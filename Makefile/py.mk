# pip and venv module must be already installed for the python you are going to use

# required makefiles:
# - misc.mk

# required variables:
# PYTHON

# optional variables:
# - PACKAGE
# - WORK_DIR

VENV_DIR       := $(WORK_DIR)/.venv
PYENV          = $(VENV_DIR)/bin
ifeq ($(OS), Windows_NT)
PYENV          = $(VENV_DIR)/Scripts
endif
ACTIVATE       = $(PYENV)/activate

ifeq ($(call is_git_repo),true)
PY_SRCS          = $(shell git ls-files | grep ".*\.py$$")
else
PY_SRCS          = $(shell /usr/bin/find . -path ./$(VENV_DIR) -prune -o -name "*.py" -print)
endif
PY_REQUIREMENTS  := $(wildcard requirements.txt)
PY_LOG_PREF      := PYTHON
PY_DEPS_DIR      := $(shell /usr/bin/find $(VENV_DIR) -name site-packages $(NULL_STDERR))
PY_DEPS_PYLINT   := $(PY_DEPS_DIR)/pylint
PY_DEPS_FLAKE8   := $(PY_DEPS_DIR)/flake8
PY_DEPS_COVERAGE := $(PY_DEPS_DIR)/coverage

PY_CONF_FLAKE8 ?= $(wildcard .flake8)
PY_CONF_PYLINT ?= $(wildcard .pylint.toml)

$(ACTIVATE):
# Create python virtual environment
# The venv module provides support for creating lightweight "virtual environments" with
# their own site directories, optionally isolated from system site directories.
# https://docs.python.org/3/library/venv.html
	@$(call log-info,$(PY_LOG_PREF),Creating virtual environment)
	@$(PYTHON) -m venv $(VENV_DIR)
	@sed -i 's/\r$$//g' $(ACTIVATE)
	@chmod u+x $(ACTIVATE)
	@$(call log-debug,$(PY_LOG_PREF),Upgrading pip)
	@$(PYENV)/python -m pip install --upgrade pip
	@$(call log-debug,$(PY_LOG_PREF),Installing dependencies)
ifneq ($(strip $(PY_REQUIREMENTS)),)
	@$(PYENV)/pip install -r $(PY_REQUIREMENTS)
endif

$(PY_DEPS_PYLINT) $(PY_DEPS_FLAKE8) $(PY_DEPS_COVERAGE):
	@$(call log-debug,$(PY_LOG_PREF),Installing developement requirements $(@F))
	@$(PYENV)/pip install $(@F)

clean::
	@$(call log-info,$(PY_LOG_PREF),Clean python)
	@$(call log-debug,$(PY_LOG_PREF),Removing bytecode-compiled python files)
	@/usr/bin/find . -name __pycache__ -type d  -print0 | xargs -0 -r rm -rf

distclean:: clean
	@$(call log-info,$(PY_LOG_PREF),Distclean python)
	@$(call log-debug,$(PY_LOG_PREF),Removing virtual environment)
	@-$(RMDIR) $(VENV_DIR) $(NULL_STDERR)
	@$(call log-debug,$(PY_LOG_PREF),Removing coverage files and folders)
	@-$(RM) .coverage $(NULL_STDERR)
	@-$(RMDIR) htmlcov $(NULL_STDERR)

build:: $(ACTIVATE)

lint:: $(ACTIVATE) $(PY_DEPS_FLAKE8) $(PY_DEPS_PYLINT)
ifneq ($(strip $(PY_SRCS)),)
	@$(call log-info,$(PY_LOG_PREF),Running python lint)
	@$(call log-debug,$(PY_LOG_PREF),Running flake8)
ifeq ($(strip $(PY_CONF_FLAKE8)),)
	@$(PYENV)/python -m flake8 $(PY_SRCS)
else
	@$(PYENV)/python -m flake8 --config $(PY_CONF_FLAKE8) $(PY_SRCS)
endif
	@$(call log-debug,$(PY_LOG_PREF),Running pylint)
ifeq ($(strip $(PY_CONF_PYLINT)),)
	@$(PYENV)/python -m pylint --recursive=y $(PY_SRCS)
else
	@$(PYENV)/python -m pylint --recursive=y --rcfile=$(PY_CONF_PYLINT) $(PY_SRCS)
endif
endif

test:: $(ACTIVATE)
	@$(call log-info,$(PY_LOG_PREF),Running python unit tests)
	@$(PYENV)/python -m unittest -v

coverage:: $(ACTIVATE) $(PY_DEPS_COVERAGE)
	@$(call log-info,$(PY_LOG_PREF),Python coverage)
	@$(PYENV)/coverage run -m unittest
	@$(PYENV)/coverage report

# ~@:-]
