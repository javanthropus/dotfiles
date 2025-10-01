# vim: ts=2 sw=2 noet ft=zsh:

#####
# Source this file into your shell.  It will add several functions to your
# environment and start a new kubeconfig "session".  This session allows you to
# safely manage independent configurations between shell instances without
# interference between the sessions in other shell instances.
#
# A session is implemented by creating a kubeconfig file that is only used for
# defining context details and placing it first in the list of kubeconfig files
# used by tools such as kubectl and other that utilize the kube-client library
# for golang and equivalents.  Your existing KUBECONFIG environment variable is
# used as the base of the list.  If the KUBECONFIG environment is not set or
# empty, `~/.kube/config` is used by default as the base.
#
# A session includes a context named "session" which will supercede any other
# similarly named session, so avoid that name in your own kubeconfig files.  The
# "session" context is selected as the current context by default.
#
# Helper functions such as kc, ku, kcl, and kns allow you to manipulate the
# user, cluster, and/or namespace associated with the current context.  See
# their individual function documentation for more information.
#
# The kcnf function allows you to include an additional kubeconfig file to the
# end of the list of kubeconfig list.  Giving it an argument of "example" will
# cause the `~/.kube/example.yaml` file to be added.  Calling it again with a
# different argument will replace the appended file in the list.  Calling it
# without an argument will remove the appended file from the list if there is
# one.
#
# The kco function allows you to change the current context; however, this is
# not recommended since it may allow for collisions between different shell
# instances due to operating on shared contexts.  Only use this if you truly
# know what you are doing.
#
# The kube_info function prints a summary of the current context configuration
# that can be useful for command prompts to help track the context.  The
# kube_session function toggles the session on and off.
#####

##
# Prints the currently selected k8s user, cluster, and namespace given a
# template string or as \n[user@cluster:namespace] without.
#
# This is useful for building command line prompts.  The following placeholders
# are replaced in the template string if provided:
#
# * %user%
#   * The user selected for the current context
#   * "(none)" if no user is selected
# * %cluster%
#   * The cluster selected for the current context
#   * "localhost" if no cluster is selected
# * %namespace%
#   * The namespace selected for the current namespace
#   * "default" if no namespace is selected
#
# After substitution of the above strings, the printf builtin is used to print
# the result, so special character sequences such as "\n" work as expected.
function kube_info {
	local TEMPLATE='\n[%user%@%cluster%:%namespace%]'
	[ -n "$1" ] && TEMPLATE=$1

	local KUBE_INFO='
{{- $userName := "(none)" }}
{{- $clusterName := "localhost" }}
{{- $namespaceName := "default" }}
{{- range .contexts }}
  {{- if eq .name (index $ "current-context") }}
    {{- if .context.user }}
      {{- $userName = .context.user }}
    {{- end }}
    {{- if .context.cluster }}
      {{- $clusterName = .context.cluster }}
    {{- end }}
    {{- if .context.namespace }}
      {{- $namespaceName = .context.namespace }}
    {{- end }}
    {{- break }}
  {{- end }}
{{- end -}}
{{ $userName }} {{ $clusterName }} {{ $namespaceName }}'

	local USER CLUSTER NAMESPACE
	local kube_output=$(kubectl config view -o go-template="$KUBE_INFO" 2>/dev/null)
	read -r USER CLUSTER NAMESPACE <<< "$kube_output"

	local RESULT
	RESULT="${TEMPLATE/\%user\%/$USER}"
	RESULT="${RESULT/\%cluster\%/$CLUSTER}"
	RESULT="${RESULT/\%namespace\%/$NAMESPACE}"
	printf "$RESULT"
}


##
# Sets the user, cluster, and/or namespace for the current context using the
# format user@cluster:namespace.
#
# Components are optional and can be omitted. Cluster names must start with @,
# and namespace names must start with :.
#
# Examples:
#
# kc user
# kc @cluster
# kc :namespace
# kc user@cluster
# kc @cluster:namespace
# kc user:namespace
# kc user@cluster:namespace
function kc {
	if [ -z "$1" ]; then
		echo 'kc: argument not provided' >&2
		return 1
	fi

	local arg="$1"
	local namespace
	local cluster
	local user
	local config_args=()

	# Parse user@cluster:namespace format
	[[ "$arg" == *":"* ]] && namespace="${arg#*:}"
	arg="${arg%%:*}"
	[[ "$arg" == *"@"* ]] && cluster="${arg#*@}"
	user="${arg%%@*}"

	# Set configuration arguments for kubectl
	if [[ -n "$namespace" ]]; then
		config_args+=(--namespace "$namespace")
	fi
	if [[ -n "$cluster" ]]; then
		config_args+=(--cluster "$cluster")
	fi
	if [[ -n "$user" ]]; then
		config_args+=(--user "$user")
	fi

	# Set the context configuration
	kubectl config set-context --current "${config_args[@]}"
}

