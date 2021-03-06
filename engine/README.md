# CDS Engine

This is the core component of CDS.

This component is responsible and is the entry point to several ┬ÁServices such as:

* API
* VCS
* Hooks
* Repositories
* ElasticSearch
* Migrate
* [Hatcheries](https://ovh.github.io/cds/docs/components/hatchery/)

The API component is the core component and is mandatory in every setups.

To start CDS API, the mandatory dependencies are a [PostgreSQL database](https://www.postgresql.org/), a [Redis Server](https://redis.io/) and a path to the directory containing other CDS binaries, for serious usages you may need other third parties [Read more](https://ovh.github.io/cds/hosting/requirements/)

## Configuration
There are two ways to set up CDS:

- with [toml](https://github.com/toml-lang/toml) configuration
- with environment variables.

[Read more](https://ovh.github.io/cds/hosting/configuration/)
 
## Startup

A docker-compose file is provided for light deployment and dev environments, [follow this guide](https://ovh.github.io/cds/hosting/ready-to-run/docker-compose/).

For larger deployments you have to go deeper and read this [advanced startup page](https://ovh.github.io/cds/hosting/).

## Database management

CDS provides all needed tools scripts to perform Schema creation and auto-migration. Those tools are embedded inside the `engine` binary.

The migration files are available to download on [GitHub Releases](https://github.com/ovh/cds/releases) and the archive is named `sql.tar.gz`. You have to download it and untar (`tar xvzf sql.tar.gz`).

[Read more](https://ovh.github.io/cds/hosting/database/)
