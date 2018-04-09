# SQS messaging setup
sqs:
  salt.runner:
    - name: salt.cmd
    - arg:
      - state.sls
      - aws.sqs

sns:
  salt.runner:
    - name: salt.cmd
    - arg:
      - state.sls
      - aws.sns
    - require:
      - salt: sqs

# setting up VPC
vpc:
  salt.runner:
    - name: salt.cmd
    - arg:
      - state.sls
      - aws.vpc

vpc_privrtb:
  salt.runner:
    - name: salt.cmd
    - arg:
      - state.sls
      - aws.vpc_privrtb
    - require:
      - salt: vpc

# creates new salt-master
ec2:
  salt.runner:
    - name: salt.cmd
    - arg:
      - state.sls
      - aws.ec2
    - require:
      - salt: vpc_privrtb

r53:
  salt.runner:
    - name: salt.cmd
    - arg:
      - state.sls
      - aws.r53
    - require:
      - salt: ec2

# this should be swapped for cloudwatch definitions
asg:
  salt.runner:
    - name: salt.cmd
    - arg:
      - state.sls
      - aws.asg
    - require:
      - salt: r53
      - salt: sns
