{% import 'aws/common.sls' as vpc with context %}

{% set ec2_info = salt['cloud.get_instance'](name=vpc.aws_data['ec2']['name']) %}
{% if not ec2_info %}
  {% set ec2_info = {
    'privateIpAddress': '127.0.0.1',
    'ipAddress': '127.0.0.1',
  } %}
{% endif %}

r53:
  boto3_route53.rr_present:
    - profile: {{ vpc.aws_data['profile'] }}
    - TTL: 60
    - names:
      - {{ vpc.aws_data['ec2']['name'] }}.{{ vpc.aws_data['priv-r53']['domain'] }}:
        - Name: {{ vpc.aws_data['ec2']['name'] }}.{{ vpc.aws_data['priv-r53']['domain'] }}
        - ResourceRecords:
          - {{ ec2_info['privateIpAddress'] }}
        - DomainName: {{ vpc.aws_data['priv-r53']['domain'] }}
        - Type: A
        - PrivateZone: true
      - {{ vpc.aws_data['ec2']['name'] }}.{{ vpc.aws_data['pub-r53']['domain'] }}:
        - Name: {{ vpc.aws_data['ec2']['name'] }}.{{ vpc.aws_data['pub-r53']['domain'] }}
        - ResourceRecords:
          - {{ ec2_info['ipAddress'] }}
        - DomainName: {{ vpc.aws_data['pub-r53']['domain'] }}
        - Type: A
