# git executable must be in PATH

# required makefiles:
# - misc.mk

# required variables:

# optional variables:
# - PACKAGE
# - DIST_DIR
# - VERSION_EXP
# - VERSION_FILE
# - GIT_HOOKS_DIR

GIT_HOOKS_DIR        ?= .githooks
SOURCE_DIST_DIR      := $(DIST_DIR)/source
GIT_LOG_PREF         := GIT

ifneq (,$(findstring tar,$(MAKECMDGOALS)))
GIT_CURRENT_BRANCH   := $(shell git rev-parse --abbrev-ref HEAD)
GIT_MAIN_BRANCH      := main
GIT_RELEASE_BRANCH   := $(shell git describe --tags --abbrev=0 $(NULL_STDERR))
GIT_CURRENT_REV      := $(shell git rev-list --count HEAD)
ifneq ($(strip $(GIT_RELEASE_BRANCH)),)
	GIT_RELEASE_REV  := $(shell git rev-list --count $(GIT_RELEASE_BRANCH))
else
	GIT_RELEASE_REV  := 0
endif
GIT_SRCS             := $(shell git ls-files)


SOURCE_STABLE_OBJ    := $(SOURCE_DIST_DIR)/$(PACKAGE)-$(GIT_RELEASE_BRANCH)-$(GIT_RELEASE_REV).tgz
SOURCE_UNSTABLE_OBJ  := $(SOURCE_DIST_DIR)/$(PACKAGE)-$(GIT_RELEASE_BRANCH)-$(GIT_CURRENT_REV)-UNSTABLE.tgz
SOURCE_SCREENSHOT_OBJ:= $(SOURCE_DIST_DIR)/$(PACKAGE)-$(GIT_RELEASE_BRANCH)-$(GIT_CURRENT_REV)-SCREENSHOT.tgz
endif

DIRS                 += $(SOURCE_DIST_DIR) $(GIT_HOOKS_DIR)

ifneq ("$(wildcard $(VERSION_FILE))","")
	ifdef VERSION_EXP
		VERSION = $(shell sed -nr "s/$(VERSION_EXP)/\2/p" $(VERSION_FILE))
	endif
endif

# git_current_version = sed -nr "s/$(VERSION_EXP)/\2/p" $(VERSION_FILE)
git_update_version  = sed -i -re "s/$(VERSION_EXP)/\1$1\3/" $(VERSION_FILE)
git_checkout = git checkout $1 --quiet
git_stash    = git stash --include-untracked --quiet
git_unstash  = [[ $$(git stash list | wc -l) -gt 0 ]] && git stash pop --quiet


.PHONY: git-release tar-screenshot tar-unstable tar

$(SOURCE_STABLE_OBJ): | $(SOURCE_DIST_DIR)
ifneq ($(strip $(GIT_RELEASE_BRANCH)),)
	@$(call log-debug,$(GIT_LOG_PREF),Creating $@)
	@$(git_stash)
	@$(call git_checkout,$(GIT_RELEASE_BRANCH))
	@$(call tgzip,$@,$(GIT_SRCS))
	@$(call git_checkout,$(GIT_CURRENT_BRANCH))
	@$(git_unstash)
endif

$(SOURCE_SCREENSHOT_OBJ): $(GIT_SRCS) | $(SOURCE_DIST_DIR)
	@$(call log-debug,$(GIT_LOG_PREF),Creating $@)
	@$(call tgzip,$@,$(GIT_SRCS))

$(SOURCE_UNSTABLE_OBJ): | $(SOURCE_DIST_DIR)
	@$(call log-debug,$(GIT_LOG_PREF),Creating $@)
	@$(git_stash)
	@$(call tgzip,$@,$(GIT_SRCS))
	@$(git_unstash)

init:: | $(GIT_HOOKS_DIR)
	@$(call log-debug,$(GIT_LOG_PREF),Set hooks folder $(GIT_HOOKS_DIR) [require git > 2.9])
	@git config --local core.hooksPath $(GIT_HOOKS_DIR)

clean::
	@$(call log-debug,$(GIT_LOG_PREF),Removing output source files)
	@-$(RM) SOURCE_STABLE_OBJ $(NULL_STDERR)
	@-$(RM) SOURCE_UNSTABLE_OBJ $(NULL_STDERR)
	@-$(RM) SOURCE_SCREENSHOT_OBJ $(NULL_STDERR)

distclean:: clean
	@$(call log-debug,$(GIT_LOG_PREF),deleting '$(SOURCE_DIST_DIR)' folder)
	@-$(RMDIR) $(SOURCE_DIST_DIR) $(NULL_STDERR)

git-release: ## Ask for new git tag, update version and push it to github (releases are in branch main only)
ifeq ("$(wildcard $(VERSION_FILE))","")
	$(error VERSION_FILE does not exist)
endif
ifeq ($(strip $(VERSION)),)
	$(error Cannot get current version)
endif
	@$(call log-info,$(GIT_LOG_PREF),Last release: $(VERSION))
	@$(git_stash)
# @$(call git_checkout, $(GIT_MAIN_BRANCH))
# @while [ -z "$$gittag" ]; do \
# 	read -r -p "new version: " gittag; \
# done && \
# $(call git_update_version,$$gittag) && \
# git add $(VERSION_FILE) && \
# git commit -m"chore: release $1 && \
# git tag -a $$gittag -m "new release $$gittag"
# @git push origin $(GIT_MAIN_BRANCH) --follow-tags
# @$(call git_checkout, $(GIT_CURRENT_BRANCH))
	@$(git_unstash)

tar-screenshot: $(SOURCE_SCREENSHOT_OBJ) ## Create a distributable tgz of current branch (with unstaged changes)

tar-unstable: $(SOURCE_UNSTABLE_OBJ) ## Create a distributable tgz of current branch (without unstaged changes)

tar: $(SOURCE_STABLE_OBJ) ## Create a distributable tgz of the latest stable release

# ~@:-]
