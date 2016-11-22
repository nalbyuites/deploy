#!/bin/bash -x

# Extract values to be substituted into config
APP=`grep APP /tmp/env | cut -d'=' -f2`
VARNISH_LISTEN_PORT=`grep VARNISH_LISTEN_PORT /tmp/env | cut -d'=' -f2`
VARNISH_DEFAULT_BACKEND_HOST=`grep VARNISH_DEFAULT_BACKEND_HOST /tmp/env | cut -d'=' -f2`
VARNISH_DEFAULT_BACKEND_PORT=`grep VARNISH_DEFAULT_BACKEND_PORT /tmp/env | cut -d'=' -f2`
VARNISH_DEFAULT_BACKEND_DOMAINS=`grep VARNISH_DEFAULT_BACKEND_DOMAINS /tmp/env | cut -d'=' -f2 | sed 's/,/ /g'`

# Export some variables so that ansible commands work and install relevant the service
export HOME=/root/
export ANSIBLE_REMOTE_TMP=$HOME/.ansible/tmp
ansible-galaxy install -r /root/scripts/$APP/"$APP"_requirements.yml

# Set the hosts file entry for domains served by the default backend
sed -i "/example/d" /etc/hosts
echo "$VARNISH_DEFAULT_BACKEND_HOST $VARNISH_DEFAULT_BACKEND_DOMAINS" >> /etc/hosts
# Set the defaults in playbook
sed -i "/varnish_listen_port/d" /etc/ansible/roles/$APP/defaults/main.yml
sed -i "/varnish_default_backend_host/d" /etc/ansible/roles/$APP/defaults/main.yml
sed -i "/varnish_default_backend_port/d" /etc/ansible/roles/$APP/defaults/main.yml
echo "varnish_listen_port: '$VARNISH_LISTEN_PORT'" >> /etc/ansible/roles/$APP/defaults/main.yml
echo "varnish_default_backend_host: '$VARNISH_DEFAULT_BACKEND_HOST'" >> /etc/ansible/roles/$APP/defaults/main.yml
echo "varnish_default_backend_port: '$VARNISH_DEFAULT_BACKEND_PORT'" >> /etc/ansible/roles/$APP/defaults/main.yml

# Install varnish the first time and only configure varnish thereafter.
if ! type "varnishd" > /dev/null; then

    ansible-playbook /root/scripts/$APP/"$APP"_playbook.yml --tags "varnish-configure,varnish-service"

    if ping -W1 -c1 8.8.8.8 >/dev/null; then
        # Notify folks
        /root/scripts/$APP/inform.sh 2>/dev/null
	else
        touch /usr/local/share/no-notification-email-sent
    fi

    # Clean up
    ansible-galaxy remove $APP

else

    ansible-playbook /root/scripts/$APP/"$APP"_playbook.yml

fi
