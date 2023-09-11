---
title: "Setting up Docker for SvelteKit, Rust and Postgres"
date: 2023-09-09T22:24:33+02:00
showToc: true
draft: true
---

## Prerequisites

TODO:

## Docker basics

Docker is a platform for running code in
reproducible, isolated environments.
It allows you to guarantee that any person,
and any server you deploy to,
will run your program with the exact same conditions you did.

This running instance is called a container.
Images are the instructions for building containers.
In practical terms,
they're the contexts on which your application will run.
Dockerfiles are the instructions for building images.
For example, take the following example Dockerfile

```Docker
# Uses the debian image as a base, pulling it from:
# https://hub.docker.com/_/debian
FROM debian

# This command is in "shell form", so it'll run using sh
# <instruction> <command>
# RUN instructions are executed when building the image only
# They're used to set up the environment
#
# It generates a test.txt file that contains "test1\ntest2"
RUN echo test1 >> text.txt
RUN echo test2 >> text.txt

# This command is in "exec form", so it'll run directly
# <instruction> ["executable", "parameter", "parameter", ...]
# CMD instrucions (and ENTRYPOINT instructions)
# are executed when running the image.
CMD ["cat", "text.txt"]
```
To test it out, create a directory and paste this inside a file named "Dockerfile".
Then, run `docker build . -t test` (the -t is to tag it with a name):
TODO: tell people to install Docker

```bash session
 docker build . -t test

Sending build context to Docker daemon   2.56kB
Step 1/4 : FROM debian
 ---> df89715852d4
Step 2/4 : RUN echo test1 >> text.txt
 ---> Running in d36ae3ea2a68
Removing intermediate container d36ae3ea2a68
 ---> bdea86ec38cb
Step 3/4 : RUN echo test2 >> text.txt
 ---> Running in 1bbc1bf944a5
Removing intermediate container 1bbc1bf944a5
 ---> a91f97d770cf
Step 4/4 : CMD ["cat", "text.txt"]
 ---> Running in da0bc7888e1b
Removing intermediate container da0bc7888e1b
 ---> 92877451fc0f
Successfully built 92877451fc0f
Successfully tagged test:latest
```

And then `docker run test`:
``` bash session
 docker run test
test1
test2
```

Now let's try running `docker build . -t test` again:
```bash session
 docker build . -t test

Sending build context to Docker daemon   2.56kB
Step 1/4 : FROM debian
 ---> df89715852d4
Step 2/4 : RUN echo test1 >> text.txt
 ---> Using cache
#     ^^^^^^^^^^^
 ---> bdea86ec38cb
Step 3/4 : RUN echo test2 >> text.txt
 ---> Using cache
#     ^^^^^^^^^^^
 ---> a91f97d770cf
Step 4/4 : CMD ["cat", "text.txt"]
 ---> Using cache
#     ^^^^^^^^^^^
 ---> 92877451fc0f
Successfully built 92877451fc0f
Successfully tagged test:latest
```

It'll used cached results instead of running it all over again!
Now let's change the Dockerfile so that instead of "test2" it echoes "something new!":
```Docker
# Uses the debian image as a base, pulling it from:
# https://hub.docker.com/_/debian
FROM debian

# This command is in "shell form", so it'll run using sh
# <instruction> <command>
# RUN instructions are executed when building the image only
# They're used to set up the environment
#
# It generates a test.txt file that contains "test1\ntest2"
RUN echo test1 >> text.txt
RUN echo "something new!" >> text.txt
# new!   ^^^^^^^^^^^^^^^^

# This command is in "exec form", so it'll run directly
# <instruction> ["executable", "parameter", "parameter", ...]
# CMD instrucions (and ENTRYPOINT instructions)
# are executed when running the image.
CMD ["cat", "text.txt"]
```

And let's build again:
```bash session
 docker build . -t test

Sending build context to Docker daemon   2.56kB
Step 1/4 : FROM debian
 ---> df89715852d4
Step 2/4 : RUN echo test1 >> text.txt
 ---> Using cache
#     ^^^^^^^^^^^
# Using cache up to here
 ---> bdea86ec38cb
Step 3/4 : RUN echo "something new!" >> text.txt
 ---> Running in cac91335aa4b
#     ^^^^^^^^^^^^^^^^^^^^^^^
# But not using cache here!
Removing intermediate container cac91335aa4b
 ---> 91fd59c87151
Step 4/4 : CMD ["cat", "text.txt"]
 ---> Running in 9e394b158ac6
Removing intermediate container 9e394b158ac6
 ---> a2f0bfc33000
Successfully built a2f0bfc33000
Successfully tagged test:latest
```

