#!/bin/bash -x

DATE=`date +%d-%m-%Y`
SECRET_FILE="/etc/varnish/agent_secret"
MAIL_BODY="/etc/varnish/mail_body"
IP=`ip route show | grep eth0 | grep src | awk '{print $9}'`
VA_URL="http://$IP:6085/html/"
VA_USER=`cut -d: -f1 $SECRET_FILE`
VA_PASS=`cut -d: -f2 $SECRET_FILE`
TO_USER=`grep TO_USER /tmp/env | cut -d= -f2`
G_USER=`grep G_USER /tmp/env | cut -d= -f2`
G_PASS=`grep G_PASS /tmp/env | cut -d= -f2`
SSH_NONROOT_USER="e2e-user"
SSH_NONROOT_PASS="$VA_PASS"

rm -f $MAIL_BODY
touch $MAIL_BODY; chmod 600 $MAIL_BODY

echo "Your new Varnish Appliance is now ready!" >> $MAIL_BODY
echo "" >> $MAIL_BODY
echo "Varnish Dashboard Credentials" >> $MAIL_BODY
echo "=============================" >> $MAIL_BODY
echo "URL: $VA_URL" >> $MAIL_BODY
echo "Username: $VA_USER" >> $MAIL_BODY
echo "Password: $VA_PASS" >> $MAIL_BODY
echo "" >> $MAIL_BODY
echo "Varnish Appliance SSH Credentials" >> $MAIL_BODY
echo "=================================" >> $MAIL_BODY
echo "SSH Host: $IP" >> $MAIL_BODY
echo "SSH Username: $SSH_NONROOT_USER" >> $MAIL_BODY
echo "SSH Password: $SSH_NONROOT_PASS" >> $MAIL_BODY
echo "" >> $MAIL_BODY

rm -rf ~/.certs
mkdir ~/.certs
certutil -f $SECRET_FILE -N -d ~/.certs
echo -n | openssl s_client -connect smtp.gmail.com:465 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ~/.certs/gmail.crt
certutil -A -n "Google Internet Authority" -t "C,," -d ~/.certs -i ~/.certs/gmail.crt

sleep 15 && mailx -s "Varnish Appliance - $IP - $DATE" \
        -S smtp-use-starttls \
        -S ssl-verify=ignore \
        -S smtp-auth=login \
        -S smtp=smtp://smtp.gmail.com:587 \
        -S from=$G_USER \
        -S smtp-auth-user=$G_USER \
        -S smtp-auth-password="$G_PASS" \
        -S ssl-verify=ignore \
        -S nss-config-dir=~/.certs \
        $TO_USER < $MAIL_BODY &
