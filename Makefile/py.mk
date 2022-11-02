# required makefiles:
# - misc.mk

# required variables:

# optional variables:
# - PACKAGE
# - LOCALES_DIR

ifndef PY_DIR
PY_DIR        := $(shell for d in $$(echo $$PATH | tr ':' ' '); do \
					if [[ -d $$d && -x $$d && -r $$d ]]; then \
						if [[ $$(/usr/bin/find $$d -maxdepth 0 -name python -print | wc -l) -ne 0 ]]; then \
							echo $$d; \
							exit 0; \
						fi \
					fi \
				done)
endif
VENV_DIR      := venv

ACTIVATE      := $(VENV_DIR)/Scripts/activate
SITE_PACKAGES := $(VENV_DIR)/Lib/site-packages
MSGFMT        := $(PY_DIR)/Tools/i18n/msgfmt.py
PYGETTEXT     := $(PY_DIR)/Tools/i18n/pygettext.py
PYTHON        := $(PY_DIR)/python

PACKAGE       ?= $(shell basename $$PWD)
LOCALES_DIR   ?= locales

ifneq ($(wildcard $(LOCALES_DIR)),)
LANG_SRCS     := $(shell /usr/bin/find $(LOCALES_DIR) -name "*.po" -print)
LANG_OBJS     :=  $(LANG_SRCS:.po=.mo)
endif

PY_SRCS       := $(shell /usr/bin/find . -path ./$(VENV_DIR) -prune -o -name "*.py" -print)
REQUIREMENTS  := requirements.txt


do_activate   = [[ -z "$$VIRTUAL_ENV" ]] && . $(ACTIVATE) || true
pyenv         = $(do_activate) && $(1)


.PHONY: clean-pycache clean-pygettext clean-venv py-deps py-devdeps py-gettext-add py-gettext-catalog py-gettext-locales py-lint
.SUFFIXES: .po .mo


.po.mo:
	@$(call prompt-log,$< -> $@)
	@$(PYTHON) $(MSGFMT) -o $@ $<

$(ACTIVATE):
# Create python virtual environment
# The venv module provides support for creating lightweight "virtual environments" with
# their own site directories, optionally isolated from system site directories.
# https://docs.python.org/3/library/venv.html
	@$(call prompt-info,Creating virtual environment)
	@$(PYTHON) -m venv $(VENV_DIR)
# convert CRLF to LF in activate bash script
	@sed -i $$'s/\\r$$//' $(ACTIVATE)
	@$(call prompt-info,Upgrading pip)
	@$(call pyenv,python -m pip install --upgrade pip)

$(LANG_OBJS): $(LANG_SRCS)
# prevent compiling .mo files if .po files haven't changed

$(LOCALES_DIR):
	@mkdir -p $(LOCALES_DIR)

$(LOCALES_DIR)/$(ln)/LC_MESSAGES/$(PACKAGE).po: $(LOCALES_DIR)/$(PACKAGE).pot
ifdef ln
	@$(call prompt-info,Create empty locale $(@))
	@mkdir -p $(LOCALES_DIR)/$(ln)/LC_MESSAGES
	@-cp $(@) $(@:.po=-$(now).bak) > /dev/null 2>&1 || true
	@cp $(<) $(@)
else
	@$(call prompt-error,Missing language: set it with ln=LANG. Example 'make py-gettext-add ln=it')
endif

$(LOCALES_DIR)/$(PACKAGE).pot: $(PY_SRCS)
# create pot file only if python source changes
	@$(call prompt-info,Creating $(LOCALES_DIR)/$(PACKAGE).pot)
	@$(PYTHON) $(PYGETTEXT) -d $(PACKAGE) --no-location -o $(LOCALES_DIR)/$(PACKAGE).pot $(PY_SRCS)

$(SITE_PACKAGES): $(ACTIVATE) $(REQUIREMENTS)
# install dependencies only if requirements.txt file changes
	@$(call prompt-info,Installing dependencies)
	@$(call pyenv,pip install -Ur $(REQUIREMENTS))

py-clean-cache: ## Remove bytecode-compiled python files
	@$(call prompt-log,Removing bytecode-compiled python files)
	@/usr/bin/find . -name __pycache__ -type d  -print0 | xargs -0 -r rm -rf

py-clean-gettext: ## Remove generated and bytecode-compiled locales files
	@$(call prompt-log,Removing pot file "$(LOCALES_DIR)/$(PACKAGE).pot")
	@-rm $(LOCALES_DIR)/$(PACKAGE).pot
	@$(call prompt-log,Removing compiled locale translations files)
	@-rm $(LANG_OBJS)

py-clean-venv: ## Remove virtual evnironemnt
	@$(call prompt-log,Removing virtual environment)
	@rm -rf $(VENV_DIR)

py-deps: $(SITE_PACKAGES) ## Activate venv and install requirements

py-devdeps: py-deps ## Install both application and developer requirements (pylint, flake8)
	@$(call prompt-info,Installing developement requirements)
	@$(call pyenv,pip install -U pylint flake8)

py-gettext-add: $(LOCALES_DIR)/$(ln)/LC_MESSAGES/$(PACKAGE).po ## Create new empty locale. Example usage make py-gettext-add ln=it

py-gettext-catalog: $(LOCALES_DIR) $(LOCALES_DIR)/$(PACKAGE).pot ## Generate raw messages catalogs

py-gettext-locales: $(LANG_OBJS) ## Produce binary catalog files that are parsed by the Python gettext module in order to be used in program.

py-lint: ## Lint and static-check
# lint depends on devdeps, but if we put the dependency here we lost a lot of time
# trying to update pylint and flake8 that are most of the times already up-to-date
# so please consider to run lint target only after make py-devdeps.
	@$(call prompt-info,Running flake8)
	@$(call pyenv,python -m flake8 --config .github/linters/flake8 $(PY_SRCS)) && $(call prompt-success,Done) || $(call prompt-error,Failed)
	@$(call prompt-info,Running pylint)
	@$(call pyenv,python -m pylint  --recursive=y --rcfile=.github/linters/pylint.toml $(PY_SRCS)) && $(call prompt-success,Done) || $(call prompt-error,Failed)

# ~@:-]
