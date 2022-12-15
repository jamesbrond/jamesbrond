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

DOKER_COMPOSE_OBJ=$(DC_BUILD_DIR)/docker-compose.yml

docker_compose = $(call exec_in,$(DC_BUILD_DIR),$1)

$(DC_BUILD_DIR):
	@$(call log-debug,$(DC_LOG_PREF),make directory $@)
	@mkdir -p $@

$(DOKER_COMPOSE_OBJ): | $(DC_BUILD_DIR)
	@cp $(SRC_DIR)/docker-compose.yml $(DC_BUILD_DIR)

$(SERVICES): $(DOKER_COMPOSE_OBJ)
	@$(call log-debug,$(DC_LOG_PREF),Make service $@)
	@$(MAKE) -C $(SRC_DIR)/$@ compose

# Move the docker-compose YAML file and all the dockers environment in the build dir where run it
compile:: $(DOKER_COMPOSE_OBJ) $(SERVICES)

clean:: dc-stop
	-@rm -rf $(DC_BUILD_DIR)

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
