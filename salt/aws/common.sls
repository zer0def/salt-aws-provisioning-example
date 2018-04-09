{% set aws_data = {
  'profile': 'awsprofile',
  'vpc': {
    'name': 'asdf',
    'cidr': '192.168.255.192/26',
  },
  'igw': {
    'name': 'asdf',
  },
  'pub-rtb': {
    'pub-sub-a': {
      'name': 'pub-rtb-a',
      'routes': {}
    },
    'pub-sub-b': {
      'name': 'pub-rtb-b',
      'routes': {}
    },
  },
  'pub-sub': {
    '{}a'.format(salt['config.get']('awsprofile:region')): {
      'name': 'pub-sub-a',
      'cidr': '192.168.255.208/28',
    },
    '{}b'.format(salt['config.get']('awsprofile:region')): {
      'name': 'pub-sub-b',
      'cidr': '192.168.255.240/28',
    },
  },
  'pub-r53': {
    'name': 'pub-r53',
    'domain': 'zer0def.public.',
  },
  'pub-elb': {
    'name': 'pub-elb',
  },
  'pub-asg': {
    'name': 'pub-asg',
    'lc': 'pub-lc',
    'sqs': 'pub-asg-sqs',
    'sns': 'pub-asg-sns',
    'sqs_policy_name': 'PubASGSQSSNS',
  },
  'priv-rtb': {
    'priv-sub-a': {
      'name': 'priv-rtb-a',
      'routes': {}
    },
    'priv-sub-b': {
      'name': 'priv-rtb-b',
      'routes': {}
    },
  },
  'priv-sub': {
    '{}a'.format(salt['config.get']('awsprofile:region')): {
      'name': 'priv-sub-a',
      'cidr': '192.168.255.192/28',
    },
    '{}b'.format(salt['config.get']('awsprofile:region')): {
      'name': 'priv-sub-b',
      'cidr': '192.168.255.224/28',
    },
  },
  'priv-r53': {
    'name': 'priv-r53',
    'domain': 'zer0def.private.',
  },
  'priv-elb': {
    'name': 'priv-elb',
  },
  'priv-asg': {
    'name': 'priv-asg',
    'lc': 'priv-lc',
    'sqs': 'priv-asg-sqs',
    'sns': 'priv-asg-sns',
    'sqs_policy_name': 'PrivASGSQSSNS',
  },
  'sg': {
    'name': 'asdf'
  },
  'ec2': {
    'name': 'saltmaster',
    'instance_type': 't2.micro',
    'image': 'ami-0fc85a60',
    'key_name': 'asdf',
  }
} %}
{% set cloud_provider_name = 'ec2-frankfurt' %}
