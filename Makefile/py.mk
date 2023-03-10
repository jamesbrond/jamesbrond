# pip and venv module must be already installed for the python you are going to use

# required makefiles:
# - misc.mk

# required variables:
# PYTHON

# optional variables:
# - PACKAGE

VENV_DIR       := .venv
ACTIVATE       := $(VENV_DIR)/bin/activate
PACKAGE        ?= $(shell basename $$PWD)
PY_SRCS        := $(shell git ls-files | grep ".*\.py$$")
REQUIREMENTS   := requirements.txt
PY_LOG_PREF    := PYTHON
PY_DEPS_DIR    := $(shell /usr/bin/find $(VENV_DIR) -name site-packages)
PY_DEPS_PYLINT := $(PY_DEPS_DIR)/pylint
PY_DEPS_FLAKE8 := $(PY_DEPS_DIR)/flake8

do_activate   = [[ -z "$$VIRTUAL_ENV" ]] && . $(ACTIVATE) || true
pyenv         = $(do_activate) && $(1)


.PHONY: --py-clean clean build distclean lint

$(ACTIVATE):
# Create python virtual environment
# The venv module provides support for creating lightweight "virtual environments" with
# their own site directories, optionally isolated from system site directories.
# https://docs.python.org/3/library/venv.html
	@$(call log-debug,$(PY_LOG_PREF),Creating virtual environment)
	@$(PYTHON) -m venv $(VENV_DIR)
	@chmod u+x $(ACTIVATE)
	@$(call log-debug,$(PY_LOG_PREF),Upgrading pip)
	@$(call pyenv,pip install --upgrade pip)

$(PY_DEPS_PYLINT) $(PY_DEPS_FLAKE8):
	@$(call log-debug,$(PY_LOG_PREF),Installing developement requirements $(@F))
	@$(call pyenv,pip install $(@F))

--py-clean:
	@$(call log-debug,$(PY_LOG_PREF),Removing bytecode-compiled python files)
	@/usr/bin/find . -name __pycache__ -type d  -print0 | xargs -0 -r rm -rf

clean:: --py-clean

distclean:: --py-clean
	@$(call log-debug,$(PY_LOG_PREF),Removing virtual environment)
	@rm -rf $(VENV_DIR)

$(PY_DEPS_DIR):
# install dependencies only if requirements.txt file changes
	@$(call log-debug,$(PY_LOG_PREF),Installing dependencies)
	@$(call pyenv,pip install -Ur $(REQUIREMENTS))

build:: $(ACTIVATE) $(REQUIREMENTS) $(PY_DEPS_DIR)

lint:: $(PY_DEPS_PYLINT) $(PY_DEPS_FLAKE8)
# lint depends on devdeps, but if we put the dependency here we lost a lot of time
# trying to update pylint and flake8 that are most of the times already up-to-date
# so please consider to run lint target only after installing devdeps.
	@$(call log-debug,$(PY_LOG_PREF),Running flake8)
	@$(call pyenv,python -m flake8 --config .github/linters/flake8 $(PY_SRCS)) && $(call log-success,$(PY_LOG_PREF),flake8 lint pass) || $(call log-error,$(PY_LOG_PREF),flake8 lint failed)
	@$(call log-debug,$(PY_LOG_PREF),Running pylint)
	@$(call pyenv,python -m pylint  --recursive=y --rcfile=.github/linters/pylint.toml $(PY_SRCS)) && $(call log-success,$(PY_LOG_PREF),pylint lint pass) || $(call log-error,$(PY_LOG_PREF),pylint lint failed)

test::
	@$(call log-debug,$(PY_LOG_PREF),Running unit tests)
	@$(call pyenv,python -m unittest -v)

coverage:: $(PY_DEPS_COVERAGE)
	@$(call log-debug,$(PY_LOG_PREF),Coverage)
	@$(call pyenv,coverage run -m unittest)
	@$(call pyenv,coverage report)

# ~@:-]
