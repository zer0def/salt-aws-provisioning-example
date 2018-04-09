{% set sqs_event = data.get('message', {'Message':'{}'})['Message']|load_json %}

# this reactor ideally should have CloudWatch reaction logic calling `runner.cloud.create`
sqs:
{% if sqs_event.get('Event', '') == 'autoscaling:EC2_INSTANCE_LAUNCH' %}
  runner.state.orchestrate:
    - mods:
      - aws.reactions.provision_minion
    - pillar:
        my_event:
          tag: {{ tag }}
          data: {{ data|json }}
{% elif sqs_event.get('Event', '') == 'autoscaling:EC2_INSTANCE_TERMINATE' %}
  wheel.key.delete:
    - match: minion-{{ sqs_event['EC2InstanceId'] }}
{% endif %}
