{% import 'aws/common.sls' as vpc with context %}

priv-rtb:
  boto_vpc.route_table_present:
    - profile: {{ vpc.aws_data['profile'] }}
    - vpc_name: {{ vpc.aws_data['vpc']['name'] }}
    - names:
{% for subnet_name in vpc.aws_data['priv-rtb'].keys() %}
      - {{ vpc.aws_data['priv-rtb'][subnet_name]['name'] }}:
        - routes:
          - destination_cidr_block: '0.0.0.0/0'
            nat_gateway_subnet_name: pub-sub-{{ subnet_name.split('-')|last }}
{% endfor %}

priv-sub:
  boto_vpc.subnet_present:
    - profile: {{ vpc.aws_data['profile'] }}
    - vpc_name: {{ vpc.aws_data['vpc']['name'] }}
    - names:
{% for az, subnet in vpc.aws_data['priv-sub'].items() %}
      - {{ subnet['name'] }}:
        - cidr_block: {{ subnet['cidr'] }}
        - availability_zone: {{ az }}
        - route_table_name: {{ vpc.aws_data['priv-rtb'][subnet['name']]['name'] }}
{% endfor %}
    - require:
      - boto_vpc: priv-rtb
