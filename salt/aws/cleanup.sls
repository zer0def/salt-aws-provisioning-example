{% import 'aws/common.sls' as vpc with context %}

{#
{% for eip_info in salt['boto_ec2.get_eip_address_info'](
  addresses=salt['boto_ec2.get_all_eip_addresses'](
    profile=salt['config.get'](vpc.aws_data['profile'], {})
  ), profile=salt['config.get'](vpc.aws_data['profile'], {})
) %}
  {% do salt['boto_ec2.release_eip_address'](allocation_id=eip_info['allocation_id'], profile=salt['config.get'](vpc.aws_data['profile'], {})) %}
{% endfor %}
#}

ec2-or-asg:
  cloud.absent:
    - name: {{ vpc.aws_data['ec2']['name'] }}
  boto_asg.absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - remove_lc: true
    - force: true
    - names:
      - {{ vpc.aws_data['pub-asg']['name'] }}
      - {{ vpc.aws_data['priv-asg']['name'] }}
  boto_elb.absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - names:
      - {{ vpc.aws_data['pub-elb']['name'] }}
      - {{ vpc.aws_data['priv-elb']['name'] }}
    - require:
      - boto_asg: ec2-or-asg
  boto_ec2.key_absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - name: {{ vpc.aws_data['ec2']['key_name'] }}
    - require:
      - cloud: ec2-or-asg
      - boto_elb: ec2-or-asg
  boto_sns.absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - unsubscribe: true
    - names:
      - {{ vpc.aws_data['pub-asg']['sns'] }}
      - {{ vpc.aws_data['priv-asg']['sns'] }}
    - require:
      - boto_asg: ec2-or-asg
  boto_sqs.absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - names:
      - {{ vpc.aws_data['pub-asg']['sqs'] }}
      - {{ vpc.aws_data['priv-asg']['sqs'] }}
    - require:
      - boto_sns: ec2-or-asg
  boto3_route53.rr_absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - names:
      - {{ vpc.aws_data['ec2']['name'] }}.{{ vpc.aws_data['priv-r53']['domain'] }}:
        - Name: {{ vpc.aws_data['ec2']['name'] }}.{{ vpc.aws_data['priv-r53']['domain'] }}
        - DomainName: {{ vpc.aws_data['priv-r53']['domain'] }}
        - Type: A
        - PrivateZone: true
      - {{ vpc.aws_data['ec2']['name'] }}.{{ vpc.aws_data['pub-r53']['domain'] }}:
        - Name: {{ vpc.aws_data['ec2']['name'] }}.{{ vpc.aws_data['pub-r53']['domain'] }}
        - DomainName: {{ vpc.aws_data['pub-r53']['domain'] }}
        - Type: A
  boto_vpc.nat_gateway_absent:
    - profile: {{ vpc.aws_data['profile'] }}
    # formula for next attempt time is `now + (2^(wait_for_delete_retries-attempt_num) + random_ms)` seconds
    - wait_for_delete_retries: 6
    - names:
{% for subnet in vpc.aws_data['pub-sub'].values() %}
      - {{ subnet['name'] }}:
        - subnet_name: {{ subnet['name'] }}
{% endfor %}

secgroup:
  boto_secgroup.absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - name: {{ vpc.aws_data['sg']['name'] }}
    - vpc_name: {{ vpc.aws_data['vpc']['name'] }}
    - require:
      - boto_asg: ec2-or-asg
      - boto_elb: ec2-or-asg
      - boto_vpc: ec2-or-asg
      - cloud: ec2-or-asg

sub:
  boto_vpc.subnet_absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - names:
{% for subnet in vpc.aws_data['pub-sub'].values() %}
      - {{ subnet['name'] }}
{% endfor %}
{% for subnet in vpc.aws_data['priv-sub'].values() %}
      - {{ subnet['name'] }}
{% endfor %}
    - require:
      - boto_asg: ec2-or-asg
      - boto_elb: ec2-or-asg
      - boto_vpc: ec2-or-asg
      - cloud: ec2-or-asg

rtb:
  boto_vpc.route_table_absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - names:
{% for subnet_name in vpc.aws_data['pub-rtb'].values()|map(attribute='name')|list %}
      - {{ subnet_name }}
{% endfor %}
{% for subnet_name in vpc.aws_data['priv-rtb'].values()|map(attribute='name')|list %}
      - {{ subnet_name }}
{% endfor %}
    - require:
      - boto_vpc: sub

igw:
  boto_vpc.internet_gateway_absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - name: {{ vpc.aws_data['igw']['name'] }}
    - detach: true
    - require:
      - boto_vpc: sub
      - boto_vpc: ec2-or-asg
    - require_in:
      - boto_vpc: vpc

r53:
  boto3_route53.hosted_zone_absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - names:
      - {{ vpc.aws_data['priv-r53']['name'] }}:
        - Name: {{ vpc.aws_data['priv-r53']['domain'] }}
        - PrivateZone: true
      - {{ vpc.aws_data['pub-r53']['name'] }}:
        - Name: {{ vpc.aws_data['pub-r53']['domain'] }}
    - require:
      - boto3_route53: ec2-or-asg

vpc:
  boto_vpc.absent:
    - profile: {{ vpc.aws_data['profile'] }}
    - name: {{ vpc.aws_data['vpc']['name'] }}
    - require:
      - boto_vpc: sub
      - boto_vpc: igw
      - boto_secgroup: secgroup
      - boto3_route53: r53
