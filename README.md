# Docker based PowerShell Scheduler using Docker Compose
This can be used to schedule multiple PowerShell scripts to run from a docker container.

## Exposed Directories
Two directories need to be exposed for this to work correctly. The **Scripts** directory and the **Data** directory.

The **Scripts** directory contains all PowerShell jobs you would like to run and consists of at minimum two files;

**Init.ps1** - This is the script which will be triggered at the appropriate intervals and can be used independently or to call other scripts.  
**Config.ini** - This is the config file which contains the schedule

An example job is [available here](https://github.com/TehMuffinMoo/ps-scheduler/tree/main/scripts/Example).

## Docker Compose Example
The example below shows deploying the PS-Scheduler container and installing the POSH-ACME Module

```yaml
version: '3'

services:
  ps-scheduler:
    image: ps-scheduler:latest
    environment:
      PSSCHEDULERMODULES: 'POSH-ACME' ## A comma separated list of PowerShell Modules to install during startup
      PSSCHEDULERDEBUG: 'false' ## true/false if Debug logging is enabled
      POSHACME_HOME: '/data/posh-acme' ## Redirect POSH-ACME home directory for this particular example
    volumes:
      - ./ps-scheduler/scripts:/scripts
      - ./ps-scheduler/data:/data
```
