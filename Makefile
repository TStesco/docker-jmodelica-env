# Makefile to build JModelica development Docker image and manage containers.
# Author: Tom Stesco <tom.stesco@gmaill.com>

CONTAINER_NAME=jmodelica
VERSION=0.0
BUILD_PATH=/opt
MPCPy_PATH=
EstimationPy_PATH=
MSL_PATH=$(BUILD_PATH)/JModelica/ThirdParty/MSL

build-trunk: ## Creates an image based on trunk version of JModelica.
	docker build ./ \
	-t $(CONTAINER_NAME)-trunk:$(VERSION)
.PHONY: build-trunk

# start container in detached mode and expose ipython notebook server on port 8888.
# mount all desired directories as volumes using the -v
# terminating ":rw" is for read-write, for other options see docs
dev:
	docker run -it \
	-v $(MPCPy_PATH):$(BUILD_PATH)/MPCPy:rw \
	-v $(EstimationPy_PATH):$(BUILD_PATH)/EstimationPy:rw \
	$(CONTAINER_NAME)-trunk:$(VERSION) \
	sh -c "bash"
.PHONY: dev

# additionally start container with jupyter-notebook server
dev-notebook:
	docker run -d \
	-v $(MPCPy_PATH):$(BUILD_PATH)/MPCPy:rw \
	-v $(EstimationPy_PATH):$(BUILD_PATH)/EstimationPy:rw \
	-p 127.0.0.1:8888:8888 \
	$(CONTAINER_NAME)-trunk:$(VERSION) \
	sh -c 'jupyter lab --ip="0.0.0.0" --allow-root --no-browser --matplotlib=inline \
	--port=8888 --notebook-dir=/root'
.PHONY: dev-notebook

stop-all: ## Remove all running containers with status 'Up'
	docker ps -q | xargs docker stop
.PHONY: stop-all

remove-all: ## Stop then remove all containers
	docker ps -a -q | xargs docker stop
	docker ps -a -q | xargs docker rm
.PHONY: remove-all

remove-exited: ## Remove all containers (error on running containers)
	docker ps -a -q | xargs docker rm
.PHONY: remove-exited
