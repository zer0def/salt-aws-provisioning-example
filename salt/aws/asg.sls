{% import 'aws/common.sls' as vpc with context %}

asg:
  boto_ec2.key_present:
    - profile: {{ vpc.aws_data['profile'] }}
    - name: {{ vpc.aws_data['ec2']['key_name'] }}
    - upload_public: salt://aws/keys/id_rsa.pub
  boto_elb.present:
    - profile: {{ vpc.aws_data['profile'] }}
    - listeners:
      - elb_protocol: TCP
        elb_port: 22
        instance_port: 22
    - security_groups:
      - {{ vpc.aws_data['sg']['name'] }}
    - names:
      - {{ vpc.aws_data['pub-elb']['name'] }}:
        - subnet_names: {{ vpc.aws_data['pub-sub'].values()|map(attribute='name')|list }}
        - scheme: internet-facing
      - {{ vpc.aws_data['priv-elb']['name'] }}:
        - subnet_names: {{ vpc.aws_data['priv-sub'].values()|map(attribute='name')|list }}
        - scheme: internal
  boto_sqs.present:  # correct permissions
    - profile: {{ vpc.aws_data['profile'] }}
    - names:
      - {{ vpc.aws_data['pub-asg']['sqs'] }}:
        - attributes:
            Policy: '{"Version": "2012-10-17", "Id": "{{ salt['boto_sqs.get_attributes'](vpc.aws_data['pub-asg']['sqs'], profile=salt['config.get'](vpc.aws_data['profile']))['QueueArn'] }}/SQSDefaultPolicy","Statement": [{"Sid": "{{ vpc.aws_data['pub-asg']['sqs_policy_name'] }}","Effect": "Allow","Principal": "*","Action": "SQS:SendMessage","Resource":"{{ salt['boto_sqs.get_attributes'](vpc.aws_data['pub-asg']['sqs'], profile=salt['config.get'](vpc.aws_data['profile']))['QueueArn'] }}","Condition":{"ArnEquals":{"aws:SourceArn":"{{ salt['boto_sns.get_arn'](vpc.aws_data['pub-asg']['sns'], profile=salt['config.get'](vpc.aws_data['profile'])) }}"} } }]}'
      - {{ vpc.aws_data['priv-asg']['sqs'] }}:
        - attributes:
            Policy: '{"Version": "2012-10-17", "Id": "{{ salt['boto_sqs.get_attributes'](vpc.aws_data['priv-asg']['sqs'], profile=salt['config.get'](vpc.aws_data['profile']))['QueueArn'] }}/SQSDefaultPolicy","Statement": [{"Sid": "{{ vpc.aws_data['priv-asg']['sqs_policy_name'] }}","Effect": "Allow","Principal": "*","Action": "SQS:SendMessage","Resource":"{{ salt['boto_sqs.get_attributes'](vpc.aws_data['priv-asg']['sqs'], profile=salt['config.get'](vpc.aws_data['profile']))['QueueArn'] }}","Condition":{"ArnEquals":{"aws:SourceArn":"{{ salt['boto_sns.get_arn'](vpc.aws_data['priv-asg']['sns'], profile=salt['config.get'](vpc.aws_data['profile'])) }}"} } }]}'
  # there may be benefits to using `boto_lc` separately
  boto_asg.present:
    - profile: {{ vpc.aws_data['profile'] }}
    - min_size: 0
    - max_size: 2
    - desired_capacity: 1
    - notification_types:
      - 'autoscaling:EC2_INSTANCE_LAUNCH'
      - 'autoscaling:EC2_INSTANCE_LAUNCH_ERROR'
      - 'autoscaling:EC2_INSTANCE_TERMINATE'
      - 'autoscaling:EC2_INSTANCE_TERMINATE_ERROR'
    - require:
      - boto_ec2: asg
      - boto_elb: asg
      - boto_sqs: asg
    - names:
      - {{ vpc.aws_data['pub-asg']['name'] }}:
        - launch_config_name: {{ vpc.aws_data['pub-asg']['lc'] }}
        - load_balancers:
          - {{ vpc.aws_data['pub-elb']['name'] }}
        - availability_zones: {{ vpc.aws_data['pub-sub'].keys() }}
        - subnet_names: {{ vpc.aws_data['pub-sub'].values()|map(attribute='name')|list }}
        - notification_arn: '{{ salt['boto_sns.get_arn'](vpc.aws_data['pub-asg']['sns'], profile=salt['config.get'](vpc.aws_data['profile'])) }}'
        - launch_config:
          - instance_type: {{ vpc.aws_data['ec2']['instance_type'] }}
          - key_name: {{ vpc.aws_data['ec2']['key_name'] }}
          - image_id: {{ vpc.aws_data['ec2']['image'] }}
          - security_groups:
            - {{ vpc.aws_data['sg']['name'] }}
#          - user_data:
          - associate_public_ip_address: true
      - {{ vpc.aws_data['priv-asg']['name'] }}:
        - launch_config_name: {{ vpc.aws_data['priv-asg']['lc'] }}
        - load_balancers:
          - {{ vpc.aws_data['priv-elb']['name'] }}
        - availability_zones: {{ vpc.aws_data['priv-sub'].keys() }}
        - subnet_names: {{ vpc.aws_data['priv-sub'].values()|map(attribute='name')|list }}
        - notification_arn: '{{ salt['boto_sns.get_arn'](vpc.aws_data['priv-asg']['sns'], profile=salt['config.get'](vpc.aws_data['profile'])) }}'
        - launch_config:
          - instance_type: {{ vpc.aws_data['ec2']['instance_type'] }}
          - key_name: {{ vpc.aws_data['ec2']['key_name'] }}
          - image_id: {{ vpc.aws_data['ec2']['image'] }}
          - security_groups:
            - {{ vpc.aws_data['sg']['name'] }}
#          - user_data:
