#!/bin/sh
# vim: ts=2 sw=2 noet:

SCRIPT=$(basename "$0")

usage() {
	cat <<EOM
Usage: $SCRIPT <options>

Options:
  --help, -h                   show this usage statement
  --error-function, -e ERROR   sets the name of the function called when there
                               are errors parsing options (default "die")
  --parser-name, -p PARSER     sets the name for the parser function (default
                               "parseopts")
  --option-sentinal, -s        enable the option termination sentinal ("--")
                               (default)
  --no-option-sentinal, -S     disable the option termination sentinal ("--")

This program prints a POSIX shell compatible function definition that processes
command line options.  The output may either be saved into a script or
immediately eval'd.  The resulting function may then be called with all of the
arguments that should be processed.

Each option is associated with a shell function that will be called when a given
option is encountered.  If the option requires an argument and an argument is
provided, the argument is passed to the shell function when called; otherwise,
the function is called without an argument.

Argument processing stops at the first non-option or when the option sentinal
("--") is encountered.  The OPTSHIFT variable will be set to the number of
arguments consumed upon return from the function.  The remaining arguments may
be passed in a subsequent call to the function if desired for additional
processing, such as when options and positional arguments may be intermixed on
the command line.

The error function is called when an option cannot be processed, such as for an
unknown option or when there is a missing argument for an option that requires
one.  The error function receives a description of the problem as its argument
and is expected to exit the script rather than return to the caller.

OPTION SPECIFICATION

Option specifications are provided via stdin.  They are 1 per line with colon
separated fields.  Empty lines are ignored.  In order, the fields are the long
option name, the short option name, the number of option arguments, and a shell
function name.

At least one of the long or short option name is required.  The number of option
arguments field defaults to 0 if empty and may be set to 0 or 1.  Other values
raise errors.  The shell function name must be a valid POSIX shell function
name.

OPTION SPECIFICATION EXAMPLE

$SCRIPT <<OPTS
long-option:l::do_long_option
longer-option::1:do_longer_option
:s:0:do_short_option
OPTS

1) Handle --long-option and -l without arguments and call do_long_option.
2) Handle --longer-option (no short option equivalent), require an argument, and
   call do_longer_option with the provided argument.
3) Handle -s (no long option equivalent) explicitly without arguments and call
   do_short_option.

PARSER USAGE EXAMPLE

#!/bin/sh

die() {
	echo "Error: \$1" >&2
	exit 1
}

# The generated parseopts function...
parseopts() {
	... 
}

parseopts "\$@"
shift \$OPTSHIFT
if [ "\$1" = -- ]; then
	shift
fi
if [ \$# -gt 0 ]; then
	echo 'The remaining arguments are:' "\$@"
else
	echo 'There are no more arguments'
fi

OPTION HANDLING

A long option that takes an argument may have it provided either as the next
argument or as part of the option itself following an equal sign: e.g.
--long-option argument OR --long-option=argument.

A short option that takes an argument may have it provided either as the next
argument or as part of the option itself immediately concatinated to the option:
e.g. -s argument OR -sargument.

Short options may NOT be combined, even if none of them require arguments.  In
other words, the argument -abc will be treated as the -a option with an argument
of bc.  If the -a option doesn't take an argument, the error function will be
called.
EOM
	exit
}

die() {
	echo "$SCRIPT: $1" >&2
	exit 1
}

is_valid_function_name() {
	echo "$1" | grep -q '^[_[:alpha:]][_[:alnum:]]*$' || return 1
	case "$1" in
		if|fi|then|else|elif) return 1;;
		case|in|'esac') return 1;;
		for|when|until|do|done|break|continue) return 1;;
		time|coproc|select|function) return 1;;
	esac
}

is_valid_long_option_name() {
	echo "$1" | grep -q '^[_[:alnum:]][-_[:alnum:]]*$'
}

is_valid_short_option_name() {
	echo "$1" | grep -q '^[_[:alnum:]]$'
}

set_error_function() {
	is_valid_function_name "$1" || die "invalid error function name: $1"
	ERROR_FUNCTION=$1
}

set_parser_name() {
	is_valid_function_name "$1" || die "invalid parser name: $1"
	PARSER=$1
}

enable_option_sentinal() {
	OPTION_SENTINAL=true
}

disable_option_sentinal() {
	OPTION_SENTINAL=false
}

validate_option_configuration() {
	[ -z "$OPTLONG" -a -z "$OPTSHORT" ] &&
		die "line $OPTLINENO: long and short option names are empty"
	[ -z "$OPTLONG" ] || is_valid_long_option_name "$OPTLONG" ||
		die "line $OPTLINENO: invalid long option name: $OPTLONG"
	[ -z "$OPTSHORT" ] || is_valid_short_option_name "$OPTSHORT" ||
		die "line $OPTLINENO: invalid short option name: $OPTSHORT"
	[ -z "$OPTFUNCTION" ] &&
		die "line $OPTLINENO: function name is empty"
	is_valid_function_name "$OPTFUNCTION" ||
		die "line $OPTLINENO: invalid function name: $OPTFUNCTION"

	case "$OPTNEEDSARG" in
		0|1|'') ;;
		*) die "line $OPTLINENO: invalid argument flag: $OPTNEEDSARG";;
	esac
}

