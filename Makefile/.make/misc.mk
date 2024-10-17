# Default variables
PACKAGE   ?= $(shell basename $$PWD)
WORK_DIR  ?= .
BUILD_DIR ?= $(WORK_DIR)/build
DIST_DIR  ?= $(WORK_DIR)/release
# Current date in format YYYY-mm-dd
TODAY = $(shell date '+%F')
# Current date in format YYYYmmddHHMMSS
NOW = $(shell date '+%Y%m%d%H%M%S')
CONFIGURE = .makefile.conf

ifeq (ok,$(shell test -e /dev/null 2>&1 && echo ok))
	NULL_STDERR = 2>/dev/null
	NULL_STDIO  = 1>/dev/null
else
	NULL_STDERR = 2>NUL
	NULL_STDIO  = 1>NUL
endif

touch = touch $(1)
ifeq (,$(shell command -v touch $(NULL_STDERR)))
# https://ss64.com/nt/touch.html
	touch = type nul >> $(subst /,\,$(1)) && copy /y /b $(subst /,\,$(1))+,, $(subst /,\,$(1))
endif

RM ?= rm -f
ifeq (,$(shell command -v $(firstword $(RM)) $(NULL_STDERR)))
	RMDIR := rd /s /q
	RM    := del /q
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

# Replace in files
# usage file_replace,folder,files,find_str,replace_str
# example $(call file_replace,build,*,OLD_STR,NEW_STR))
# example $(call file_replace,docs,example.txt,OLD_STR,NEW_STR))
file_replace = /usr/bin/find "$1" -name "$2" -type f -exec sed -i "s/$3/$4/g" {} \;

# Execute command in specific folder
# usare exec_in,folder,command
# example $(call exec_in,$(BUILD_DIR),docker-compose up)
exec_in = cd "$1" && $2

# Create a new zip file
# Usage $(call zip,zip_filename.zip,files_list)
zip = zip -r -9 -q $1 $2

# check if current folder is in a valid git working tree
# Examples:
# $(if is_git_repo,@echo "This is a git repo")
# ifeq ($(call is_git_repo),true)
# ...
# endif
is_git_repo = $(shell git rev-parse --is-inside-work-tree)

# Recursive wildcard function:
# Examples:
# all py files in folder and subfolders
# ALL_PYS := $(call rwildcard,foo/,*.py)
rwildcard = $(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

# Appends a line to a file only if it does not already exist
# Examples:
# $(call append_to_file,.gitignore,__pycache__/)
append_to_file = $(shell grep -qsxF '$2' $1 || echo '$2' >> $1)

init::
	@$(call log-info,MISC,Create the $(CONFIGURE) file)
	@$(call log-info,MISC,if something is misconfigured please feel free to edit it according to your configuration)
	@$(call touch,$(CONFIGURE))

maintainer-clean::
	@$(call log-info,MISC,This command is intended for maintainers to use it)
	@$(call log-info,MISC,deletes files that may need special tools to rebuild)

help: ## Show Makefile help
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@grep -E -h '^[a-zA-Z_\.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CLR_PRF)$(BLUE)m%-20s$(CLR_OFF) %s\n", $$1, $$2}'

lint::
	@$(call log-debug,MISC,Makefile undefined variables)
	@$(MAKE) help --dry-run --warn-undefined-variables $(NULL_STDIO)

# ~@:-]
