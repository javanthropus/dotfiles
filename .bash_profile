if type -p keychain >/dev/null; then
	keychain ~/.ssh/id_rsa
	. ~/.keychain/${HOSTNAME}-sh
fi

[ -f .bashrc ] && source .bashrc
