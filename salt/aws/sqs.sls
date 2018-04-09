{% import 'aws/common.sls' as vpc with context %}

sqs:
  boto_sqs.present:
    - profile: {{ vpc.aws_data['profile'] }}
    - names: {{ vpc.aws_data.values()|selectattr('sqs', 'defined')|map(attribute='sqs')|list }}
