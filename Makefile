# Check whether the `OBSIDIAN_PATH` and `TRANSFORMER_CACHE` env vars are set
ifndef OBSIDIAN_PATH
$(error OBSIDIAN_PATH is not set, please refer to the README for more information)
endif
ifndef TRANSFORMER_CACHE
$(error TRANSFORMER_CACHE is not set, please refer to the README for more information)
endif

# These generally do not need to be changed
PWD_PATH = ${PWD}
DOCKER_OBSIDIAN_PATH = /obsidian-vault
NETWORK = obsidian-copilot
IMAGE_TAG = obsidian-copilot

# Choose your container runtime: docker or podman. Default is docker.
# echo "export RUNTIME=podman" >> ~/.bashrc and source ~/.profile 
# if you dont want to keep typing it for each make or change it here
RUNTIME ?= docker

# if podman use podman else use docker with ${RUNTIME} command

ifeq ($(RUNTIME), docker) 
docker-network:
	${RUNTIME}  network create ${NETWORK} || true
else ifeq ($(RUNTIME), podman)
podman-network:
	${RUNTIME}  network create ${NETWORK} || true
else
	@echo "Invalid runtime, please use 'docker' or 'podman'"
	exit 1
endif

# note: modified due to weird local issues
# https://github.com/eugeneyan/obsidian-copilot/issues/11
ifeq ($(RUNTIME), docker) 
opensearch: docker-network
	${RUNTIME}  run -it --rm --network obsidian-copilot --network-alias opensearch -p 9200:9200 -p 9600:9600 -v "${PWD_PATH}/data:/usr/share/opensearch/data" -v ./opensearch_entrypoint.sh:/opensearch_entrypoint.sh -e "discovery.type=single-node" --entrypoint /opensearch_entrypoint.sh opensearchproject/opensearch:2.7.0 
else ifeq ($(RUNTIME), podman)
opensearch: podman-network
	${RUNTIME}  run -it --rm --network obsidian-copilot --network-alias opensearch -p 9200:9200 -p 9600:9600 -v "${PWD_PATH}/data:/usr/share/opensearch/data" -e "discovery.type=single-node" opensearchproject/opensearch:2.7.0
else
	@echo "Invalid runtime, please use 'docker' or 'podman'"
	exit 1
endif

ifeq ($(RUNTIME), docker) 
build:
	DOCKER_BUILDKIT=1 ${RUNTIME} build -t ${IMAGE_TAG} -f Dockerfile .
else ifeq ($(RUNTIME), podman)
build:
	${RUNTIME} build --format docker -t ${IMAGE_TAG} -f Dockerfile .
else
	@echo "Invalid runtime, please use 'docker' or 'podman'"
	exit 1
endif

build-artifacts: build
	${RUNTIME} run -it --rm --network ${NETWORK} -v "${PWD_PATH}/data:/obsidian-copilot/data" -v "$(OBSIDIAN_PATH):${DOCKER_OBSIDIAN_PATH}" -v "${TRANSFORMER_CACHE}:/root/.cache/huggingface/hub" ${IMAGE_TAG} /bin/bash -c "./build.sh ${DOCKER_OBSIDIAN_PATH}"

# pip install podman-compose if you don't have it
# Note: this was originally `docker-compose` but I changed it to `docker compose`
ifeq ($(RUNTIME), docker) 
run:
	docker compose up
else ifeq ($(RUNTIME), podman)
run:
	podman-compose up 
else
	@echo "Invalid runtime, please use 'docker' or 'podman'"
	exit 1
endif

install-plugin:
	mkdir -p ${OBSIDIAN_PATH}.obsidian/plugins/copilot/
	cp plugin/main.ts plugin/main.js plugin/styles.css plugin/manifest.json ${OBSIDIAN_PATH}.obsidian/plugins/copilot/

# Development
dev: build
	${RUNTIME} run -it --rm --network ${NETWORK} -v "${PWD_PATH}:/obsidian-copilot" -v "$(OBSIDIAN_PATH):/obsidian-vault" ${IMAGE_TAG} /bin/bash

app: build
	${RUNTIME} run -it --rm --network ${NETWORK} -v "${PWD_PATH}:/obsidian-copilot" -v "$(OBSIDIAN_PATH):/obsidian-vault" -v "${TRANSFORMER_CACHE}:/root/.cache/huggingface/hub" -p 8000:8000 ${IMAGE_TAG} /bin/bash -c "python -m uvicorn src.app:app --reload --host 0.0.0.0 --port 8000"


build-local:
	./build.sh

app-local:
	uvicorn src.app:app --reload

sync-plugin:
	cp -R ${OBSIDIAN_PATH}.obsidian/plugins/copilot/* plugin
