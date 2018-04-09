{% import 'aws/common.sls' as vpc with context %}

sns:
  boto_sns.present:
    - profile: {{ vpc.aws_data['profile'] }}
    - names:
      - {{ vpc.aws_data['pub-asg']['sns'] }}:
        - subscriptions:
          - protocol: sqs
            endpoint: '{{ salt['boto_sqs.get_attributes'](vpc.aws_data['pub-asg']['sqs'], profile=salt['config.get'](vpc.aws_data['profile']))['QueueArn']  }}'
      - {{ vpc.aws_data['priv-asg']['sns'] }}:
        - subscriptions:
          - protocol: sqs
            endpoint: '{{ salt['boto_sqs.get_attributes'](vpc.aws_data['priv-asg']['sqs'], profile=salt['config.get'](vpc.aws_data['profile']))['QueueArn']  }}'
