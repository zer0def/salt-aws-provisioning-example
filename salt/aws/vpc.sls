{% import 'aws/common.sls' as vpc with context %}

{#
{% set eips = salt['boto_ec2.get_all_eip_addresses'](profile=salt['config.get'](vpc.aws_data['profile'], {})) %}
{% if not eips %}
  {% set eip_info = salt['boto_ec2.allocate_eip_address'](domain='vpc', profile=salt['config.get'](vpc.aws_data['profile'], {})) %}
  {% set eip_ip = eip_info['public_ip'] %}
{% else %}
  {% set eip_ip = salt['boto_ec2.get_unassociated_eip_address'](domain='vpc', profile=salt['config.get'](vpc.aws_data['profile'], {})) %}
  {% set eip_info = salt['boto_ec2.get_eip_address_info'](addresses=[eip_ip], profile=salt['config.get'](vpc.aws_data['profile'], {})) %}
{% endif %}
{% set eip_alloc_id = eip_info['allocation_id'] %}
#}

vpc:
  boto_vpc.present:
    - profile: {{ vpc.aws_data['profile'] }}
    - name: {{ vpc.aws_data['vpc']['name'] }}
    - cidr_block: {{ vpc.aws_data['vpc']['cidr'] }}
    - instance_tenancy: default
    - dns_support: true
    - dns_hostnames: true

igw:
  boto_vpc.internet_gateway_present:
    - profile: {{ vpc.aws_data['profile'] }}
    - name: {{ vpc.aws_data.get('igw', {}).get('name', '') }}
    - vpc_name: {{ vpc.aws_data['vpc']['name'] }}
    - require:
      - boto_vpc: vpc

pub-rtb:
  boto_vpc.route_table_present:
    - profile: {{ vpc.aws_data['profile'] }}
    - names: {{ vpc.aws_data['pub-rtb'].values()|map(attribute='name')|list }}
    - vpc_name: {{ vpc.aws_data['vpc']['name'] }}
    - routes:
      - destination_cidr_block: '0.0.0.0/0'
        internet_gateway_name: {{ vpc.aws_data.get('igw', {}).get('name', '') }}
    - require:
      - boto_vpc: igw

pub-sub:
  boto_vpc.subnet_present:
    - profile: {{ vpc.aws_data['profile'] }}
    - vpc_name: {{ vpc.aws_data['vpc']['name'] }}
    - names:
{% for az, subnet in vpc.aws_data['pub-sub'].items() %}
      - {{ subnet['name'] }}:
        - cidr_block: {{ subnet['cidr'] }}
        - availability_zone: {{ az }}
        - route_table_name: {{ vpc.aws_data['pub-rtb'][subnet['name']]['name'] }}
{% endfor %}
{% for az, subnet in vpc.aws_data['priv-sub'].items() %}
      - {{ subnet['name'] }}:
        - cidr_block: {{ subnet['cidr'] }}
        - availability_zone: {{ az }}
{% endfor %}
    - require:
      - boto_vpc: vpc
      - boto_vpc: pub-rtb

r53:
  boto3_route53.hosted_zone_present:
    - profile: {{ vpc.aws_data['profile'] }}
    - names:
      - {{ vpc.aws_data['pub-r53']['name'] }}:
        - Name: {{ vpc.aws_data['pub-r53']['domain'] }}
        - PrivateZone: false
      - {{ vpc.aws_data['priv-r53']['name'] }}:
        - Name: {{ vpc.aws_data['priv-r53']['domain'] }}
        - PrivateZone: true
        - VPCs:
          - VPCName: {{ vpc.aws_data['vpc']['name'] }}
            VPCRegion: {{ salt['config.get']('{}:region'.format(vpc.aws_data['profile'])) }}

nat:
  boto_vpc.nat_gateway_present:
    - profile: {{ vpc.aws_data['profile'] }}
    - names:
{% for subnet in vpc.aws_data['pub-sub'].values() %}
      - {{ subnet['name'] }}:
        - subnet_name: {{ subnet['name'] }}
{% endfor %}
{#    - allocation_id: {{ eip_alloc_id }} #}
    - require:
      - boto_vpc: igw
      # private subnet requisite
      - boto_vpc: pub-sub

secgroup:
  boto_secgroup.present:
    - profile: {{ vpc.aws_data['profile'] }}
    - name: {{ vpc.aws_data['sg']['name'] }}
    - description: 'Default SG for VPC {{ vpc.aws_data['vpc']['name'] }}'
    - vpc_name: {{ vpc.aws_data['vpc']['name'] }}
    - rules:
      - ip_protocol: all
        from_port: -1
        to_port: -1
        source_group_name: '{{ vpc.aws_data['sg']['name'] }}'
      - ip_protocol: tcp
        from_port: 22
        to_port: 22
        cidr_ip: '0.0.0.0/0'
    - require:
      - boto_vpc: vpc
