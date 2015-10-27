#!/bin/bash

echo "[info] Configuring easy-rsa..."
mkdir -p /config/easy-rsa
mkdir -p /data/keys
chmod u=rwx,go=x /data/keys
if ! [ -f /config/easy-rsa/vars ]; then
	cp -f /easy-rsa/vars /config/easy-rsa/vars
	echo "edit /config/easy-rsa/vars to set easyrsa settings"
fi

if ! [ -d /config/easy-rsa/x509-types ]; then
	mkdir -p /config/easy-rsa/x509-types/
	cp /easy-rsa/x509-types/* /config/easy-rsa/x509-types
fi
(
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
	source /easy-rsa/vars
	mkdir -p $EASYRSA_PKI
	chown root: $EASYRSA_PKI
	chmod u=rwx,go=x $EASYRSA_PKI
	chown root: $EASYRSA_PKI/* 2>/dev/null
	chmod u=rwx,go=x $EASYRSA_PKI/* 2>/dev/null
	[ -d $EASYRSA_PKI/private ] && chmod u=rwx,go= $EASYRSA_PKI/private
	if [ -f $EASYRSA_PKI/ca.crt ]; then
		chmod +r $EASYRSA_PKI/ca.crt
		ln -sf $EASYRSA_PKI/ca.crt /usr/share/nginx/html/ca.crt
	fi
	if [ -f $EASYRSA_PKI/private/ca.key ]; then
		chmod u=rw,go= $EASYRSA_PKI/private/ca.key
		chown root:root $EASYRSA_PKI/private/ca.key
	fi
	if [ -f $EASYRSA_PKI/crl.pem ]; then
		chmod u=rw,go=r $EASYRSA_PKI/crl.pem
		ln -sf $EASYRSA_PKI/crl.pem /usr/share/nginx/html/crl.pem
	fi
	ln -sf $EASYRSA_PKI/issued /usr/share/nginx/html/
)
echo "[info] easy-rsa configuration done"

echo "[info] Configuring OpenSSH sever..."
mkdir -p /config/sshd
mkdir -p /root/.ssh
chmod 700 /root/.ssh

if [[ -f "/config/sshd/authorized_keys" ]]; then
        cp -R /config/sshd/authorized_keys /root/.ssh/ && chmod 600 /root/.ssh/*
fi

LAN_IP=$(hostname -i)
#sed -i -e "s/#ListenAddress.*/ListenAddress $LAN_IP/g" /etc/ssh/sshd_config
sed -i -e "s/#Port 22/Port 2222/g" /etc/ssh/sshd_config
sed -i -e "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
sed -i -e "s/#PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i -e "s/#PermitEmptyPasswords.*/PermitEmptyPasswords yes/g" /etc/ssh/sshd_config
sed -i -e "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config

echo "[info] OpenSSH server configuration done"

exec "$@"
