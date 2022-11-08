# required makefiles:
# - misc.mk

# required variables:
# NG_DIR
# BUILD_DIR

SHELL:=/bin/bash

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


$(NG_BUILD_DIR):
	@mkdir -p $@

$(NG_OBJ): $(NG_BUILD_DIR) $(NG_SRCS)
	@$(call prompt-info,Build Angular UI)
	@cd $(NG_DIR) && ng build --configuration=production --output-path $(NG_RELPATH)/$(NG_BUILD_DIR)

ng-compile: $(NG_OBJ)

ng-serve:
	@$(call prompt-info,NG serve)
	@cd $(NG_DIR) && ng serve

# ~@:-]
