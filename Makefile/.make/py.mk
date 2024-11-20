# pip and venv module must be already installed for the python you are going to use

# required makefiles:
# - misc.mk

# required variables:
# PYTHON

# optional variables:
# - PACKAGE
# - BUILD_DIR
# - PY_CONF_FLAKE8
# - PY_CONF_PYLINT

VENV_DIR        ?= venv
PYENV           = $(VENV_DIR)/bin
ifeq ($(OS), Windows_NT)
	PYENV       = $(VENV_DIR)/Scripts
endif
COVERAGE_DIR    = $(BUILD_DIR)/htmlcov
DIRS            += $(COVERAGE_DIR)

ifeq ($(call is_git_repo),true)
	PY_SRCS     = $(shell comm -23 <(git ls-files | sort) <(git ls-files --deleted | sort) | grep -P '(\.py)(?=\s)')
else
	PY_SRCS     = $(shell /usr/bin/find . -path $(VENV_DIR) -prune -o -name "*.py" -print)
endif
PY_LOG_PREF     := PYTHON

PY_REQUIREMENTS ?= $(wildcard requirements.txt)
PY_DEV_DEPS     = pylint flake8 coverage
PY_DEV_DEPS_FILE:= $(VENV_DIR)/.install.devdeps.stamp
PY_DEV_PROD_FILE:= $(VENV_DIR)/.install.proddeps.stamp
PY_CONF_FLAKE8  ?= $(wildcard .flake8)
PY_CONF_PYLINT  ?= $(wildcard .pylint.toml)
# py_check_dep = $(shell $(PYENV)/python -c "import $1" $(NULL_STDERR); echo $$?)

.PHONY: coverage

$(PYENV):
# Create python virtual environment
# The venv module provides support for creating lightweight "virtual environments" with
# their own site directories, optionally isolated from system site directories.
# https://docs.python.org/3/library/venv.html
	@$(call log-debug,$(PY_LOG_PREF),Creating virtual environment)
	@$(PYTHON) -m venv $(VENV_DIR) --upgrade-deps

all:: $(PY_DEV_PROD_FILE)

clean::
	@$(call log-info,$(PY_LOG_PREF),Clean python)
	@$(call log-debug,$(PY_LOG_PREF),Removing bytecode-compiled python files)
	@/usr/bin/find . -name __pycache__ -type d -print0 | xargs -0 -r rm -rf

distclean:: clean
	@$(call log-info,$(PY_LOG_PREF),Distclean python)
	@$(call log-debug,$(PY_LOG_PREF),Removing virtual environment)
	@-$(RMDIR) $(VENV_DIR) $(NULL_STDERR)
	@$(call log-debug,$(PY_LOG_PREF),Removing coverage files and folders)
	@-$(RM) .coverage $(NULL_STDERR)
	@-$(RMDIR) $(COVERAGE_DIR) $(NULL_STDERR)

init:: $(PYENV) $(PY_DEV_DEPS_FILE) $(PY_DEV_PROD_FILE)
	@sed -i 's/\r$$//g' $(PYENV)/activate
ifeq ($(call is_git_repo),true)
	@$(call append_to_file,$(GIT_IGNORE),$(PYENV))
endif

lint:: $(PYENV) $(PY_DEV_DEPS_FILE) $(PY_DEV_PROD_FILE)
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

test:: $(PYENV) $(PY_DEV_PROD_FILE)
	@$(call log-info,$(PY_LOG_PREF),Running python unit tests)
	@$(PYENV)/python -m unittest -v

coverage: $(PYENV) $(PY_DEV_DEPS_FILE) $(PY_DEV_PROD_FILE) | $(COVERAGE_DIR) ## Code coverage test
	@$(call log-info,$(PY_LOG_PREF),Python coverage)
	@$(PYENV)/coverage run -m unittest
	@$(PYENV)/coverage html --skip-empty -q -d $(COVERAGE_DIR) --title $(PACKAGE)
	@$(PYENV)/coverage report --skip-empty

$(PY_DEV_DEPS_FILE):
	@$(call log-debug,$(PY_LOG_PREF),Installing developing dependencies)
	@$(PYENV)/pip install $(PY_DEV_DEPS)
	@touch $(PY_DEV_DEPS_FILE)

$(PY_DEV_PROD_FILE): $(PY_REQUIREMENTS)
ifneq ($(strip $(PY_REQUIREMENTS)),)
	@$(call log-debug,$(PY_LOG_PREF),Installing dependencies)
	@$(PYENV)/pip install -r $(PY_REQUIREMENTS)
endif
	@touch $(PY_DEV_PROD_FILE)

# ~@:-]
