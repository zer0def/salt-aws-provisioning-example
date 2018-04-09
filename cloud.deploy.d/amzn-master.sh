#!/bin/bash

rpm -i "https://repo.saltstack.com/yum/amazon/salt-amzn-repo-2017.7-1.amzn1.noarch.rpm" || true
yum clean expire-cache
yum -y install salt-master salt-minion salt-cloud python27-boto python27-boto3 git
git clone https://github.com/zer0def/salt-reactive-aws-in-15 /srv/salt
for i in cloud.conf.d cloud.deploy.d cloud.providers.d master.d; do rm -rf /etc/salt/${i} && ln -sf /srv/salt/${i} /etc/salt/${i}; done

/sbin/chkconfig salt-master on
service salt-master restart
echo "${@: -1}" | base64 -dw0 - | /bin/bash -s
