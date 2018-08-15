# Docker-JModelica-Env

This repo contains a Dockerfile for building a Ubuntu based container that runs 
[JModelica](https://jmodelica.org/) with [Ipopt](https://projects.coin-or.org/Ipopt) 
for development in Python 2.7 (tested with 2.7.14). 

For interactive development it optionally exposes a jupyter-notebook server session on 
port 8888 with jupyterlab, accessible at http://localhost:8888/lab. 
Alternatively you can edit all files mounted to the container with rw permissions as 
normal outside the container and they will be shared bidirectionally with the container.

## Setup

If you do not have Docker installed, 
install the community edition as per the official guide: https://docs.docker.com/install/  
note: installing Docker requires root permissions

The Makefile is a thin wrapper for Docker commands to manage the containers. 
The most important part is the volumes which are mounted when running the containers.

Both MPCPy and EstimationPy are setup simply by cloning the repos and adding 
the "MPCPyPATH" and "EstimationPy_PATH" variables for your installation path 
in the Makefile. These versions are mounted with the docker container and added 
to the PYTHONPATH environment variable in the container.

You can clone both libraries into this directory for example.

```sh
git clone https://github.com/lbl-srg/MPCPy.git
git clone https://github.com/lbl-srg/EstimationPy.git
```

There are a lot of environment variables, but you only need to configure these 
two in the Makefile for your system.

```Dockerfile
# Makefile to build JModelica development Docker image and manage containers.
# Author: Tom Stesco <tom.stesco@gmaill.com>

CONTAINER_NAME=jmodelica
VERSION=0.7
BUILD_PATH=/opt
MPCPy_PATH=<add your system path here>
EstimationPy_PATH=<add your system path here>
MSL_PATH=$(BUILD_PATH)/JModelica/ThirdParty/MSL
```

For example my Makefile is configured as such:

```Dockerfile
# Makefile to build JModelica development Docker image and manage containers.
# Author: Tom Stesco <tom.stesco@gmaill.com>

CONTAINER_NAME=jmodelica
VERSION=0.7
BUILD_PATH=/opt
MPCPy_PATH=/home/tom/projects/MPCPy
EstimationPy_PATH=/home/tom/projects/EstimationPy
MSL_PATH=$(BUILD_PATH)/JModelica/ThirdParty/MSL
```

MPCPy and EstimationPy are left outside of the container and mounted with rw permissions 
so that you can change the libraries without having to rebuild the container each 
time. The same works for any other libraries you would like to add, such as 
your own Modelica libraries beyond the MSL.

## Adding additional Modelica libraries

To add modelica libraries, such as the [IBPSA](https://github.com/ibpsa/modelica-ibpsa) 
library for building systems, clone the library:

```sh
git clone https://github.com/ibpsa/modelica-ibpsa.git
```

Then mount the source code to a directory in the MSL directory in the make file 
dev command, for example in my Makefile:

```Dockerfile
dev:
    docker run -it \
    -v $(shell pwd)/modelica:/root/modelica:rw \
    -v $(shell pwd)/energyplus:/root/energyplus:rw \
    -v $(shell pwd)/notebooks:/root/notebooks:rw \
    -v $(shell pwd)/src:/root/src:rw \
    -v $(shell pwd)/data:/root/data:rw \
    -v $(MPCPy_PATH):$(BUILD_PATH)/MPCPy:rw \
    -v $(EstimationPy_PATH):$(BUILD_PATH)/EstimationPy:rw \
    -v $(shell pwd)/modelica/BuildingComponents:$(MSL_PATH)/BuildingComponents:rw \
    -v $(shell pwd)/modelica/IBPSA:$(MSL_PATH)/IBPSA:rw \
    $(CONTAINER_NAME)-trunk:$(VERSION) \
    sh -c "bash"
.PHONY: dev
```

This would need to be repeated for dev-notebook if you want to use that command 
to run your container.

## Build container

Building the container can be done before figuring out your mounting scheme. 
To build the container run:

```sh
Make build-trunk
```

This will take quite some time to compile everything from source, around 30 minutes.

## development

Use the command ```Make dev``` to start the container and expose a bash session 
with the volumes mounted as configured in the Makefile.

Use the command ```Make dev-notebook``` to start the container and expose a jupyter-notebook 
server on port 8888 with jupyterlab, accessible at http://localhost:8888/lab.

With the bash session you can test the container has access to the key libraries:
```sh
python -c "import mpcpy, pymodelica, pyfmi, pyjmi"
```
This should return no import errors.

## Notes on Docker

All normal docker commands work with this setup as normal. The Makefile is just 
a script to make running specific commands with custom arguments easier. 

For more information on Docker see: https://docs.docker.com/

In general Docker containers can be further customized after being built and ran, but the images will not be 
updated. This means for example if you install any software or save a file that 
is not in a mounted volume on a specific container instance, then stop the 
container, you can restart it without losing anything. However, if you remove 
the container you lose the additional software and unmounted files.

