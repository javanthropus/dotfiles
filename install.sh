#!/bin/bash
# vim: noet ts=2 sw=2:

set -e

DOTFILES_DIR=$(cd "$(dirname $0)" && pwd)

cd "$DOTFILES_DIR"
find .* * -mindepth 0 -maxdepth 0 \
	! -name . ! -name .. \
	! -name .git \
	! -name .gitignore \
	! -name install.sh \
	! -name .\*.sw\? \
	-exec ln -snf "$DOTFILES_DIR/{}" ~/{} \;
