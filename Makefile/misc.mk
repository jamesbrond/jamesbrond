# required makefiles:
#

# required variables:
#

# optional variables:
#

.PHONY: help


# Default variables
PACKAGE   ?= $(shell basename $$PWD)
WORK_DIR  ?= .
BUILD_DIR ?= $(WORK_DIR)/.build
DIST_DIR  ?= $(WORK_DIR)/dist

ifeq (ok,$(shell test -e /dev/null 2>&1 && echo ok))
NULL_STDERR=2>/dev/null
else
NULL_STDERR=2>NUL
endif

touch = touch $(1)
ifeq (,$(shell command -v touch $(NULL_STDERR)))
# https://ss64.com/nt/touch.html
touch = type nul >> $(subst /,\,$(1)) && copy /y /b $(subst /,\,$(1))+,, $(subst /,\,$(1))
endif

RM ?= rm -f
ifeq (,$(shell command -v $(firstword $(RM)) $(NULL_STDERR)))
RMDIR := rd /s /q
RM := del /q
else
RMDIR := $(RM)r
endif


# Reset
CLR_PRF=\033[
CLR_OFF=$(CLR_PRF)0m

FONT_BOLD   = 1# Bold
FONT_UNDL   = 4# Underline
# 10 	Primary(default) font
# 11–19 	Alternate font
FONT_FRAMED = 51# Framed
FONT_ENC    = 52# Encircled
FONT_OVRLN  = 53# Overlined

# Foreground regular colors
BLACK       = 30
RED         = 31
GREEN       = 32
YELLOW      = 33
BLUE        = 34
PURPLE      = 35
CYAN        = 36
WHITE       = 37

# Background regular colors
ON_BLACK    = 40
ON_RED      = 41
ON_GREEN    = 42
ON_YELLOW   = 43
ON_BLUE     = 44
ON_PURPLE   = 45
ON_CYAN     = 46
ON_WHITE    = 47

# Foreground bright colors (aixterm not in standard)
IBLACK      = 90
IRED        = 91
IGREEN      = 92
IYELLOW     = 93
IBLUE       = 94
IPURPLE     = 95
ICYAN       = 96
IWHITE      = 97

# Background bright colors (aixterm not in standard)
ON_IBLACK   = 100
ON_IRED     = 101
ON_IGREEN   = 102
ON_IYELLOW  = 103
ON_IBLUE    = 104
ON_IPURPLE  = 105
ON_ICYAN    = 106
ON_IWHITE   = 107


# echoclr,COLOR_TXT,TEXT
# examples: $(call echoclr,WHITE,Hello world)
# examples: $(call echoclr,ON_IWHITE,Hello world)
echoclr = echo -e "$(CLR_PRF)$($1)m$(2)$(CLR_OFF)"

# echoclr_variant,COLOR_TXT,FONT_VARIANT,TEXT
# examples: $(call echoclr_variant,WHITE,FONT_UNDL,Hello world)
# examples: $(call echoclr_variant,ON_IWHITE,FONT_BOLD;Hello world)
echoclr_variant = echo -e "$(CLR_PRF)$($1);$($2)m$(3)$(CLR_OFF)"

# echobkgclr,COLOR_TXT,BACKGROUND_COLOR,TEXT
# examples: $(call echoclrbkg,WHITE,ON_RED,Hello world)
# examples: $(call echoclrbkg,BLUE,ON_IWHITE,Hello world)
echoclrbkg = echo -e "$(CLR_PRF)$($1);$($2)m$(3)$(CLR_OFF)"

# echoclrbkg_varian,COLOR_TXT,BACKGROUND_COLOR,FONT_VARIANT,TEXT
# examples: $(call echoclrbkg_variant,WHITE,ON_RED,FONT_BOLD,Hello world)
echoclrbkg_variant = echo -e "$(CLR_PRF)$($1);$($2);$($3)m$(4)$(CLR_OFF)"

# log-%,PREFIX?,TEXT
log  = echo -e "$(CLR_PRF)$($1)m[$2] $3$(CLR_OFF)"
log-success = $(call log,GREEN,$1,$2)
log-error   = $(call log,RED,$1,$2)
log-warn    = $(call log,YELLOW,$1,$2)
log-info    = $(call log,BLUE,$1,$2)
log-debug   = $(call log,BLACK,$1,$2)

# Random UUID generator
uuid = $(shell uuidgen)

# Return current date in format YYYY-mm-dd
today = $(shell date '+%F')

# Return current date in format YYYYmmddHHMMSS
now = $(shell date '+%Y%m%d%H%M%S')

# Replace in files
# usage file_replace,folder,files,find_str,replace_str
# example $(call file_replace,build,*,OLD_STR,NEW_STR))
# example $(call file_replace,docs,example.txt,OLD_STR,NEW_STR))
file_replace = /usr/bin/find "$1" -name "$2" -type f -exec sed -i "s/$3/$4/g" {} \;

# Execute command in specific folder
# usare exec_in,folder,command
# example $(call exec_in,$(BUILD_DIR),docker-compose up)
exec_in = cd "$1" && $2


# Create a new tgz file
# Usage $(call tgzip,zip_filename.tgz,files_list)
ifeq ($(OS), Windows_NT)
tgzip = 7z a -ttar -so source.tar $2 | 7z a -si $1
else
tgzip = tar -czf $1 $2
endif


# check if current folder is in a valid git working tree
# Examples:
# $(if is_git_repo,@echo "This is a git repo")
# ifeq ($(call is_git_repo),true)
# ...
# endif
is_git_repo = $(shell git rev-parse --is-inside-work-tree)


help: ## Show Makefile help
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@grep -E -h '^[a-zA-Z_\.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CLR_PRF)$(BLUE)m%-20s$(CLR_OFF) %s\n", $$1, $$2}'

# ~@:-]
