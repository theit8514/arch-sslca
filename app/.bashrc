# /etc/skel/.bashrc
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen !


# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
	# Shell is non-interactive.  Be done now!
	return
fi

# Put your fun stuff here.
# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
shopt -s checkwinsize

# Enable history appending instead of overwriting.  #139609
shopt -s histappend

# Change the window title of X terminals 
case ${TERM} in
        xterm*|rxvt*|Eterm*|aterm|kterm|gnome*|interix|konsole*)
                PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\007"'
                ;;
        screen*)
                PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\033\\"'
                ;;
esac

use_color=false

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
        && type -P dircolors >/dev/null \
        && match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
        # Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
        if type -P dircolors >/dev/null ; then
                if [[ -f ~/.dir_colors ]] ; then
                        eval $(dircolors -b ~/.dir_colors)
                elif [[ -f /etc/DIR_COLORS ]] ; then
                        eval $(dircolors -b /etc/DIR_COLORS)
                fi
        fi

        if [[ ${EUID} == 0 ]] ; then
                PS1='\[\033[01;31m\]\h\[\033[01;34m\] \W \$\[\033[00m\] '
        else
                PS1='\[\033[01;32m\]\u@\h\[\033[01;34m\] \w \$\[\033[00m\] '
        fi

        alias ls='ls --color=auto'
        alias grep='grep --colour=auto'
        alias egrep='egrep --colour=auto'
        alias fgrep='fgrep --colour=auto'
else
        if [[ ${EUID} == 0 ]] ; then
                # show root@ when we don't have colors
                PS1='\u@\h \W \$ '
        else
                PS1='\u@\h \w \$ '
        fi
fi

alias supervisorctl='supervisorctl -c /etc/supervisor.conf'
alias ll='ls -l'

[ -z "$EASYRSA_VARS_FILE" ] && export EASYRSA_VARS_FILE=/config/easy-rsa/vars
export EASYRSA_CALLER=start
function set_var() {
        export OLD_$1=${!1}
        export $1=$2
}
function unset_var() {
        old_var_name="OLD_$1"
        test -z "$old_var_name" && unset $1 || export $1=${!old_var_name}
        unset OLD_$1
}
tvf=$(mktemp)
grep "EASYRSA_PKI" $EASYRSA_VARS_FILE > $tvf
sed -i 's/EASYRSA_PKI/_EASYRSA_PKI/' $tvf
source $tvf
unset EASYRSA_CALLER
unset -f set_var
unset -f unset_var
rm -f $tvf
echo $_EASYRSA_PKI
if ! [ -f $_EASYRSA_PKI/ca.crt ]; then
        echo "No ca certificate found. Execute 'easyrsa build-ca' to build the certificate"
	echo "To ensure maximum security, use 'easyrsa build-ca --keysize 4096'"
fi

function easyrsa {
	args=("$@")
	while [ $# -ne 0 ]
	do
		arg="$1"
		case "$arg" in
		init-pki)
			echo "Initializing pki folder will erase data outside container!"
			;;
		esac
		shift
	done
	set -- "${args[@]}"
        /easy-rsa/easyrsa "$@"
	if [ -d $_EASYRSA_PKI/issued ]; then
		files=$(ls $_EASYRSA_PKI/issued/*.crt 2> /dev/null | wc -l)
		[ "$files" != "0" ] && chmod u=rw,go=r $_EASYRSA_PKI/issued/*.crt
	fi
	while [ $# -ne 0 ]
	do
		arg="$1"
		case "$arg" in
		init-pki)
			chown root: $_EASYRSA_PKI
			chmod u=rwx,go=x $_EASYRSA_PKI
			mkdir -p $_EASYRSA_PKI/issued
			chown root: $_EASYRSA_PKI/issued
			chmod u=rwx,go=x $_EASYRSA_PKI/issued
			;;
		build-ca)
			if [ -f $_EASYRSA_PKI/ca.crt ]; then
				chmod u=rw,go=r $_EASYRSA_PKI/ca.crt
				ln -sf $_EASYRSA_PKI/ca.crt /usr/share/nginx/html/ca.crt
			fi
			;;
		gen-crl)
			if [ -f $_EASYRSA_PKI/crl.pem ]; then
				chmod u=rw,go=r $_EASYRSA_PKI/crl.pem
				ln -sf $_EASYRSA_PKI/crl.pem /usr/share/nginx/html/ca.crl
			fi
			;;
		esac
		shift
	done
}

if ! [ -f /config/.sslca_first_run ]; then
	touch /config/.sslca_first_run
	cat <<'_EOF'
I see this is your first time running this container. (Or you haven't set your /config folder)
This container allows for managing certificates using easyrsa, and publishing ca certificate
and crl via nginx.

To begin your setup, please ensure that /data and /config are persisted volumes.
The script will write two config files to /config/easy-rsa:
 1. vars - script loaded by easyrsa script with default parameters for most settings
   * Do not change EASYRSA variable.
 2. x509-common - x509 settings which is applied to all certificates.
   * You should set this to your external URL for the container, ex:
     If the container is hosted on port 8080 (-p 8080:80), then
     crlDistributionPoints = URI:http://example.net:8080/ca.crl

After changing these config files, a restart of the container is required.
Once the proper settings are configured, you can begin your PKI environment.

'easyrsa init-pki' will create the necessary folder structure in your EASYRSA_PKI
  folder (default /data/keys)
'easyrsa build-ca' will create a certificate authority. A higher key strength
  is recommended by using the --keysize argument. e.g:
  'easyrsa --keysize=4096 build-ca'

At this point, you an access your ca certificate via the nginx server:
If the container is hosted on port 8080 (-p 80808:80), then
  http://example.net:8080/ca.crt

Signing certificates:
'easyrsa gen-req <name>' will generate a private key and certificate request file
'easyrsa sign-req server <name>' is used to create server certificates
  (with Digital Signature and Key Encipherment usages)
'easyrsa revoke <name>' will revoke a certificate
'easyrsa gen-crl' will generate the crl and ensure it exists on nginx.

Further documentation of the easyrsa script is available here:
https://community.openvpn.net/openvpn/wiki/EasyRSA3-OpenVPN-Howto
_EOF
fi

# Try to keep environment pollution down, EPA loves us.
unset use_color safe_term match_lhs
