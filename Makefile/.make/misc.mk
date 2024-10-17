# Default variables
PACKAGE   ?= $(shell basename $$PWD)
WORK_DIR  ?= .
BUILD_DIR ?= $(WORK_DIR)/build
DIST_DIR  ?= $(WORK_DIR)/release
# Current date in format YYYY-mm-dd
TODAY = $(shell date '+%F')
# Current date in format YYYYmmddHHMMSS
NOW = $(shell date '+%Y%m%d%H%M%S')
CONFIGURE = .makefile.conf

is_git_repo = $(shell git rev-parse --is-inside-work-tree)

# Recursive wildcard function:
# Examples:
# all py files in folder and subfolders
# ALL_PYS := $(call rwildcard,foo/,*.py)
rwildcard = $(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

# Appends a line to a file only if it does not already exist
# Examples:
# $(call append_to_file,.gitignore,__pycache__/)
append_to_file = $(shell grep -qsxF '$2' $1 || echo '$2' >> $1)

init::
	@$(call log-info,MISC,Create the $(CONFIGURE) file)
	@$(call log-info,MISC,if something is misconfigured please feel free to edit it according to your configuration)
	@$(call touch,$(CONFIGURE))

maintainer-clean::
	@$(call log-info,MISC,This command is intended for maintainers to use it)
	@$(call log-info,MISC,deletes files that may need special tools to rebuild)

help: ## Show Makefile help
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@grep -E -h '^[a-zA-Z_\.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CLR_PRF)$(BLUE)m%-20s$(CLR_OFF) %s\n", $$1, $$2}'

lint::
	@$(call log-debug,MISC,Makefile undefined variables)
	@$(MAKE) help --dry-run --warn-undefined-variables $(NULL_STDIO)

# ~@:-]
