# required makefiles:
# - misc.mk

# required variables:
# -BUILD_DIR
# - DIST_DIR
# - NG_DIR
# optional variables:
# - PACKAGE

SHELL:=/bin/bash

ROOT_DIR     := .
NG_BUILD_DIR := $(BUILD_DIR)/ng
NG_DIST_DIR := $(DIST_DIR)/www
NG_SRCS      := $(shell /usr/bin/find $(NG_DIR)/ -name 'node_modules' -type d -prune -o -name '.angular' -type d -prune -name '.vscode' -type d -prune -o -type f -print)
NG_OBJ       := $(NG_BUILD_DIR)/index.html
NG_DIST_OBJ  := $(NG_DIST_DIR)/$(PACKAGE)-WEB.tar.bz2
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


$(NG_BUILD_DIR) $(NG_DIST_DIR):
	@$(call log-debug,$(NG_LOG_PREF),make '$@' folder)
	@mkdir -p $@

$(NG_OBJ): $(NG_SRCS) | $(NG_BUILD_DIR)
	@$(call log-debug,$(NG_LOG_PREF),Build Angular UI)
	@$(call exec_in,$(NG_DIR),ng build --configuration=production --output-path $(NG_RELPATH)/$(NG_BUILD_DIR))

$(NG_DIST_OBJ): $(NG_OBJ) | $(NG_DIST_DIR)
	@tar --transform=s,build/ng,$(PACKAGE), -jcf $(NG_DIST_OBJ) $(NG_BUILD_DIR)

clean::
	@$(call log-debug,$(NG_LOG_PREF),Removing angular generated files)
	-@rm -rf $(NG_BUILD_DIR)

distclean::
	@rm -rf $(NG_DIST_DIR)

build:: $(NG_OBJ)

dist:: $(NG_DIST_OBJ)

ng-serve:
	@$(call log-info,$(NG_LOG_PREF),NG serve)
	@$(call exec_in,$(NG_DIR),ng serve)

lint::
	@$(call log-debug,$(NG_LOG_PREF),Running angular linting)
	@$(call exec_in,$(NG_DIR),ng lint)

# ~@:-]
