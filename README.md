# Forestry (ZooKeeper)

Forestry is a naive implementation of [Apache ZooKeeper](https://zookeeper.apache.org/), an open-source server which enables highly reliable distributed coordination.

## Motivation

Forestry focus on being a study of how to implement ZooKeeper's API for service discovery.

## Running Forestry

### Environment Variables

The Forestry applications accept environment variables or command line parameters.
Makefile requires a `.env` file to inject environment variables before running any command.

[Makefile#L29](Makefile#L29)
```
# Inject env file
include .env
export $(shell sed 's/=.*//' .env)
```

Make sure to have a `.env` file in the root folder before starting. You can create a
symbolic link to one of the samples included in the project or create your own.

```
$ ln -s .env.integration .env
```

#### Export Variables

```
$ export $(cat .env | xargs)
```

### Start Forestry HTTP Server

```
$ make start
```

### Start Forestry HTTP Server with Parameters

```
$ make build
$ bin/forestry serve --log-level=debug --log-format=text
```
