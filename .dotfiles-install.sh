#!/bin/bash
# vim: ts=2 sw=2 noet ft=sh:

set -e

if [ -n "$1" ]; then
	ROOT="$1"
	shift
elif [ -n "$HOME" ]; then
	ROOT="$HOME"
else
	echo '$HOME is not set or empty' >&2
	exit 1
fi

mkdir -p "$ROOT"

export GIT_DIR="$ROOT/.dotfiles"

if [ -e "$GIT_DIR" ]; then
	echo "$ROOT is already managed by the dotfiles repository" >&2
	exit 1
fi

git init
git config --local core.bare false
git config --local core.worktree ..
git config --local core.logallrefupdates true
git config --local status.showUntrackedFiles no
git remote add -f origin git@github.com:javanthropus/dotfiles.git
git remote set-head origin -a
git checkout --track $(git rev-parse --abbrev-ref origin/HEAD) -f
