* Substitute `<aws_access_key>` and `<aws_secret_key>` appropriately in:
  * `cloud.providers.d/ec2.conf`
  * `master.d/aws.conf`
* Run it: `salt-run state.orchestrate aws.orch`
* Cleanup: `salt-run state.orchestrate aws.cleanup`

The orchestration is split into vpc, ec2/asg and r53 to stagger out Jinja rendering so that dependents don't fall over on a not-yet-provisioned dependency.
