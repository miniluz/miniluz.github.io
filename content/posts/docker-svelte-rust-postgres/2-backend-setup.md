---
title: "2 Backend Setup"
date: 2023-09-15T11:32:05+02:00
draft: true
---

First, we need a way to make SeaORM generate the Entities directory.

Following
[the documentation](https://www.sea-ql.org/SeaORM/docs/migration/setting-up-migration/)
TODO: update to one that reflects not using a new package.
we'll be creating a new lib package from `backend`

Now we want to extract the entities from the database. We create `backend/Dockerfile.generate_entity`
```Dockerfile
FROM docker.io/rust:1.72 AS entity-generator
RUN cargo install sea-orm-cli
RUN rustup component add rustfmt
WORKDIR /app
ENTRYPOINT "/usr/local/cargo/bin/sea-orm-cli" "generate" "entity" "-o" "src/entities"
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
      - ./backend/src/entities/:/app/src/entities
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

We can now run this with `docker compose -f docker-compose-generate-entity.yaml up --build --force-recreate`.
You'll probably want to add it to a script on `/generate-entities.sh`:
```bash
#!/bin/sh
docker compose -f docker-compose-generate-entity.yaml up --build --force-recreate
docker compose down
```

Then make it executable with `chmod +x ./generate-entities.sh`, and call it with `./generate-entities.sh`.
```bash
 chmod +x ./generate-entities.sh
 ./generate-entities.sh
# [...]
miniluz-todo-entity-generator-1  | Connecting to Postgres ...
miniluz-todo-entity-generator-1  | Discovering schema ...
miniluz-todo-entity-generator-1  | ... discovered.
miniluz-todo-entity-generator-1  | Writing src/entities/mod.rs
miniluz-todo-entity-generator-1  | Writing src/entities/prelude.rs
miniluz-todo-entity-generator-1  | ... Done.
```

Hm. This didn't create a task entity.
I guess that makes sense:
it's generating the entities from the database directly,
and we haven't applied the migrations to it yet.
It should be enough to go on for now though.

<!--
TODO:
Create migration with sea-orm-migrate, commit "Added migrations and entity generator"
https://www.sea-ql.org/SeaORM/docs/migration/setting-up-migration/
-->

We're gonna add four more crates to the dependencies:
[`poem_openapi`](https://docs.rs/poem-openapi/latest/poem_openapi/)
and
[poem](https://docs.rs/poem/1.3.58/poem/),
for easy creation of the REST server,
and
[tracing_subscriber](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/)
plus
[tracing](https://docs.rs/tracing/0.1.38/tracing/),
for easy logs.

We're gonna follow the 
[`poem_openapi docs`](https://docs.rs/poem-openapi/latest/poem_openapi/)
and the
[SeaORM example using `poem`](https://github.com/SeaQL/sea-orm/tree/master/examples/poem_example)
to get a working setup that migrates the database when starting up:

```rs
use std::{env, net::SocketAddr, str::FromStr};

use migration::{Migrator, MigratorTrait};
use poem::{listener::TcpListener, web::Data, EndpointExt, Route, Server};
use poem_openapi::{payload::Json, Object, OpenApi, OpenApiService};
use sea_orm::{Database, DatabaseConnection};
use tracing::{event, span, Level};

struct Api;

#[derive(Object)]
struct Test;

#[OpenApi]
impl Api {
    #[oai(path = "/", method = "get")]
    async fn index(&self, conn: Data<&DatabaseConnection>) -> Json<Test> {
        Json(Test {})
    }
}

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    tracing_subscriber::fmt::init();

    let db_url = env::var("DATABASE_URL").expect("DATABASE_URL is not set in env.");

    let start_up_span = span!(Level::INFO, "start-up");
    let start_up_guard = start_up_span.enter();

    event!(Level::INFO, "Connecting to database...");
    let conn = Database::connect(db_url)
        .await
        .expect("Failed to connect to database.");
    event!(Level::INFO, "Connected to database successfully");

    event!(Level::INFO, "Trying to migrate...");
    Migrator::up(&conn, None).await.unwrap();
    event!(Level::INFO, "Migrated");

    event!(Level::INFO, "Starting server...");
    let host = env::var("HOST").expect("HOST is not set in env.");
    let port = env::var("PORT").expect("PORT is not set in env.");
    let addr = SocketAddr::from_str(&format!("{host}:{port}")).unwrap();

    let api_serive = OpenApiService::new(Api, "mini-do backend", "1.0").server(addr.to_string());
    let app = Route::new().nest("/", api_serive).data(conn);

    Server::new(TcpListener::bind(addr)).run(app).await.unwrap();

    drop(start_up_guard);

    Ok(())
}
```

This will migrate our database if needed and start a server.
We'll need to specify the `HOST` and `PORT` environment variables,
and a `RUST_LOG` variable to specify how much to trace
([docs](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/fmt/index.html#filtering-events-with-environment-variables)).
Finally we need to forward the port to make it accessible.
On `docker-compose.yaml`:

```yaml
  backend:
    build:
      context: backend
      dockerfile: Dockerfile
    depends_on:
      - db
    networks:
      - back-db
    environment:
      - HOST=0.0.0.0
      - PORT=3000
      - RUST_LOG=info
    env_file:
      - .env.dev
    ports:
      - 3000:3000
```

I'll create a `run.sh` command to automate starting the server up:
```bash
#!/bin/sh
docker compose up --build --force-recreate
docker compose down
```

And when we start it up:
```bash
 chmod +x run.sh
 ./run.sh
