# pip and venv module must be already installed for the python you are going to use

# required makefiles:
# - misc.mk

# required variables:
# PYTHON

# optional variables:
# - PACKAGE
# - LOCALES_DIR

VENV_DIR      := venv

ACTIVATE      := $(VENV_DIR)/bin/activate
SITE_PACKAGES := $(VENV_DIR)/Lib/site-packages

PACKAGE       ?= $(shell basename $$PWD)
LOCALES_DIR   ?= locales

ifneq ($(wildcard $(LOCALES_DIR)),)
LANG_SRCS     := $(shell /usr/bin/find $(LOCALES_DIR) -name "*.po" -print)
LANG_OBJS     :=  $(LANG_SRCS:.po=.mo)
endif

PY_SRCS       := $(shell git ls-files | grep ".*\.py$$")
REQUIREMENTS  := requirements.txt

PY_PREFIX     := PYTHON


do_activate   = [[ -z "$$VIRTUAL_ENV" ]] && . $(ACTIVATE) || true
pyenv         = $(do_activate) && $(1)


.PHONY: clean-pycache clean-pygettext clean-venv py-deps py-devdeps py-gettext-add py-gettext-catalog py-gettext-locales py-lint
.SUFFIXES: .po .mo

.po.mo:
	@$(PYTHON) $(MSGFMT) -o $@ $<

$(ACTIVATE):
# Create python virtual environment
# The venv module provides support for creating lightweight "virtual environments" with
# their own site directories, optionally isolated from system site directories.
# https://docs.python.org/3/library/venv.html
	@$(call log,$(PY_PREFIX),Creating virtual environment)
	@$(PYTHON) -m venv $(VENV_DIR)
# convert CRLF to LF in activate bash script
	@$(call log,$(PY_PREFIX),Upgrading pip)
	@$(call pyenv,pip install --upgrade pip)

$(LANG_OBJS): $(LANG_SRCS)
# prevent compiling .mo files if .po files haven't changed

$(LOCALES_DIR):
	@mkdir -p $(LOCALES_DIR)

$(LOCALES_DIR)/$(ln)/LC_MESSAGES/$(PACKAGE).po: $(LOCALES_DIR)/$(PACKAGE).pot
ifdef ln
	@$(call log,$(PY_PREFIX),Create empty locale $(@))
	@mkdir -p $(LOCALES_DIR)/$(ln)/LC_MESSAGES
	@-cp $(@) $(@:.po=-$(now).bak) > /dev/null 2>&1 || true
	@cp $(<) $(@)
else
	@$(call prompt-error,Missing language: set it with ln=LANG. Example ln=it)
endif

$(LOCALES_DIR)/$(PACKAGE).pot: $(PY_SRCS) | $(LOCALES_DIR)
# create pot file only if python source changes
	@$(call log,$(PY_PREFIX),Creating $(LOCALES_DIR)/$(PACKAGE).pot)
	@$(PYTHON) $(PYGETTEXT) -d $(PACKAGE) -o $(LOCALES_DIR)/$(PACKAGE).pot $(PY_SRCS)

$(SITE_PACKAGES): $(ACTIVATE) $(REQUIREMENTS)
# install dependencies only if requirements.txt file changes
	@$(call log,$(PY_PREFIX),Installing dependencies)
	@$(call pyenv,pip install -Ur $(REQUIREMENTS))

clean::
	@$(call log,$(PY_PREFIX),Removing bytecode-compiled python files)
	@/usr/bin/find . -name __pycache__ -type d  -print0 | xargs -0 -r rm -rf

py-clean-gettext: ## Remove generated and bytecode-compiled locales files
	@$(call log,$(PY_PREFIX),Removing pot file "$(LOCALES_DIR)/$(PACKAGE).pot")
	@-rm $(LOCALES_DIR)/$(PACKAGE).pot
	@$(call log,$(PY_PREFIX),Removing compiled locale translations files)
	@-rm $(LANG_OBJS)

clean-deep:: py-clean-gettext
	@$(call log,$(PY_PREFIX),Removing virtual environment)
	@rm -rf $(VENV_DIR)

py-deps: $(SITE_PACKAGES) ## Activate venv and install requirements
deps:: py-deps

devdeps:: py-deps ## Install both application and developer requirements (pylint, flake8)
	@$(call log,$(PY_PREFIX),Installing developement requirements)
	@$(call pyenv,pip install -U pylint flake8)
	@$(call pyenv,pip install -U python-gettext)

py-gettext-add: $(LOCALES_DIR) py-gettext-catalog $(LOCALES_DIR)/$(ln)/LC_MESSAGES/$(PACKAGE).po ## Create new empty locale. Example usage make pygettext-add ln=it

py-gettext-catalog: $(LOCALES_DIR)/$(PACKAGE).pot ## Generate raw messages catalogs

py-gettext-locales: $(LANG_OBJS) ## Produce binary catalog files that are parsed by the Python gettext module in order to be used in program.

lint::
# lint depends on devdeps, but if we put the dependency here we lost a lot of time
# trying to update pylint and flake8 that are most of the times already up-to-date
# so please consider to run lint target only after installing devdeps.
	@$(call log,$(PY_PREFIX),Running flake8)
	@$(call pyenv,python -m flake8 --config .github/linters/flake8 $(PY_SRCS)) && $(call prompt-success,Done) || $(call prompt-error,Failed)
	@$(call log,$(PY_PREFIX),Running pylint)
	@$(call pyenv,python -m pylint  --recursive=y --rcfile=.github/linters/pylint.toml $(PY_SRCS)) && $(call prompt-success,Done) || $(call prompt-error,Failed)

# ~@:-]
