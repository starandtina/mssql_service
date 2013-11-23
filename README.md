# MSSQL Service Node

## Introduction

MSSQL Service Node provides MSSSQL service for vCHS.

## Supported Features

- Provision/Unprovison/Backup/Restore
- varz/healthz

# Installation
--------------

1. Download source code from github
    + git clone http://username@tempest-reviews.eng.vmware.com/p/vchs-mssqlaas-node

## Prerequisites
1. ruby-1.9.3

## Running in local Windows box

1. Run bundler:
    + bundle install --deployment

2. Start the server:
    + bin/mssql-node # run mssql agent

3. Run unit tests:
    + rake

## Running as Windows Service in local Windows box

Using `mssql_node` as for example.

1. Run bundler:
    + bundle install --deployment

2. Install `mssql_node` service:
    + ruby bin/mssql_service_daemon_ctl install MSSQLNodeSvc MSSQLNode

3. Start `mssql_node`
    + ruby bin/mssql_service_daemon_ctl start MSSQLNodeSvc mssql_node

Please see all other commands(delete, pause, resume...) and options using `ruby bin/mssql_service_daemon_ctl`