# docker command must be in PATH

# required makefiles:
# - misc.mk

# required variables:
# DOCKER_TAG
# CONTAINER_NAME
# BUILD_DIR

# optional variables:
# - BUILD_TYPE
# - NO_CACHE
# - PULL
# - SHELL_TYPE


BUILD_TYPE ?= dev
NO_CACHE ?= false
PULL ?= false
SHELL_TYPE ?= bash


FULL_CONTAINER_NAME := $(CONTAINER_NAME)_$(BUILD_TYPE)

DOCKER_BUILD_DIR := $(BUILD_DIR)/docker
DOCKER_LOG_PREF  := DOCKER

DIRS += $(DOCKER_BUILD_DIR)


define docker
	$(call log-debug,$(DOCKER_LOG_PREF),Run: $1)
	cd $(DOCKER_BUILD_DIR) && $1 || true
endef

clean::
	@$(call log-debug,$(DOCKER_LOG_PREF),Remove container)
	@docker rm -f $(FULL_CONTAINER_NAME) 2>/dev/null \
	&& echo Container for "$(FULL_CONTAINER_NAME)" removed \
	|| echo Container for "$(FULL_CONTAINER_NAME)" already removed or not found

distclean:: clean
	@$(call log-debug,$(DOCKER_LOG_PREF),Remove created image)
	@docker rmi $(DOCKER_TAG) 2>/dev/null \
	&& echo Image(s) for "$(DOCKER_TAG)" removed \
	|| echo Image(s) for "$(DOCKER_TAG)" already removed or not found

build::
	@$(call log-debug,$(DOCKER_LOG_PREF),Build the dockerfile)
	docker build --pull=$(PULL) --no-cache=$(NO_CACHE) -t $(DOCKER_TAG) .

docker-show: ## Show running containers
	docker ps | grep $(CONTAINER_NAME)

docker-sh: ## Run as a service and attach to it
	docker exec -it $(FULL_CONTAINER_NAME) $(SHELL_TYPE)

docker-start: ## Start a container
	docker start $(FULL_CONTAINER_NAME)

docker-stop: ## Stop a running container
	docker stop $(FULL_CONTAINER_NAME);

# ~@:-]