function _kube_kc_completion {
	local -a completions
	local cur="${words[CURRENT]}"

	# Determine what component we're completing based on the current word
	if [[ "$cur" == *":"* ]]; then
		# Completing namespace component
		local prefix="${cur%:*}"
		local ns_part="${cur##*:}"
		local cluster
		local user
		local kubectl_opts=()

		# Parse user@cluster:namespace format
		local parse_word="${cur%%:*}"
		[[ "$parse_word" == *"@"* ]] && cluster="${parse_word#*@}"
		user="${parse_word%%@*}"

		# Set configuration arguments for kubectl
		if [[ -n "$cluster" ]]; then
			kubectl_opts+=(--cluster "$cluster")
		fi
		if [[ -n "$user" ]]; then
			kubectl_opts+=(--user "$user")
		fi
		completions=(${(f)"$(kubectl "${kubectl_opts[@]}" get ns --no-headers -o custom-columns=NAME:.metadata.name)"})
		compadd -p "${prefix}:" - "${completions[@]}"
	elif [[ "$cur" == *"@"* ]]; then
		# Completing cluster component (has @ but no :)
		local prefix="${cur%@*}"
		local cluster_part="${cur##*@}"
		completions=(${(f)"$(kubectl config view -o jsonpath='{.clusters[*].name}' | tr ' ' '\n')"})
		compadd -p "${prefix}@" - "${completions[@]}"
	else
		# Completing user component (no @ or : yet, or empty/partial user)
		completions=(${(f)"$(kubectl config view -o jsonpath='{.users[*].name}' | tr ' ' '\n')"})
		compadd - "${completions[@]}"
	fi
}
compdef _kube_kc_completion kc


##
# Sets the name of the current context to use.
function kco {
	if [ -z "$1" ]; then
		echo 'kco: context not provided' >&2
		return 1
	fi

	kubectl config use-context "$1"
}

function _kube_kco_completion {
	local -a completions
	completions=(${(f)"$(kubectl config get-contexts --no-headers -o name)"})
	compadd - "${completions[@]}"
}
compdef _kube_kco_completion kco


##
# Sets the name of the cluster to use in the currently selected context.
function kcl {
	if [ -z "$1" ]; then
		echo 'kcl: cluster not provided' >&2
		return 1
	fi

	kubectl config set-context --current --cluster "$1"
}

function _kube_kcl_completion {
	local -a completions
	completions=(${(f)"$(kubectl config get-clusters | tail -n +2)"})
	compadd - "${completions[@]}"
}
compdef _kube_kcl_completion kcl


##
# Sets the name of the namespace to use in the currently selected context.
function kns {
	if [ -z "$1" ]; then
		echo 'kns: namespace not provided' >&2
		return 1
	fi

	kubectl config set-context --current --namespace "$1"
}

function _kube_kns_completion {
	local -a completions
	completions=(${(f)"$(kubectl get ns --no-headers -o custom-columns=NAME:.metadata.name)"})
	compadd - "${completions[@]}"
}
compdef _kube_kns_completion kns


##
# Sets the name of the user to use in the currently selected context.
function ku {
	if [ -z "$1" ]; then
		echo 'ku: user not provided' >&2
		return 1
	fi

	kubectl config set-context --current --user "$1"
}

function _kube_ku_completion {
	local -a completions
	completions=(${(f)"$(kubectl config get-users | tail -n +2)"})
	compadd - "${completions[@]}"
}
compdef _kube_ku_completion ku


##
# Manages the KUBECONFIG environment variable by apending the given config file
# to the end of the list.  If no argument is given, the default KUBECONFIG
# setting is reinstated.
function kcnf {
	KUBECONFIG=$(printf '%s:%s:%s' "$SESSION_KUBECONFIG" "${ORIG_KUBECONFIG:-$HOME/.kube/config}" "${1:+$HOME/.kube/$1.yaml}" | sed 's/:::*/:/g; s/^://; s/:$//')
	export KUBECONFIG
}

function _kube_kcnf_completion {
	local -a completions
	completions=(${(f)"$(cd $HOME/.kube && ls *.yaml | sed 's|\.yaml$||')"})
	compadd - "${completions[@]}"
}
compdef _kube_kcnf_completion kcnf

##
# Records the current setting of the KUBECONFIG environment variable.
function _kube_kcnf_save {
	ORIG_KUBECONFIG=$KUBECONFIG
	ORIG_KUBECONFIG_SET=1
}

##
# Reinstates the original setting of the KUBECONFIG environment variable.
function _kube_kcnf_restore {
	[ -z "$ORIG_KUBECONFIG_SET" ] || KUBECONFIG=$ORIG_KUBECONFIG
	unset ORIG_KUBECONFIG_SET ORIG_KUBECONFIG
}

##
# Initializes a new kubeconfig session by creating a temporary file to hold
# session specific settings for context and prepending that file to the
# KUBECONFIG environnment variable value.
function _kube_session_init {
	if ! kube_session_is_active; then
		trap 'kube_session_is_active && rm -f "$SESSION_KUBECONFIG"' EXIT
		SESSION_KUBECONFIG=$(mktemp -t kube-session.XXXXXXXXXX)
	fi

	# Initialize the session config from its template file if available.
	[ -f ~/.kube/session_config ] &&
		cp ~/.kube/session_config "$SESSION_KUBECONFIG"

	# Initialize the KUBECONFIG environment variable to include the session
	# config file.
	_kube_kcnf_save
	kcnf

	if ! kubectl --kubeconfig "$SESSION_KUBECONFIG" config current-context >/dev/null 2>&1; then
		# Ensure that a context named "session" exists and use it.
		kubectl --kubeconfig "$SESSION_KUBECONFIG" config set-context session
		kubectl --kubeconfig "$SESSION_KUBECONFIG" config use-context session
	fi
}

##
# Deactivates the kubeconfig session if active.
function _kube_session_exit {
	kube_session_is_active || return

	rm -f "$SESSION_KUBECONFIG"
	unset SESSION_KUBECONFIG
	_kube_kcnf_restore
}

##
# Exits successfully if the kubeconfig session is active.
function kube_session_is_active {
	[ -n "$SESSION_KUBECONFIG" ]
}

##
# Toggles the active status of the kubeconfig session.
function kube_session {
  if kube_session_is_active; then
    _kube_session_exit
  else
    _kube_session_init
  fi
}

# Activate a new session.
kube_session
