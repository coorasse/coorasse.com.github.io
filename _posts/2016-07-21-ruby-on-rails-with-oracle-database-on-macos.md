---
layout: post
title: "Ruby On Rails with Oracle Database on MacOS"
date: 2016-07-21
categories: rails
excerpt: "A step by step guide to work with an Oracle database in your development environment"
---

![Rails + Oracle](/assets/ruby-on-rails-with-oracle-database-on-macos/top.png)

**Updated on 12th July 2020**

What is the nightmare of every developer? Have to work on an Oracle Database, of course.
Since it took me some days to figure out how to make Ruby on Rails connect to an Oracle Database on my Mac, I decided to
write this step-by-step guide, hoping to save you some time whenever you will have to face this situation.

## Introduction

I have a Rails application which needs to connect to an Oracle database.
The customer runs the software on Oracle in production and is much better to also develop on the same database.

## Install Oracle Database

The first step is impossible: Oracle doesn’t provide OracleDB for macOS anymore so we are not able to install it on our
machine. We need to install Docker and download a docker image to run Oracle in a virtual machine.

Please follow instructions here to install it: https://docs.docker.com/engine/installation/mac/#/docker-for-mac until
you end up having Docker running.

![Docker Desktop running](/assets/ruby-on-rails-with-oracle-database-on-macos/docker-desktop.png)

Now is time to download the image for Oracle Database 12. Proceed
to https://hub.docker.com/_/oracle-database-enterprise-edition, to find the official Docker image for Oracle Enterprise
12. Once you have accepted the TOS, you will be able to pull the image:

```bash
docker pull store/oracle/database-enterprise:12.2.0.1
```

I suggest you to run it with the following:

```bash
docker run -d -p 1521:1521 -v ~/oracle/data:/ORCL store/oracle/database-enterprise:12.2.0.1
```

Some hints about the above command if you are not familiar with Docker:

* we are running a virtual machine with Oracle pre-installed in the background (the -d option);
* we are binding the port 1521 to our local machine (the -p 1521:1521 option)
* we are mounting a local folder ~/oracle/data to the container folder to persist the database status (the -v ~
/oracle/data:/ORCL option)
This will take ~5 minutes, you can check the progress with

```bash
docker logs -f ID_FROM_PREVIOUS_COMMAND
```

If the Oracle instance is up and running you will see it using. The status will be healthy.

```bash
docker ps
```

Now that you have Oracle running we can install the client on our machine

## Install Oracle Instant Client for macOS

Let’s do it step by step:

1. Download Oracle Instant Client Basic, SDK and sqplus for MacOSX 64bit from this
link: http://www.oracle.com/technetwork/topics/intel-macsoft-096467.html.
The files are named more or less like that (apart from version which may change):
  * instantclient-basic-macos.x64–12.2.0.1.0–2.zip
  * instantclient-sqlplus-macos.x64–12.2.0.1.0–2.zip
  * instantclient-sdk-macos.x64–12.2.0.1.0–2.zip
2. Create a oracle folder in your home folder and unzip instantclient-basic into it. You will end up with the following
  folder structure:
  ~/oracle/instantclient_12_2
3. Extract the sqlplus zip content and the sdk zip content into the instantclient_12_2 folder.
4. Put dylib files out of quarantine:
```bash
find . -name "*dylib*" | sudo xargs xattr -r -d com.apple.quarantine
```

5. Create a `~/.oracle` file and put the following content which will set necessary environment variables:

```
export OCI_DIR=~/oracle/instantclient_12_2
export PATH=$PATH:~/oracle/instantclient_12_2
export NLS_LANG=AMERICAN_AMERICA.UTF8
```

You will have to load the `~/.oracle` file into your `~/.bashrc` file or `~/.profile` or `~/.zshrc` file depending on your
  terminal.

You should now be able to install ruby-oci8 gem via

```bash
gem install ruby-oci8
```

## Configure Rails
Add `activerecord-oracle_enhanced-adapter` to your Gemfile and `bundle install`.

Now edit your database.yml file to something like:

```yaml
default: &default
adapter: oracle_enhanced
database: "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=0.0.0.0)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(
SERVICE_NAME=ORCLPDB1.localdomain)))"

development:
<<: *default
username: "myproject_development"
password: "myproject_development"

test:
<<: *default
username: "myproject_test"
password: "myproject_test"

production:
<<: *default
username: "myproject_production"
password: "myproject_production"
```

The Oracle adapter for Rails doesn’t allow to create a database so you won’t be able to use `rails db:create` command.
Instead use a script like the following, that I saved in my bin folder. This script creates the three database we will
need.

```sql
# bin/setup_oracle.sql

CREATE BIGFILE TABLESPACE myproject_development DATAFILE 'myproject_development.dat' SIZE 100M AUTOEXTEND ON;
GRANT CONNECT, RESOURCE TO myproject_development IDENTIFIED BY myproject_development;
ALTER USER myproject_development DEFAULT TABLESPACE myproject_development TEMPORARY TABLESPACE temp;
ALTER USER myproject_development quota 100M on myproject_development;

CREATE BIGFILE TABLESPACE myproject_test DATAFILE 'myproject_test.dat' SIZE 100M AUTOEXTEND ON;
GRANT CONNECT, RESOURCE TO myproject_test IDENTIFIED BY myproject_test;
ALTER USER myproject_test DEFAULT TABLESPACE myproject_test TEMPORARY TABLESPACE temp;
ALTER USER myproject_test quota 100M on myproject_test;

CREATE BIGFILE TABLESPACE myproject_production DATAFILE 'myproject_production.dat' SIZE 100M AUTOEXTEND ON;
GRANT CONNECT, RESOURCE TO myproject_production IDENTIFIED BY myproject_production;
ALTER USER myproject_production DEFAULT TABLESPACE myproject_production TEMPORARY TABLESPACE temp;
ALTER USER myproject_production quota 100M on myproject_production;

ALTER SYSTEM SET open_cursors = 1000 scope=both;

QUIT;
/
```

You can execute the script with

```bash
DB_NAME=`cat config/database.yml | grep 'database:' | grep "^[^#]" | awk '{ print $2}'`
sqlplus sys/Oradoc_db1@$DB_NAME as sysdba @bin/setup_oracle.sql
```

from the root folder of your project.

Finally you can run `rails db:schema:load db:seed` to setup your database.

## Notes
Commands `rails db:create` and `rails db:drop` are not available.
You may face problems with your schema (length of index names for example) and need to change it manually