print_parser_header() {
	cat <<PARSER_HEADER
${PARSER}() {
	OPTSHIFT=0
	while [ \$# -gt 0 ]; do
		case "\$1" in
PARSER_HEADER
}

print_parser_footer() {
	cat <<PARSER_FOOTER
			--*)
				'$ERROR_FUNCTION' "unknown option: \${1%%=*}"
				;;
			-*)
				'$ERROR_FUNCTION' "unknown option: \$(printf '%.2s' "\$1")"
				;;
			*)
				break
				;;
		esac
	done
}
PARSER_FOOTER
}

print_no_arg_case() {
	if [ -n "$OPTLONG" ]; then
		cat <<NO_ARG_LONG_CASE
			--'$OPTLONG')
				'$OPTFUNCTION' ||
					'$ERROR_FUNCTION' "error handling --$OPTLONG"
				OPTSHIFT=\$((\$OPTSHIFT + 1)); shift
				;;
			--'$OPTLONG'=*)
				'$ERROR_FUNCTION' "--$OPTLONG does not take an argument"
				;;
NO_ARG_LONG_CASE
	fi

	if [ -n "$OPTSHORT" ]; then
		cat <<NO_ARG_SHORT_CASE
			-'$OPTSHORT')
				'$OPTFUNCTION' ||
					'$ERROR_FUNCTION' "error handling -$OPTSHORT"
				OPTSHIFT=\$((\$OPTSHIFT + 1)); shift
				;;
			-'$OPTSHORT'?*)
				'$ERROR_FUNCTION' "-$OPTSHORT does not take an argument"
				;;
NO_ARG_SHORT_CASE
	fi
}

print_require_arg_case() {
	if [ -n "$OPTLONG" ]; then
		cat <<REQUIRE_ARG_LONG_CASE
			--'$OPTLONG')
				[ \$# -gt 1 ] || '$ERROR_FUNCTION' "\$1 requires an argument"
				'$OPTFUNCTION' "\$2" ||
					'$ERROR_FUNCTION' "error handling --$OPTLONG"
				OPTSHIFT=\$((\$OPTSHIFT + 2)); shift 2
				;;
			--'$OPTLONG'=*)
				'$OPTFUNCTION' "\${1#--*=}" ||
					'$ERROR_FUNCTION' "error handling --$OPTLONG"
				OPTSHIFT=\$((\$OPTSHIFT + 1)); shift
				;;
REQUIRE_ARG_LONG_CASE
	fi

	if [ -n "$OPTSHORT" ]; then
		cat <<REQUIRE_ARG_SHORT_CASE
			-'$OPTSHORT')
				[ \$# -gt 1 ] || '$ERROR_FUNCTION' "\$1 requires an argument"
				'$OPTFUNCTION' "\$2" ||
					'$ERROR_FUNCTION' "error handling -$OPTSHORT"
				OPTSHIFT=\$((\$OPTSHIFT + 2)); shift 2
				;;
			-'$OPTSHORT'?*)
				'$OPTFUNCTION' "\${1#-[^-]}" ||
					'$ERROR_FUNCTION' "error handling -$OPTSHORT"
				OPTSHIFT=\$((\$OPTSHIFT + 1)); shift
				;;
REQUIRE_ARG_SHORT_CASE
	fi
}

print_option_cases() {
	case "$OPTNEEDSARG" in
		0|'') print_no_arg_case;;
		1) print_require_arg_case;;
	esac
}

print_option_sentinal_case() {
	cat <<OPTION_SENTINAL
			--)
				break
				;;
			--=*)
				'$ERROR_FUNCTION' '-- does not take an argument'
				;;
OPTION_SENTINAL
}

for_each_option() {
	OPTLINENO=-1
	echo "$OPTCONFIG" |
	while read LINE; do
		OPTLINENO=$(($OPTLINENO + 1))
		[ -z "$LINE" ] && continue
		IFS=: read OPTLONG OPTSHORT OPTNEEDSARG OPTFUNCTION <<LINE
$LINE
LINE

		"$@" || return $?
	done
}

generate_optparser() {
	OPTCONFIG=$(cat)
	for_each_option validate_option_configuration || exit $?

	print_parser_header
	for_each_option print_option_cases
	[ "$OPTION_SENTINAL" = true ] && print_option_sentinal_case
	print_parser_footer
}



# These are the parser generator settings for the generator program itself.
set_error_function die
set_parser_name parseopts
disable_option_sentinal

# Generate the option parser for this program.
eval "$(
	generate_optparser <<'OPTIONS'
help:h::usage
error-function:e:1:set_error_function
parser-name:p:1:set_parser_name
option-sentinal:s::enable_option_sentinal
no-option-sentinal:S::disable_option_sentinal
OPTIONS
)"


# These are the default parser generator settings for users of this program
# which may be overridden via options passed to this program.
set_error_function die
set_parser_name parseopts
enable_option_sentinal

parseopts "$@"
shift $OPTSHIFT
[ $# -gt 0 ] && die 'too many arguments given'

generate_optparser
