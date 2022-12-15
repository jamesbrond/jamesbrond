# required makefiles:
# - misc.mk

# required variables:
# BUILD_DIR
# NG_DIR

SHELL:=/bin/bash

ROOT_DIR     := .
NG_BUILD_DIR := $(BUILD_DIR)/ng
NG_SRCS      := $(shell /usr/bin/find $(NG_DIR)/ -name 'node_modules' -type d -prune -o -name '.angular' -type d -prune -name '.vscode' -type d -prune -o -type f -print)
NG_OBJ       := $(NG_BUILD_DIR)/index.html
NG_RELPATH   := $(shell SOURCE="$(ROOT_DIR)/$(NG_DIR)/"; \
	TARGET="$(ROOT_DIR)/"; \
	RESULT=''; \
	while [ "$$SOURCE" ] && [ "$$TARGET" = "$${TARGET\#"$$SOURCE"}" ]; do \
		SOURCE="$${SOURCE%/?*/}/"; \
		RESULT="../$$RESULT"; \
	done; \
	REPLY="$${RESULT}$${TARGET\#"$$SOURCE"}"; \
	[ "$${REPLY\#/}" ] && REPLY="$${REPLY%/}" || REPLY="$${REPLY:-.}"; \
	echo $${REPLY})


NG_LOG_PREF   := NG

$(NG_BUILD_DIR):
	@$(call log-debug,$(NG_LOG_PREF),make directory $@)
	@mkdir -p $@

$(NG_OBJ): $(NG_SRCS) | $(NG_BUILD_DIR)
	@$(call log-info,$(NG_LOG_PREF),Build Angular UI)
	@$(call exec_in,$(NG_DIR),ng build --configuration=production --output-path $(NG_RELPATH)/$(NG_BUILD_DIR))

compile:: $(NG_OBJ)

ng-serve:
	@$(call log-info,$(NG_LOG_PREF),NG serve)
	@$(call exec_in,$(NG_DIR),ng serve)

lint::
	@$(call log-debug,$(NG_LOG_PREF),Running angular linting)
	@$(call exec_in,$(NG_DIR),ng lint)

# ~@:-]
