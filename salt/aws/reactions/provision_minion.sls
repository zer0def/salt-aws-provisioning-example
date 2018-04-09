{% set sqs_event = pillar['my_event']['data'].get('message', {'Message': '{}'})['Message']|load_json %}

{% set private_ip = {} %}
{% for i in salt['boto_asg.get_instances'](sqs_event['AutoScalingGroupName'], attributes=['id', 'private_ip_address'], profile=salt['config.get']('awsprofile')) %}
  {% if i[0] == sqs_event['EC2InstanceId'] %}
    {% do private_ip.update({
      i[0]: i[1]
    }) %}
  {% endif %}
{% endfor %}

provision_minion:
  cmd.run:
    - name: sleep 15
{% if sqs_event['EC2InstanceId'] in private_ip %}
  salt.wheel:
    - name: key.delete
    - match: minion-{{ sqs_event['EC2InstanceId'] }}
    - onfail:
      - cloud: provision_minion
  cloud.present:
    - name: minion-{{ sqs_event['EC2InstanceId'] }}
    - cloud_provider: saltify
    - ssh_host: {{ private_ip[sqs_event['EC2InstanceId']] }}
    - ssh_username: ec2-user
    - key_filename: /srv/salt/salt/aws/keys/id_rsa
    - script: amzn-upstream
    - minion:
        master:
          - {{ salt['network.ip_addrs']('eth0') }}
    - require:
      - cmd: provision_minion
    - onfail_in:
{% else %}
    - require_in:
{% endif %}
      - salt: provision_failure

provision_failure:
  salt.runner:
    - name: event.send
    - tag: {{ pillar['my_event']['tag'] }}
    - data: {{ pillar['my_event']['data'] }}
