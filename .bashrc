# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.

PATH=~/bin:/bin:$PATH

# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]]; then
        # Shell is non-interactive.  Be done now
        return
fi

# Shell is interactive.  It is okay to produce output at this point,
# though this example doesn't produce any.  Do setup for
# command-line interactivity.

function set_title {
	STR=$(echo "$1" | sed 's/\\/\\\\/g')
	PS1=$(echo "$PS1_BASE" | sed "s/%t/$STR/g")
}

function __safe_git_ps1 {
	type -t __git_ps1 >/dev/null && __git_ps1
}

case x$TERM in
	xscreen|xxterm*)
		PS1_BASE='\[\033]0;%t\u@\h:\w\007\n\033[32m\]\u@\h \[\033[33m\]\w\[\033[0m\]\[\033[31m\]$(__safe_git_ps1)\[\033[0m\]\n\$ '
		set_title
		;;
	xcygwin|xlinux)
		PS1_BASE='\n\033[32m\]%t\[\033[0m\]\[\033[31m\]$(__safe_git_ps1)\[\033[0m\]\n\$ '
		set_title '\u@\h \[\033[33m\]\w'
		;;
	*)
		PS1_BASE='\n\u@\h \w$(__safe_git_ps1)\n$ '
		set_title
		;;
esac

# Pick a nice pager for man.
if [ -x ~/bin/manpager.sh ]; then
	export MANPAGER=~/bin/manpager.sh
fi

# Beep...
alias beep="echo -ne \"\\007\""

# Set the editor for git.
export GIT_EDITOR='gvim -f'

# Directory and file coloring for ls
[ -e ~/.dircolors ] && DIRCOLORS=~/.dircolors
eval $(dircolors -b $DIRCOLORS)
alias ls='ls --color=auto'

# Activate bash-completion.
[ -f /etc/bash_completion ] && source /etc/bash_completion

# This loads rbenv, if available.
if [[ -x "$HOME/.rbenv/bin/rbenv" ]]; then
	PATH="$HOME/.rbenv/bin:$PATH"
	eval "$(rbenv init -)"
fi
