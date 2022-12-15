# git executable must be in PATH

# required makefiles:
# - misc.mk

# required variables:
# DIST_DIR

# optional variables:
# - PACKAGE
# - VERSION_EXP
# - VERSION_FILE


PACKAGE              ?= $(shell basename $$PWD)

SOURCE_DIST_DIR      := $(DIST_DIR)/source

GIT_CURRENT_BRANCH   := $(shell git rev-parse --abbrev-ref HEAD)
GIT_MAIN_BRANCH      := main
GIT_RELEASE_BRANCH   := $(shell git describe --tags --abbrev=0 2>/dev/null)
GIT_CURRENT_REV      := $(shell git rev-list --count HEAD)
ifneq ($(strip $(GIT_RELEASE_BRANCH)),)
	GIT_RELEASE_REV  := $(shell git rev-list --count $(GIT_RELEASE_BRANCH))
else
	GIT_RELEASE_REV  := 0
endif
GIT_SRCS             := $(shell git ls-files)

SOURCE_OBJ_NAME      := $(PACKAGE)-$(GIT_RELEASE_BRANCH)-$(GIT_RELEASE_REV)
SOURCE_STABLE_OBJ    := $(SOURCE_DIST_DIR)/$(SOURCE_OBJ_NAME).tar.bz2
SOURCE_UNSTABLE_OBJ  := $(SOURCE_DIST_DIR)/$(SOURCE_OBJ_NAME)-unstaged.tar.bz2
SOURCE_STAGED_OBJ    := $(SOURCE_DIST_DIR)/$(SOURCE_OBJ_NAME).tar.bz2

GIT_LOG_PREF         := GIT

git_checkout = git checkout $1 --quiet
git_stash    = git stash --include-untracked --quiet
git_unstash  = [[ $$(git stash list | wc -l) -gt 0 ]] && git stash pop --quiet

zip_create   = tar -X .gitignore --exclude='.git' -jcf $1 .

ifdef VERSION_FILE
	ifdef VERSION_EXP
		git_update_version = sed -i -r -e "s/$(VERSION_EXP)/\1$1/" $(VERSION_FILE) && \
		git add $(VERSION_FILE) && \
		git commit -m "chore: release $1"
	else
		git_update_version = $(call log-warn,$(GIT_LOG_PREF),VERSION_EXP is not defined)
	endif
else
	git_update_version = $(call log-warn,$(GIT_LOG_PREF),VERSION_FILE is not defined)
endif

.PHONY: clean-source-dist git-release source-zip-release source-zip-unstaged source-zip

$(SOURCE_DIST_DIR): | $(SOURCE_DIST_DIR)
	@$(call log-debug,$(GIT_LOG_PREF),make directory $@)
	@mkdir -p $@

$(SOURCE_STABLE_OBJ): | $(SOURCE_DIST_DIR)
ifneq ($(strip $(GIT_RELEASE_BRANCH)),)
	@$(call log-debug,$(GIT_LOG_PREF),Creating $@)
	@$(git_stash)
	@$(call git_checkout,$(GIT_RELEASE_BRANCH))
	@$(call zip_create,$@)
	@$(call git_checkout,$(GIT_CURRENT_BRANCH))
	@$(git_unstash)
endif

$(SOURCE_UNSTABLE_OBJ): $(GIT_SRCS) | $(SOURCE_DIST_DIR)
	@$(call log-debug,$(GIT_LOG_PREF),Creating $@)
	@$(call zip_create,$@)

$(SOURCE_STAGED_OBJ): | $(SOURCE_DIST_DIR)
	@$(call log-debug,$(GIT_LOG_PREF),Creating $@)
	@$(git_stash)
	@$(call zip_create,$@)
	@$(git_unstash)

clean-release::
	@$(call log-debug,$(GIT_LOG_PREF),Removing output zip files)
	@-rm -f $(SOURCE_DIST_DIR)/$(PACKAGE)-*.tar.gz

clean-deep::
	@-rm -d $(SOURCE_DIST_DIR)

git-release: ## Ask for new git tag, update version and push it to github (releases are in branch main only)
	@$(call log-info,$(GIT_LOG_PREF),Last release: $(GIT_RELEASE_BRANCH))
	@$(git_stash)
	@$(call git_checkout, $(GIT_MAIN_BRANCH))
	@while [ -z "$$gittag" ]; do \
		read -r -p "new git tag: " gittag; \
	done && \
	$(call git_update_version,$$gittag) && \
	git tag -a $$gittag -m "new release $$gittag"
	@git push origin $(GIT_MAIN_BRANCH) --follow-tags
	@$(call git_checkout, $(GIT_CURRENT_BRANCH))
	@$(git_unstash)

source-stable: $(SOURCE_STABLE_OBJ) ## Create a distributable zip of the latest stable release

source-unstaged: $(SOURCE_UNSTABLE_OBJ) ## Create a distributable zip of current branch (with unstaged changes)

source: $(SOURCE_STAGED_OBJ) ## Create a distributable zip of current branch (without unstaged changes)

# ~@:-]
