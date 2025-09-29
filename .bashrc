# vim: ts=2 sw=2 noet:

# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.

umask 022
PATH=~/bin:/bin:$PATH

# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]]; then
	# Shell is non-interactive.  Be done now
	return
fi

# Shell is interactive.  It is okay to produce output at this point.
# Do setup for command-line interactivity.

# Make managing the dotfiles content easy.
alias dotfiles='git --git-dir $HOME/.dotfiles'

case "$TERM" in
	screen|xterm*|rxvt|Eterm|eterm|cygwin|linux)
		COLOR_RED='\[\033[31m\]'
		COLOR_GREEN='\[\033[32m\]'
		COLOR_BLUE='\[\033[34m\]'
		COLOR_YELLOW='\[\033[33m\]'
		COLOR_RESET='\[\033[0m\]'
		;;
esac

function ps1_title {
	case "$TERM" in
		screen|xterm*|rxvt|Eterm|eterm)
			echo '\[\033]0;${TERM_TITLE}\u@\h:\w\007\]'
			;;
	esac
}

function ps1_kube {
	[ -z "$SESSION_KUBECONFIG" ] && return
	echo '\n'$COLOR_BLUE'[$(kube_info)]'$COLOR_RESET
}

function ps1_info {
	echo '\n'$COLOR_GREEN'\u@\h '$COLOR_YELLOW'\w'$COLOR_RESET
}

function ps1_git {
	type -t __git_ps1 >/dev/null || return
	echo $COLOR_RED'$(__git_ps1)'$COLOR_RESET
}

function prompt_command {
	PS1=$(ps1_title)$(ps1_kube)$(ps1_info)$(ps1_git)'\n\$ '
}

PROMPT_COMMAND='prompt_command'

# Pick a nice pager for man.
if type vim >&/dev/null; then
	export MANPAGER='vim -M +MANPAGER --not-a-term -'
fi

# Beep...
alias beep="echo -ne \"\\007\""

# Set the editor.
EDITORS='nvim vim vi'
if type -aP $EDITORS >/dev/null; then
	export EDITOR=$(type -aP $EDITORS | head -n 1)
fi
unset EDITORS

# Directory and file coloring for ls
[ -e ~/.dircolors ] && DIRCOLORS=~/.dircolors
eval $(dircolors -b $DIRCOLORS)
alias ls='ls --color=auto'

# Activate bash-completion.
[ -f /etc/bash_completion ] && source /etc/bash_completion

# Set up bash completions for k8s, if available.
source <(kubectl completion bash 2>/dev/null)

# This loads rbenv, if available.
if [[ -x "$HOME/.rbenv/bin/rbenv" ]]; then
	PATH="$HOME/.rbenv/bin:$PATH"
	eval "$(rbenv init -)"
fi

# This loads rust, if available.
if [[ -f "$HOME/.cargo/env" ]]; then
	source "$HOME/.cargo/env"
fi

[ ! -f ~/.bashrc_local ] || . ~/.bashrc_local
