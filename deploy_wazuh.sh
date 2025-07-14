#!/usr/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

apt-get -y update
apt-get -y install auditd

wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.11.2-1_amd64.deb -O wazuh-agent.deb

if [ ! -f wazuh-agent.deb ]; then
    echo "Failed to download wazuh-agent package" 1>&2
    exit 1
fi

dpkg -i wazuh-agent.deb

OSSEC_CONF="/var/ossec/etc/ossec.conf"
if [ -f $OSSEC_CONF ]; then
    cp $OSSEC_CONF "${OSSEC_CONF}.bak"
fi

WAZUH_MANAGER='wz.togethernetworks.com'
WAZUH_AGENT_GROUP='linux-endpoint,default'
WAZUH_MANAGER_PORT='7312'

sed -i "s/<address>MANAGER_IP<\/address>/<address>${WAZUH_MANAGER}<\/address>/g" $OSSEC_CONF
sed -i "s/<port>1514<\/port>/<port>${WAZUH_MANAGER_PORT}<\/port>/g" $OSSEC_CONF
sed -i '/<crypto_method>aes<\/crypto_method>/ {
a\
    <enrollment>\
      <enabled>yes</enabled>\
      <manager_address>wz.togethernetworks.com</manager_address>\
      <groups>linux-endpoint,default</groups>\
    </enrollment>
}' $OSSEC_CONF

systemctl daemon-reload
systemctl enable auditd
systemctl start auditd
systemctl enable wazuh-agent
systemctl start wazuh-agent

rm -f wazuh-agent.deb

echo ""
echo "---------------------------------------------------"
echo "Wazuh agent installation and configuration complete"
echo "---------------------------------------------------"
exit 0
