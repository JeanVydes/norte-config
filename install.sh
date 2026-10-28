#!/bin/sh
# Installs this configuration into Norte Code's configuration directory.
#
# It copies and never symlinks: a symlink into a git checkout makes the running
# host depend on the checkout still being there, and the point of the
# repository is that the files can be restored anywhere.
#
# Whatever was there is backed up first, with a timestamp, so a file this script
# overwrites is one a person can still read afterwards.

set -eu

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            echo "usage: install.sh [--dry-run]"
            echo "copies config.json, providers.json and models.json into the"
            echo "Norte Code configuration directory, backing up what was there"
            exit 0
            ;;
        *)
            echo "install.sh: unknown argument '$arg'" >&2
            exit 2
            ;;
    esac
done

# The same rule the host follows: XDG names the directory when it is set, and
# HOME is the fallback. Writing to a relative path would put the files wherever
# the script happened to be run from.
if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    DIR="$XDG_CONFIG_HOME/norte-code"
elif [ -n "${HOME:-}" ]; then
    DIR="$HOME/.config/norte-code"
else
    echo "install.sh: neither XDG_CONFIG_HOME nor HOME is set" >&2
    echo "install.sh: set HOME, or XDG_CONFIG_HOME to name the directory" >&2
    exit 1
fi

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
STAMP=$(date +%Y%m%d-%H%M%S)

echo "target: $DIR"

# A directory, not a file: `mkdir -p` on an existing file fails, and that
# failure is the message a person needs.
if [ ! -d "$DIR" ]; then
    if [ "$DRY_RUN" = 1 ]; then
        echo "would create $DIR"
    else
        mkdir -p "$DIR"
        echo "created $DIR"
    fi
fi

for name in config.json providers.json models.json; do
    source="$HERE/$name"
    if [ ! -f "$source" ]; then
        echo "install.sh: $source is missing" >&2
        exit 1
    fi
    target="$DIR/$name"
    if [ -f "$target" ] && ! cmp -s "$source" "$target"; then
        backup="$target.bak-$STAMP"
        if [ "$DRY_RUN" = 1 ]; then
            echo "would back up $target to $backup"
        else
            cp "$target" "$backup"
            echo "backed up $(basename "$target") to $(basename "$backup")"
        fi
    fi
    if [ "$DRY_RUN" = 1 ]; then
        echo "would copy $name"
    else
        # A temporary file renamed into place, so a reader never sees a
        # half-written catalogue: the host reads these at startup.
        tmp="$target.tmp.$$"
        cp "$source" "$tmp"
        chmod 600 "$tmp"
        mv "$tmp" "$target"
        echo "installed $name"
    fi
done

if [ "$DRY_RUN" = 1 ]; then
    echo "dry run: nothing was written"
else
    echo
    echo "Keys are read from the environment, and are not installed by this script."
    echo "Check with: norte-code models"
fi
