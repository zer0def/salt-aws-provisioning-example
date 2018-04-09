{% import 'aws/common.sls' as vpc with context %}

{% set ec2_subnet = salt['boto_vpc.describe_subnet'](subnet_name=vpc.aws_data['pub-sub']['{}a'.format(salt['config.get']('awsprofile:region'))]['name'], profile=salt['config.get'](vpc.aws_data['profile'], {}))['subnet'] %}

ec2:
  boto_ec2.key_present:
    - profile: {{ vpc.aws_data['profile'] }}
    - name: {{ vpc.aws_data['ec2']['key_name'] }}
    - upload_public: salt://aws/keys/id_rsa.pub
  cloud.present:
    - name: {{ vpc.aws_data['ec2']['name'] }}
    - cloud_provider: {{ vpc.cloud_provider_name }}
    - size: {{ vpc.aws_data['ec2']['instance_type'] }}
    - image: {{ vpc.aws_data['ec2']['image'] }}
    - del_root_vol_on_destroy: true
    - del_all_vols_on_destroy: true
    - rename_on_destroy: true
    - script: amzn-master
    - usernames:
      - ec2-user
    - script_args: {{ salt['environ.get']('SUPAH_SIKRIT') }}
    - parallel: false
    - network_interfaces:
      - DeviceIndex: 0
        AssociatePublicIpAddress: true
        SubnetId: {{ ec2_subnet['id'] }}
        SecurityGroupId:
          - {{ salt['boto_secgroup.get_group_id'](vpc.aws_data['sg']['name'], vpc_name=vpc.aws_data['vpc']['name'], profile=salt['config.get'](vpc.aws_data['profile'], {})) }}
    - private_key: {{ salt['config.get']('file_roots:base')|first }}/aws/keys/id_rsa
    - require:
#      - boto_secgroup: secgroup
      - boto_ec2: ec2