TODO: talk abou caches

And then run again:
``` bash session
 docker run test
test1
something new!
```

TODO: Finish

## Docker compose

TODO: Finish

## Setting up our project

### Front-end

First we'll want to install bun TODO:
Then we'll want to
[create a SvelteKit project using bun](https://bun.sh/guides/ecosystem/sveltekit)
naming it "frontend" using `bunx create-svelte frontend`.
We'll also want to `cd` into the directory and run `bun install`
and `bun --bun run svelte-kit sync`
to download the libraries and set up the `.svelte-kit` directory
so that Intellisense works properly.

```bash session
 cd frontend
 bun install
bun install v1.0.0 (822a00c4)
 + @fontsource/fira-mono@4.5.10
# [...]

 115 packages installed [3.69s]
 bun --bun run svelte-kit sync

```

We can verify that the project runs with `bun --bun run dev`:
```bash session
 bun --bun run dev
$ vite dev

Forced re-optimization of dependencies

  VITE v4.4.9  ready in 707 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h to show help

```
{{< newline >}}

Then we'll create a Dockerfile
and add it as a service in a `docker-compose.yaml` in the root directory.
In the `docker-compose.yaml` we'll do the following:

```yaml
version: "3"
services:
  frontend:
    build:
      context: frontend
      dockerfile: Dockerfile
    working_dir: /app
    # Bind all important files over
    # Notably, node_modules and .svelte-kit are not bound
    # This means that when changed in the host, they'll also be changed in the container
    # And that in turn enables hot-reloading
    volumes:
      - ./frontend/src:/app/src
      - ./frontend/static:/app/static
      - ./frontend/vite.config.ts:/app/vite.config.ts
      - ./frontend/tsconfig.json:/app/tsconfig.json
      - ./frontend/svelte.config.js:/app/svelte.config.js
    # Expose port to host
    ports:
      - 5173:5173
    # Run command
    command: [ "bun", "--bun", "run", "dev", "--", "--host" ]  
```

And on the `Dockerfile`:
```Docker
FROM oven/bun:1.0 as bun

# When building the image the docker-compose volumes aren't set up
# So we'll set up an app folder
WORKDIR /app

FROM bun as install
# Copy the package.json and package-lock.json into it
COPY package*.json ./

# And install the packages
RUN [ "bun", "install" ]

FROM bun as svelte_sync
# Add svelte.config.js and packages
COPY svelte.config.js svelte.config.js
COPY --from=install /app/node_modules /app/node_modules
# Generate .svelte-kit
RUN [ "bun", "--bun", "run", "svelte-kit", "sync" ]

FROM bun as runner
# Add the modules and .svelte-kit
COPY --from=install /app/node_modules /app/node_modules
COPY --from=svelte_sync /app/.svelte-kit /app/.svelte-kit
# Add package*.json
COPY --from=install /app/package*.json /app/
# The volumes in docker-compose.yaml will provide the other needed files
```

Then we should be able to run it with `docker compose up`!
```bash
   frontend docker compose up
[+] Building 0.7s (15/15) FINISHED                                                                                                                                                 docker:default
 => [frontend internal] load build definition from Dockerfile                                                                                                                                

# [...]

[+] Running 2/0
 ✔ Network test_default       Created                                                                                                                                                        0.0s 
 ✔ Container test-frontend-1  Created                                                                                                                                                        0.0s 
Attaching to test-frontend-1
test-frontend-1  | $ vite dev --host
test-frontend-1  | 
test-frontend-1  | 
test-frontend-1  | Forced re-optimization of dependencies
test-frontend-1  | 
test-frontend-1  |   VITE v4.4.9  ready in 745 ms
test-frontend-1  | 
test-frontend-1  | 
test-frontend-1  |   ➜  Local:   http://localhost:5173/
test-frontend-1  |   ➜  Network: http://172.26.0.2:5173/
```

If you go to the link, which should be
<http://localhost:5173>,
you should be greeted with the example website?
