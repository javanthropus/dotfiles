[ -f ~/.bashrc ] && source ~/.bashrc

type -p keychain >/dev/null && eval $(keychain --eval --agents ssh id_rsa)
