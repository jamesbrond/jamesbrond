# requires misc.mk
# git executable must be in PATH

ifndef PACKAGE
	PACKAGE          := $(shell basename $$PWD)
endif

SOURCE_DIST_DIR = dist/source

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

git_checkout = git co $(1) --quiet
git_stash    = git stash --include-untracked --quiet
git_unstash  = [[ $$(git stash list | wc -l) -gt 0 ]] && git stash pop --quiet

zip_create   = tar -X .gitignore --exclude='.git' -jcf $(1) .

ifdef VERSION_FILE
	ifdef VERSION_EXP
		git_update_version = sed -i -r -e "s/$(VERSION_EXP)/\1$(1)/" $(VERSION_FILE) && \
		git add $(VERSION_FILE) && \
		git commit -m "chore: release $(1)"
	else
		git_update_version = $(call prompt-log,VERSION_EXP is not defined)
	endif
else
	git_update_version = $(call prompt-log,VERSION_FILE is not defined)
endif

.PHONY: clean-source-dist git-release source-zip-release source-zip-unstaged source-zip

$(SOURCE_DIST_DIR):
	@mkdir -p $(@)

$(SOURCE_DIST_DIR)/$(PACKAGE)-$(GIT_RELEASE_BRANCH)-$(GIT_RELEASE_REV).tar.bz2:
ifneq ($(strip $(GIT_RELEASE_BRANCH)),)
	@$(git_stash)
	@$(call git_checkout,$(GIT_RELEASE_BRANCH))
	@$(call zip_create,$@)
	@$(call git_checkout,$(GIT_CURRENT_BRANCH))
	@$(git_unstash)
endif

$(SOURCE_DIST_DIR)/$(PACKAGE)-$(GIT_CURRENT_BRANCH)-$(GIT_CURRENT_REV)-unstaged.tar.bz2: $(GIT_SRCS)
	@$(call zip_create,$@)

$(SOURCE_DIST_DIR)/$(PACKAGE)-$(GIT_CURRENT_BRANCH)-$(GIT_CURRENT_REV).tar.bz2:
	@$(git_stash)
	@$(call zip_create,$@)
	@$(git_unstash)

clean-source-dist: ## Clean zips in dist folder
	@$(call prompt-log,Removing output zip files)
	@-rm -f $(SOURCE_DIST_DIR)/$(PACKAGE)-*.tar.gz
	@-rm -d $(SOURCE_DIST_DIR) || echo ""

git-release: ## Ask for new git tag, update version and push it to github (releases are in branch main only)
	@$(call prompt-info,Last release: $(GIT_RELEASE_BRANCH))
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

source-zip-release: $(SOURCE_DIST_DIR) $(SOURCE_DIST_DIR)/$(PACKAGE)-$(GIT_RELEASE_BRANCH)-$(GIT_RELEASE_REV).tar.gz ## Create a distributable zip of the latest stable release

source-zip-unstaged: $(SOURCE_DIST_DIR) $(SOURCE_DIST_DIR)/$(PACKAGE)-$(GIT_CURRENT_BRANCH)-$(GIT_CURRENT_REV)-unstaged.tar.gz ## Create a distributable zip of current branch (with unstaged changes)

source-zip: $(SOURCE_DIST_DIR) $(SOURCE_DIST_DIR)/$(PACKAGE)-$(GIT_CURRENT_BRANCH)-$(GIT_CURRENT_REV).tar.gz ## Create a distributable zip of current branch (without unstaged changes)

# ~@:-]
