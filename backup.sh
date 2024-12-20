#!/bin/bash

#######################################################################
BASE_DIR="/cygdrive/c"
BACKUP_DIR="$BASE_DIR/Users/320072283/OneDrive - Philips/backup"
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

### Add here all files (or folders) you wanto to backup!
INPUT_FILES="$BASE_DIR/Users/320072283/AppData/Roaming/Code/User/keybindings.json
$BASE_DIR/Users/320072283/AppData/Roaming/Code/User/settings.json
$BASE_DIR/Users/320072283/src/misc/todoist-template/
$BASE_DIR/Windows/System32/drivers/etc/hosts
$BASE_DIR/Users/320072283/bin/sumatra/SumatraPDF-settings.txt
$BASE_DIR/Users/320072283/AppData/Local/Microsoft/Edge/User Data/Default/Bookmarks
$BASE_DIR/Users/320072283/AppData/Roaming/Mozilla/Firefox/Profiles/xw4rvfwe.default-release/bookmarkbackups
$BASE_DIR/Users/320072283/.gitconfig
$SCRIPT
"

### virtual files: files that not exists but are command output that must be backupped
VIRTUAL_DIR="$BASE_DIR/OutputBackup"
mkdir -p "$VIRTUAL_DIR"
# visual studio code extensions
code --list-extensions --show-versions 2>&1 /dev/null > "$VIRTUAL_DIR/vscode_extensions.txt"
# cygwin installed packages
lista=$(mktemp)
cygcheck -cd | sed -e "1,2d" > $lista
awk 'NR==1{printf $1}{printf ",%s", $1}' ${lista} > "$VIRTUAL_DIR/cygwin_packages.txt"
######################################################################


INPUT_FILES="$INPUT_FILES
$VIRTUAL_DIR"

TODAY=$(date +%Y-%m-%d)
BACKUP_FILE=$BACKUP_DIR/backup-$TODAY.tgz

# remove backup file if it already exists
[ -e "$BACKUP_FILE" ] && rm -- "$BACKUP_FILE"

TAR_OPTS="--exclude-vcs --exclude-vcs-ignores --absolute-names"

echo "$INPUT_FILES" | tar $TAR_OPTS --transform="s|$BASE_DIR/||g" -zcvf "$BACKUP_FILE" -T -

# clean-up
rm -f "$lista"
rm -rf "$VIRTUAL_DIR"

# ~@:-]
