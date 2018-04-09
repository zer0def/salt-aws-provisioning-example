#!/bin/bash

rpm -i "https://repo.saltstack.com/yum/amazon/salt-amzn-repo-2017.7-1.amzn1.noarch.rpm" || true
yum clean expire-cache
yum -y install salt-minion

mkdir -p /etc/salt/pki
echo '{{ vm['priv_key'] }}' > /etc/salt/pki/minion.pem
echo '{{ vm['pub_key'] }}' > /etc/salt/pki/minion.pub
cat > /etc/salt/minion <<EOF
{{minion}}
EOF

/sbin/chkconfig salt-minion on
service salt-minion start
