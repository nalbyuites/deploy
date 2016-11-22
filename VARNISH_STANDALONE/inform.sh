#!/bin/bash -x

DATE=`date +%d-%m-%Y`
APP=`grep APP /tmp/env | cut -d'=' -f2`
IP=`ip route show | grep eth0 | grep src | awk '{print $9}'`
PORT=`grep varnish_agent_listen_port /etc/ansible/roles/$APP/defaults/main.yml | awk '{print $2}' | tr -d "'"`
SECRET_FILE=`grep varnish_agent_secret_file /etc/ansible/roles/$APP/vars/RedHat.yml | awk '{print $2}' | tr -d "'"`
VA_URL="http://$IP:$PORT/html/"
VA_USER=`cut -d: -f1 $SECRET_FILE`
VA_PASS=`cut -d: -f2 $SECRET_FILE`
TO_USER=`grep TO_USER /tmp/env | cut -d= -f2`
G_USER=`grep G_USER /tmp/env | cut -d= -f2`
G_PASS=`grep G_PASS /tmp/env | cut -d= -f2`

function mail_body {
    echo "Varnish Dashboard Credentials"
    echo "============================="
    echo "URL: $VA_URL"
    echo "Username: $VA_USER"
    echo "Password: $VA_PASS"
}

rm -rf ~/.certs
mkdir ~/.certs
certutil -f $SECRET_FILE -N -d ~/.certs
echo -n | openssl s_client -connect smtp.gmail.com:465 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ~/.certs/gmail.crt
certutil -A -n "Google Internet Authority" -t "C,," -d ~/.certs -i ~/.certs/gmail.crt

mail_body | mailx -s "Varnish Dashboard Details - $IP - $DATE" \
        -S smtp-use-starttls \
        -S ssl-verify=ignore \
        -S smtp-auth=login \
        -S smtp=smtp://smtp.gmail.com:587 \
        -S from=$G_USER \
        -S smtp-auth-user=$G_USER \
        -S smtp-auth-password="$G_PASS" \
        -S ssl-verify=ignore \
        -S nss-config-dir=~/.certs \
        $TO_USER
