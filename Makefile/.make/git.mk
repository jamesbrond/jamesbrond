# Add this makefile if git is the current versioning system for this project
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

GIT_HOOKS_DIR ?= .githooks
GIT_IGNORE    := .gitignore
TAR_DIST_DIR  := $(DIST_DIR)/source
DIRS          += $(GIT_HOOKS_DIR) $(TAR_DIST_DIR)

ifneq ("$(wildcard $(VERSION_FILE))","")
	ifdef VERSION_EXP
		VERSION = $(shell sed -nr "s/$(VERSION_EXP)/\2/p" $(VERSION_FILE))
		git_update_version = sed -i -re "s/$(VERSION_EXP)/\1$1\3/" $(VERSION_FILE) \
			&& git add $(VERSION_FILE) \
			&& git commit -m"chore: release $1"
	endif
endif
ifndef git_update_version
	git_update_version = $(call log-warn,GIT,Cannot update version file)
endif
ifndef VERSION
	VERSION = 0
endif

GIT_CURRENT_BRANCH   := $(shell git rev-parse --abbrev-ref HEAD)
GIT_MAIN_BRANCH      := main
GIT_RELEASE_BRANCH   := $(shell git describe --tags --abbrev=0 $(NULL_STDERR))
GIT_CURRENT_REV      := $(shell git rev-list --count HEAD)
ifneq ($(strip $(GIT_RELEASE_BRANCH)),)
	GIT_RELEASE_REV  = $(shell git rev-list --count $(GIT_RELEASE_BRANCH))
else
	GIT_RELEASE_REV  = 0
endif

ifeq ($(MAKECMDGOALS),tar-bleeding)
	GIT_SRCS_CMD := comm -23 <(git ls-files | sort) <(git ls-files --deleted | sort)
# (git status --short| grep '^?' | cut -d\  -f2- && git ls-files ) | ( xargs -d '\n' -- stat -c%n 2>/dev/null  ||: )
else
	GIT_SRCS_CMD := git ls-files
endif
GIT_SRCS = $(shell $(GIT_SRCS_CMD))

TAR_BLEEDING_OBJ  := $(TAR_DIST_DIR)/$(PACKAGE)-$(VERSION)-$(GIT_CURRENT_REV)-BLEEDING.zip
TAR_RELEASE_OBJ   := $(TAR_DIST_DIR)/$(PACKAGE)-$(VERSION)-$(GIT_RELEASE_REV).zip
TAR_UNSTABLE_OBJ  := $(TAR_DIST_DIR)/$(PACKAGE)-$(VERSION)-$(GIT_CURRENT_REV).zip

git_checkout = git checkout $1 --quiet
git_stash    = git stash --include-untracked --quiet
git_unstash  = [[ $$(git stash list | wc -l) -gt 0 ]] && git stash pop --quiet || echo ''


.PHONY: git-release tar-bleeding tar-release tar

$(TAR_BLEEDING_OBJ): $(GIT_SRCS) | $(TAR_DIST_DIR)
	@$(call log-debug,GIT,Creating $@)
	@$(call zip,$@,$(GIT_SRCS))

$(TAR_RELEASE_OBJ): | $(TAR_DIST_DIR)
ifneq ($(strip $(GIT_RELEASE_BRANCH)),)
	@$(call log-debug,GIT,Creating $@)
	@$(git_stash) && \
	$(call git_checkout,$(GIT_RELEASE_BRANCH)) && \
	$(call zip,$@,$(GIT_SRCS)) && \
	$(call git_checkout,$(GIT_CURRENT_BRANCH)) && \
	$(git_unstash)
endif

$(TAR_UNSTABLE_OBJ): | $(TAR_DIST_DIR)
	@$(call log-debug,GIT,Creating $@)
	@$(git_stash) && \
	$(call zip,$@,$(GIT_SRCS)) && \
	$(git_unstash)

init:: | $(GIT_HOOKS_DIR)
	@$(call log-debug,GIT,Set hooks folder $(GIT_HOOKS_DIR) [require git > 2.9])
	@git config --local core.hooksPath $(GIT_HOOKS_DIR)
	@$(call log-debug,GIT,Add ignore dirs [$(DIRS)] to .gitignore)
	@for I in $(DIRS) ; do \
		if ! grep -Fqm1 $$I/ .gitignore; then \
			echo $$I/ >> .gitignore ; \
		fi ; \
	done
	@$(call append_to_file,$(GIT_IGNORE),$(BUILD_DIR))
	@$(call append_to_file,$(GIT_IGNORE),$(MAKE_DIR))

clean::
	@$(call log-debug,GIT,Removing output source files)
	@-$(RM) $(TAR_DIST_DIR)/*.zip $(NULL_STDERR)

distclean:: clean
	@$(call log-debug,GIT,deleting '$(TAR_DIST_DIR)' folder)
	@-$(RMDIR) $(TAR_DIST_DIR) $(NULL_STDERR)

git-release: ## Ask for new git tag, update version and push it to github (releases are in branch main only)
ifneq ($(call is_git_repo),true)
	$(error It's not a git repo)
endif
ifeq ("$(wildcard $(VERSION_FILE))","")
	$(error VERSION_FILE does not exist)
endif
ifeq ($(strip $(VERSION)),)
	$(error Cannot get current version)
endif
	@$(call log-info,GIT,Last release: $(VERSION))
	@$(git_stash)
	@$(call git_checkout,$(GIT_MAIN_BRANCH))
	@while [ -z "$$gittag" ]; do \
		read -r -p "new version: " gittag; \
	done && \
	$(call git_update_version,$$gittag) && \
	git tag -a $$gittag -m "new release $$gittag"
	@git push origin $(GIT_MAIN_BRANCH) --follow-tags
	@$(call git_checkout, $(GIT_CURRENT_BRANCH))
	@$(git_unstash)

tar-bleeding: $(TAR_BLEEDING_OBJ) ## Create a distributable zip of current branch (with unstaged changes)

tar-release: $(TAR_RELEASE_OBJ) ## Create a distributable zip of the latest stable release

tar: $(TAR_UNSTABLE_OBJ) ## Create a distributable zip of current branch (without unstaged changes)

# ~@:-]