# [...]
miniluz-todo-backend-1   | 2023-10-08T11:28:06.937007Z  INFO start-up: backend: Migrated
# The back-end has finished migrating!                                 ^^^^^^^^^^^^^^^^^
miniluz-todo-backend-1   | 2023-10-08T11:28:06.937010Z  INFO start-up: backend: Starting server...
miniluz-todo-backend-1   | 2023-10-08T11:28:06.937195Z  INFO start-up: poem::server: listening addr=socket://0.0.0.0:3000
miniluz-todo-backend-1   | 2023-10-08T11:28:06.937206Z  INFO start-up: poem::server: server started
```

We can verify that the migration has been applied on Adminer at <localhost:8080>:
{{<figure src="/docker-svelte-rust-postgres/2-first-migration.png">}}

And we can verify that the server is running correctly at <localhost:3000>:
{{<figure src="/docker-svelte-rust-postgres/2-first-server.png">}}

It's been set up correctly!

Finally, we'll update the entities to match the migrated database
with `./generate-entities.sh`:
```bash
 ./generate-entities.sh
miniluz-todo-entity-generator-1  | Connecting to Postgres ...
miniluz-todo-entity-generator-1  | Discovering schema ...
miniluz-todo-entity-generator-1  | ... discovered.
miniluz-todo-entity-generator-1  | Generating task.rs
miniluz-todo-entity-generator-1  |     > Column `id`: i32, auto_increment, not_null
miniluz-todo-entity-generator-1  |     > Column `title`: String, not_null
miniluz-todo-entity-generator-1  |     > Column `text`: String, not_null
miniluz-todo-entity-generator-1  |     > Column `creation_time`: DateTime, not_null
miniluz-todo-entity-generator-1  |     > Column `due_time`: DateTime, not_null
miniluz-todo-entity-generator-1  | Writing src/entities/task.rs
miniluz-todo-entity-generator-1  | Writing src/entities/mod.rs
miniluz-todo-entity-generator-1  | Writing src/entities/prelude.rs
miniluz-todo-entity-generator-1  | ... Done.
```

Finally, let's add an API endpoint to be able to query for a task giving its id.
First, we'll make the entity generator derive `Object` for the model
<!-- TODO: Link -->
to be able to return it as a JSON easily.

We'll change on `backend/Dockerfile.generate_entity`:
```Dockerfile
FROM docker.io/rust:1.72 AS entity-generator
RUN cargo install sea-orm-cli
RUN rustup component add rustfmt
WORKDIR /app
ENTRYPOINT "/usr/local/cargo/bin/sea-orm-cli" "generate" "entity" "-o" "src/entities" "--model-extra-derives" "poem_openapi::Object"
# NEW --------------------------------------------------------------------------------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

This will give us an error, since we haven't enabled the `chrono` feature for `poem-openapi`
that implements `ToJSON` and `ParseFromJSON` for `NaiveDateTime`. Let's go enable it:

```toml
# [...]
[dependencies]
# [...]
poem-openapi = { version = "3.0.5", features = ["chrono"] }
# New ------------------------------^^^^^^^^^^^^^^^^^^^^^
# [...]
```

Now let's create a new file: `backend/src/task.rs` for the Task endpoins:
```rs
use poem::web::Data;
use poem_openapi::{
    param::Query,
    payload::{Json, PlainText},
    ApiResponse, OpenApi,
};
use sea_orm::{DatabaseConnection, EntityTrait};

use crate::entities::task;

pub struct TaskApi;

#[derive(Debug, ApiResponse)]
pub enum GetResponse {
    /// Ok
    #[oai(status = 200)]
    Ok(Json<task::Model>),
    /// Task not found
    #[oai(status = 400)]
    TaskNotFound(PlainText<String>),
    /// Database error
    #[oai(status = 400)]
    DbErr,
}

#[OpenApi]
impl TaskApi {
    #[oai(path = "/", method = "get")]
    pub async fn get(&self, conn: Data<&DatabaseConnection>, id: Query<i32>) -> GetResponse {
        let id = id.0;
        let task_result = task::Entity::find_by_id(id).one(conn.0).await;

        match task_result {
            Ok(Some(task)) => GetResponse::Ok(Json(task)),
            Ok(None) => GetResponse::TaskNotFound(PlainText(format!("Task id {id} not found."))),
            Err(_) => GetResponse::DbErr,
        }
    }
}
```

And let's update `backend/src/main.rs` to match:
```rs
use std::{env, net::SocketAddr, str::FromStr};

mod entities;

use migration::{Migrator, MigratorTrait};
use poem::{listener::TcpListener, EndpointExt, Route, Server};
use poem_openapi::OpenApiService;
use sea_orm::Database;
use tracing::{event, span, Level};

// Old test API removed.
// New vvvvvvvvvvv
mod task;

use task::TaskApi;
// New ^^^^^^^^^^^

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    tracing_subscriber::fmt::init();

    let db_url = env::var("DATABASE_URL").expect("DATABASE_URL is not set in env.");

    // [...]

    let task_service = OpenApiService::new(TaskApi, "Task endpoint", "1.0").server(addr.to_string());
    // New --------------------------------^^^^^^^--^^^^^^^^^^^^^^^
    let app = Route::new().nest("/backend/task", task_service).data(conn);
    // New ---------------------^^^^^^^^^^^^^^^--^^^^^^^^^^^^

    Server::new(TcpListener::bind(addr)).run(app).await.unwrap();

    drop(start_up_guard);

    Ok(())
}
```

<!-- TODO: Images-->
Finally, let's query
<http://localhost:3000/backend/task>,
<http://localhost:3000/backend/task?id=1>,
and
<http://localhost:3000/backend/task?id=1>,
after having created a task.