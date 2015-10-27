#!/bin/bash

# exit script if return code != 0
set -e

if ! [ -f /easy-rsa/vars ]; then
	cp /easy-rsa/vars.example /easy-rsa/vars
	sed -i -r 's|#*set_var EASYRSA\s+"\$PWD"|set_var EASYRSA "/easy-rsa"|' /easy-rsa/vars
	sed -i -r 's|#*set_var EASYRSA_PKI\s+"\$EASYRSA/pki"|set_var EASYRSA_PKI "/data/keys"|' /easy-rsa/vars
	sed -i -r 's|#*set_var EASYRSA_DN\s+"cn_only"|set_var EASYRSA_DN "org"|' /easy-rsa/vars
	sed -i -r 's|#*set_var EASYRSA_CA_EXPIRE\s+3650|set_var EASYRSA_CA_EXPIRE 7300|' /easy-rsa/vars
	sed -i -r 's|#*set_var EASYRSA_CERT_EXPIRE\s+3650|set_var EASYRSA_CERT_EXPIRE 365|' /easy-rsa/vars
fi

# remove unix socket from supervisord
mv /etc/supervisor.conf /etc/supervisor.conf.prev1
awk -F "=" -- '/\[unix_http_server\]/ { f=1; next }; /^\[/ { f=0; }; f==1 { next; }; { print; }' /etc/supervisor.conf.prev1 > /etc/supervisor.conf.prev2
awk -F "=" -- '/\[supervisorctl\]/ { f=1; next }; /^\[/ { f=0; }; f==1 { next; }; { print; }' /etc/supervisor.conf.prev2 > /etc/supervisor.conf.prev3
awk -F "=" -- '/\[supervisord]/ { f=1; print; next; }; f==1 && /^\[/ { print "[inet_http_server]\nport = 127.0.0.1:9001\n\n[supervisorctl]\nserverurl = http://localhost:9001\n"; f=0; }; { print; }' /etc/supervisor.conf.prev3 > /etc/supervisor.conf
rm -f /etc/supervisor.conf.prev*

#https://github.com/OpenVPN/easy-rsa/releases/download/3.0.1/EasyRSA-3.0.1.tgz
