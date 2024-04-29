# docker-compose command must be in PATH

# required makefiles:
# - misc.mk

# required variables:
# - SRC_DIR (where all docker configuration and volumes are)
# - SERVICES
# - BUILD_DIR

# optional variables:
# - LOG_LINES
# - SHELL


LOG_LINES ?= 100
SHELL     ?= /bin/bash

service:=
service_shell:=bash
DC_BUILD_DIR  := $(BUILD_DIR)/docker_compose
DC_LOG_PREF   := DockerCompose

DOCKER_COMPOSE_OBJ=$(DC_BUILD_DIR)/docker-compose.yml

DIRS += $(DC_BUILD_DIR)

SERVICES_SRCS := $(foreach i,$(SERVICES),$(SRC_DIR)/$(i)/compose.yml)

docker_compose = $(call exec_in,$(DC_BUILD_DIR),$1)

docker_append = $(shell cat "$1" >> "$2" && echo -en '\n')

$(DOCKER_COMPOSE_OBJ): $(SERVICES_SRCS) $(CONFIGURE) | $(DC_BUILD_DIR)
	@cat $(SRC_DIR)/docker-compose.yml > $(DC_BUILD_DIR)/docker-compose.yml
	@for s in $(SERVICES); do \
		$(call log-debug,$(DC_LOG_PREF),Make service $$s); \
		$(MAKE) -C $(SRC_DIR)/$$s compose ROOT_BUILD_DIR=../../$(DC_BUILD_DIR) CONFIGURE=$(shell $(call abs_path,$(CONFIGURE))); \
	done

# Move the docker-compose YAML file and all the dockers environment in the build dir where run it
build:: $(DOCKER_COMPOSE_OBJ)

clean::
	@-$(RMDIR) $(DC_BUILD_DIR) $(NULL_STDERR)

dc-run: dc-compose ## Run all the services in the foreground
	@$(call docker_compose,docker-compose up)

dc-rund: dc-compose ## Run all the services in the background
	@$(call docker_compose,docker-compose up -d)

dc-stop: ## Stop all the services
	@$(call docker_compose,docker-compose down)

dc-restart: dc-stop dc-run ## Stop and restart all the services

dc-logs: ## Show latest logs of all services or of a specific service with service=<service_name>
	@$(call docker_compose,docker-compose logs --timestamps --follow --tail $(LOGS_LINE) $(service))

dc-logsf: ## Log to file all logs of all services or of a specific service with service=<service_name>
	$(call docker_compose,docker-compose logs --timestamps --follow --no-color $(service) >& logs_$(service).log)

dc-tty: ## Start the service  with service=<service_name> a root shell (service_shell=<bash or sh>)
	$(call docker_compose,docker exec -it "$(service)" $(service_shell))

dc-ttyr: ## Start the service  with service=<service_name> a user shell (service_shell=<bash or sh>)
	$(call docker_compose,docker-compose run -u root "$(service)" $(service_shell))

dc-ls: ## Lists containers
	$(call docker_compose,docker-compose ps)

dc-reload: ## Restarts all stopped and running services or a single service (service=<service_name>)
	$(call docker_compose,docker-compose restart $(service))

dc-rm:
	@for s in $(SERVICES); do \
		$(call docker_compose,docker-compose rm --stop --force $$s); \
	done
