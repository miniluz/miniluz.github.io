---
title: "2 Seaorm Setup"
date: 2023-09-15T11:32:05+02:00
draft: true
---

<!--
Create migration with sea-orm-migrate, commit "Added migrations and entity generator"
https://www.sea-ql.org/SeaORM/docs/migration/setting-up-migration/
-->

On the `/migration` folder, we're gonna create a Dockerfile.
```Dockerfile
FROM rust:1.72 AS chef
# Install cargo-chef
RUN cargo install cargo-chef
WORKDIR /app

FROM chef AS planner
COPY . .
# Prepare needed libraries and save to recipe.json
RUN cargo chef prepare --recipe-path recipe.json

FROM chef as builder
# Build libraries
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

# Build code
COPY . .
RUN cargo build --release

FROM chef as runtime
# Copy only compiled app
COPY --from=builder /app/target/release/migration /
ENTRYPOINT [ "/migration" ]
```

To test, start the server with `docker-compose-up`:
```bash
[...]
miniluz-todo-migrator-1  | Applying all pending migrations
miniluz-todo-migrator-1  | Applying migration 'm20230715_000001_create_todo_table'
miniluz-todo-migrator-1  | Migration 'm20230715_000001_create_todo_table' has been applied
miniluz-todo-migrator-1 exited with code 0
```

And check it out on Adminer:
{{<figure src="/docker-svelte-rust-postgres/first-migration.png">}}

It's been set up correctly!

Following
[the documentation](https://www.sea-ql.org/SeaORM/docs/migration/setting-up-migration/)
we'll be creating a new lib package from `backend` with `cargo new --lib entity`

We'll add to `Cargo.toml`
```toml
[dependencies]
sea-orm = { version = "0.12.2" }
```

And change `backend/entity/src/lib.rs` to:
```rs
mod entities;
pub use entities::*;
```

We also add to `/backend/Cargo.toml`
```toml
[workspace]
members = [".", "entity", "migration"]

[dependencies]
entity = { path = "entity" }
[...]
```

Now we want to extract the entities from the database. We create `backend/Dockerfile.generate_entity`
```Dockerfile
FROM rust:1.72 AS entity-generator
RUN cargo install sea-orm-cli
RUN rustup component add rustfmt
WORKDIR /app
ENTRYPOINT "/usr/local/cargo/bin/sea-orm-cli" "generate" "entity" "-o" "entity/src/entities"
```

And we create a new `docker-compose-generate-entity.yaml`:
```yaml
version: "3"
services:
  entity-generator:
    build:
      context: backend/
      dockerfile: Dockerfile.generate_entity
    volumes:
      - ./backend/entity/src/entities/:/app/entity/src/entities
    depends_on:
      - db
    networks:
      - back-db
    env_file:
      - .env.dev
  db:
    image: postgres:latest
    volumes:
      - ./db-data/:/var/lib/postgresql/data
      - ./postgres.conf:/etc/postgresql/postgresql.conf
    networks:
      - back-db
    env_file:
      - .env.dev

networks:
  back-db: {}
```

We can now run this with `docker compose -f docker-compose-generate-entity.yaml up --build`.

```bash
[...]
miniluz-todo-entity-generator-1  | Connecting to Postgres ...
miniluz-todo-entity-generator-1  | Discovering schema ...
miniluz-todo-entity-generator-1  | ... discovered.
miniluz-todo-entity-generator-1  | Generating task.rs
miniluz-todo-entity-generator-1  |     > Column `id`: i32, auto_increment, not_null
miniluz-todo-entity-generator-1  |     > Column `title`: String, not_null
miniluz-todo-entity-generator-1  |     > Column `text`: String, not_null
miniluz-todo-entity-generator-1  |     > Column `creation_time`: DateTime, not_null
miniluz-todo-entity-generator-1  |     > Column `due_time`: DateTime, not_null
miniluz-todo-entity-generator-1  | Writing entity/src/entities/task.rs
miniluz-todo-entity-generator-1  | Writing entity/src/entities/mod.rs
miniluz-todo-entity-generator-1  | Writing entity/src/entities/prelude.rs
miniluz-todo-entity-generator-1  | ... Done.
miniluz-todo-entity-generator-1 exited with code 0
```