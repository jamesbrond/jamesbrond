# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

function __git_dirty {
    [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit, working tree clean" ]] && echo "*"
}

function __git_ps1() {
    git branch 2> /dev/null | grep '^*' | cut -d ' ' -f2- | xargs -I BRANCH_NAME echo -n "$(__git_dirty)BRANCH_NAME" | xargs -I BRANCH echo -n "$1"
}

function __color() {
    echo "\[\033[0;$1m\]"
}

if [ "$color_prompt" = yes ]; then
    CLR_CHROOT=$(__color 37)
    CLR_USER=$(__color 33)
    CLR_VENV=$(__color 34)
    CLR_HOST=$(__color 32)
    CLR_PATH=$(__color 36)
    CLR_GIT=$(__color 35)
    # CLR_FG=30
    CLR_RESET="\[\033[0m\]"

    PS1="\${VIRTUAL_ENV:+$CLR_VENV«\$(basename \$VIRTUAL_ENV)»$CLR_RESET }$CLR_USER\u$CLR_RESET@$CLR_HOST\h$CLR_RESET:$CLR_PATH\w$CLR_RESET\$(__git_ps1 ' $CLR_GIT⑂BRANCH$CLR_RESET') \\$ "
fi


# The following block is surrounded by two delimiters.
# possible value are: oneline, twolines, moba
# PROMPT_ALTERNATIVE=oneline
# NEWLINE_BEFORE_PROMPT=no
# SHOW_GIT_BRANCH=yes

# function parse_git_dirty {
#     [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit, working directory clean" ]] && echo "~"
# }

# if [ "$color_prompt" = yes ]; then
#     # override default virtualenv indicator in prompt
#     VIRTUAL_ENV_DISABLE_PROMPT=1
#     ICON_ARROW=$'\xEe\x82\xB0'
#     PROMPT_USER="\$"
#     ICON_USER=🐵
#     CLR_USER=36
#     CLR_CHROOT=90
#     CLR_VENV=33
#     CLR_HOST=32
#     CLR_PATH=34
#     CLR_GIT=35
#     CLR_FG=30

#     color() {
#         if [ $# -eq 1 ]; then
#             echo "\e[$1m"
#         elif [ $# -eq 2 ]; then
#             echo "\e[${1};${2}m"
#         fi
#     }

#     __git_ps1() {
#        git branch 2> /dev/null | grep '^*' | colrm 1 2 | xargs -I BRANCH echo -n $1
#     }

#     arrow() { echo "\e[7m\e[$1m$ICON_ARROW\e[27m"; }
#     color_reset() {	echo "\e[39;49;00m"; }

#     __init_twolines() { echo "$(color_reset)╒══"; }
#     __chroot_twolines() { echo "\${debian_chroot:+$(color_reset)═╡'$(color $CLR_CHROOT)'\$debian_chroot'$(color_reset)'╞}"; }
#     __host_twolines() { echo "$(color $CLR_HOST)@\h$(color_reset)╞"; }
#     __user_twolines() { echo "$(color $CLR_USER)$ICON_USER \u"; }
#     __venv_twolines() { echo "\${VIRTUAL_ENV:+$(color_reset)═╡$(color $CLR_VENV)\$(basename \$VIRTUAL_ENV)$(color_reset)╞}"; }
#     __path_twolines() { echo "$(color_reset)═╡$(color $CLR_PATH)\w$(color_reset)"; }
#     __end_twolines() { echo "$(color_reset)═══╡"; }
#     __prompt_twolines() { echo "└─$PROMPT_USER "; }
#     __git_twolines() { echo "$(color_reset)╞═╡$(color $CLR_GIT)\$(__git_ps1 '[BRANCH]')$(color_reset)"; }

#     __init_oneline() { echo "$(color_reset)"; }
#     __chroot_oneline() { echo "\${debian_chroot:+($(color $CLR_CHROOT)\$debian_chroot$(color_reset))}"; }
#     __host_oneline() { echo "$(color $CLR_HOST)@\h$(color_reset):"; }
#     __user_oneline() { echo "$(color $CLR_USER)$ICON_USER \u"; }
#     __venv_oneline() { echo "\${VIRTUAL_ENV:+$(color $CLR_VENV)«\$(basename \$VIRTUAL_ENV)»$(color_reset)}"; }
#     __path_oneline() { echo "$(color_reset)$(color $CLR_PATH)\w"; }
#     __end_oneline() { echo "$(color_reset)"; }
#     __prompt_oneline() { echo "$PROMPT_USER "; }
#     __git_oneline() { echo " $(color $CLR_GIT)\$(__git_ps1 '[BRANCH]')"; }

#     __init_moba() { echo "$(color_reset)"; }
#     __chroot_moba() { echo "\${debian_chroot:+$(color $CLR_FG $((CLR_CHROOT+10))) \$debian_chroot $(arrow $CLR_HOST)}"; }
#     __host_moba() { echo "$(arrow $CLR_HOST)$(color $CLR_FG $((CLR_HOST+10))) \h "; }
#     __user_moba() { echo "$(color $CLR_FG $((CLR_USER+10)))$ICON_USER \u "; }
#     __venv_moba() { echo "\${VIRTUAL_ENV:+$(arrow $CLR_VENV)$(color $CLR_FG $((CLR_VENV+10))) \$(basename \$VIRTUAL_ENV) }"; }
#     __path_moba() { echo "$(arrow $CLR_PATH)$(color $CLR_FG $((CLR_PATH+10))) \w "; }
#     __end_moba() { echo "$(arrow 30)$(color_reset)"; }
#     __prompt_moba() { echo "$PROMPT_USER "; }
#     #__git_moba() { echo "$(arrow $CLR_PATH)$(color $CLR_FG $((CLR_PATH+10)))\$(__git_ps1 '[$(color $CLR_GIT)%s$(color $CLR_FG)]')"; }
#     __git_moba() { echo "\$(__git_ps1 '$(arrow $CLR_GIT)$(color $CLR_FG $((CLR_GIT+10)))$(color $CLR_GIT) BRANCH $(color $CLR_FG)')"; }

#     if [ "$EUID" -eq 0 ]; then # Change prompt colors for root user
#         CLR_USER=31
#         PROMPT_USER="#"
#         ICON_USER=💀
#     fi

#     PS1=$(eval '__init_$PROMPT_ALTERNATIVE')
#     PS1="$PS1$(eval '__chroot_$PROMPT_ALTERNATIVE')"
#     PS1="$PS1$(eval '__user_$PROMPT_ALTERNATIVE')"
#     PS1="$PS1$(eval '__host_$PROMPT_ALTERNATIVE')"
#     PS1="$PS1$(eval '__venv_$PROMPT_ALTERNATIVE')"
#     PS1="$PS1$(eval '__path_$PROMPT_ALTERNATIVE')"
#     if [ $SHOW_GIT_BRANCH == 'yes' ]; then
#         PS1="$PS1$(eval '__git_$PROMPT_ALTERNATIVE')"
#     fi
#     PS1="$PS1$(eval '__end_$PROMPT_ALTERNATIVE')"
#     if [ $NEWLINE_BEFORE_PROMPT == 'yes' ] || [ $PROMPT_ALTERNATIVE == 'twolines' ]; then
#         PS1="$PS1\n"
#     fi
#     PS1="$PS1$(eval '__prompt_$PROMPT_ALTERNATIVE')"

#     #PS1='${VIRTUAL_ENV:+\[\033[01;32m\]«$(basename $VIRTUAL_ENV)»\[\033[00m\] }\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " \[\033[01;37m\]⌐%s\[\033[00m\]")\$ '
# else
#     PS1='${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV)}\u@\h:\w$PROMPT_USER '
# fi


# if [ "$color_prompt" = yes ]; then
#     PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# else
#     PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
# fi


unset color_prompt force_color_prompt

[ "$NEWLINE_BEFORE_PROMPT" = yes ] && PROMPT_COMMAND="PROMPT_COMMAND=echo"

# enable color support of ls, less and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
    # colored GCC warnings and errors
    export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
fi

# Functions
# Copy a file to the current directory with today’s date automatically appended to the end.
bu() { cp $@ $@.bak-`date +%y%m%d%H%M%S`; }
# Change directory and list files
cdl() { cd "$@"; ls; }
# Create and go to directory
mkdircd () { mkdir -p $1; cd $1; }
# Go up by <N> directories
up() {
    COUNTER=${1:-1}
    while [[ $COUNTER -gt 0 ]]; do
        UP="${UP}../"
        COUNTER=$(( $COUNTER -1 ))
    done
    cd $UP
    UP=''
}

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias lal='ls -Al'
alias l='ls -CF'
# Find the files that has been added/modified most recently
alias lt='ls -lrt'

alias df='df -h'
alias du='du -ch'
# Gets the total disk usage on your machine
alias totalusage='df -hl --total | grep total'
# Shoot the fat ducks in your current dir and sub dirs
alias ducks='du -ck | sort -nr | head'

# Gives you what is using the most space. Both directories and files. Varies on current directory
alias dumost='du -hsx * | sort -rh'

alias grepnocomment="grep -Ev '^(#|$)'"

# progress bar on file copy. Useful evenlocal.
alias copy='rsync --progress -ravz'

# handy short cuts #
alias h='history'
alias j='jobs -l'

# Show open ports
alias ports='netstat -tanp'

# Add safety nets
# do not delete / or prompt if deleting more than 3 files at a time #
alias del='rm -I --preserve-root'

# update on one command
alias update='sudo apt-get update && sudo apt-get upgrade'

# reboot / halt / poweroff
alias reboot='sudo /sbin/reboot'
alias poweroff='sudo /sbin/poweroff'
alias halt='sudo /sbin/halt'
alias shutdown='sudo /sbin/shutdown'

## get top process eating memory
alias psmem='ps auxf | sort -nr -k 4'

## get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
# ~@:-]
