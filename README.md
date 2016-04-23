# Deployer

Deployer is used to create | update | delete CloudFormation Stacks

##### Flags
* -c <config file> (REQUIRED) -- Yaml configuration file to run against.
* -e <environment name> (REQUIRED) -- Environment Name corresponding to a block in the config file.
* -x <execute command> (REQUIRED) -- create|update|delete Action you wish to take on the stack.
* -p <profile> (REQUIRED) -- AWS CLI Profile to use for AWS commands [CLI Getting Started](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)

**Other flags not yet used.**

##### Example
`./deployer.py -c config.yml -e Environment -x create -p profileName`

`./deployer.py -c config.yml -e DevDerek -x create -p profileName`


# The Config

The config is a large dictionary. First keys within the dictionary are Environment Names. The global Environment Parameters is a common ground to deduplicate parameter entries that are used in each Environment. Environment parameters overwrite global parameters. 

## All Environments
All environments have a release version (interchangable with branch name), a stack name and a template location. These are used for the Top level stack and define where to find the top level stack. 
The CloudToolsBucket parameter is used with the release number(or branch name) and then the template path to construct the s3 location of the top level template. 

### Network
**There must be a Network Environment.** 

##### Parameters
These parameters correspond to parameters that need to be passed to the [DMZ-Top.json](/cloudformation/DMZ-Top.json) template.


### Service Environments

##### Parameters
These parameters correspond to parameters that need to be passed to the [Environment.json](/cloudformation/Environment.json) template.

These parameters provide identity to the Services like what AMI to use or what bootstrap file to pull even the size of the instance.
```
    parameters:
      Monitoring: 'True'
      # Bootstrap and CloudFormation bucket infered by CloudToolsBucket/{release | branch}/{bootstrap | cloudformation}
      BootstrapBucket: aws-tools-us-east-1/1.1/bootstrap
      CloudFormationBucket: aws-tools-us-east-1/1.1/cloudformation
      NginxAMI: ami-cbb9ecae
      NginxInstanceType: t2.medium
...
      UploadAMI: ami-3069145a
      UploadInstanceType: t2.medium
```

##### Lookup Parameters

These are parameters that need to be pulled from another stack. The key in this key value pair is the ParameterKey being passed to this Stack. The Value is a custom structure that requires a Stack and OutputKey. The stack is the Environment name and the OutputKey is the name of the output from the stack being targeted. The script will fetch the stack output and retrieve the output key, using it's value for the parameter value. 

These are mainly used for pulling data from the Network Stack like SNS topics or Subnets
```
    lookup_parameters:
      VPC: { Stack: Network, OutputKey: VPC }
      VPCCIDR: { Stack: Network, OutputKey: VPCCIDR }
      PublicSubnets: { Stack: Network, OutputKey: DevPublicSubnets }
      PrivateSubnets: { Stack: Network, OutputKey: DevPrivateSubnets }
```


Network takes 15 minutes to boot

Environment takes 30 minutes to boot


## Code
deployer.py is the main script. This contains the arguments and options for the scirpt and a main method. This file imports cloudformation.py.

#### cloudformation.py
Abstract class for wrapping the CloudFormation Stack 
Network and Environment Stack Classes. 

**Note** The abstract class may not be relivant, all of the methods are simmular enough but starting this way provides flexablility if the need arise. 

## Updates
When running updates to environments you'll be running updates to the CloudFormation Stack specified by Environement. 

Making updates to CloudFormation there are a lot of considerations to be had. See the [Running Updates](/cloudformation/) section of the CloudFormation [README.md](/cloudformation/README.md).
Updates to CloudFormation will change the living Infrastructure based on your current configuration. 
Updates using this script will not update the objects in s3. If you're making alterations to the cloudformation or bootstrap directory you'll need to first sync with S3. See [s3_sync.sh](../)
After syncing with S3 or if there are no changes other than your yaml configuration file you're ready to run an update.  

To run an update follow the following structure:
```
./deployer.py -c sandbox-us-east-1.yml -p profileName -e <Environment Name> -x update
```


## Deletes
When using this script to delete it simply looks up the environment variable you've provied to the command in the configuration file and issues a delete to that CloudFormation Stack name.

When deleting the Network environment the script will issue a command to remove the S3 Endpoint associated with the Network.

To issue a delete command follow the following structure:
```
./deployer.py -c sandbox-us-east-1.yml -p profileName -e <Environment Name> -x update
```


## Starting From Scratch

1. Build a configuration file
2. Start with a Network
  * Network requires release, stack_name, template and parameters
  * release corresponds to a tag or branch which is a prefix to the S3 object keys stored in s3.
    * To sync with S3 see [s3_sync.sh](/scripts/)
    * This is automated by Jenkins.
  * stack_name can be any name, this will be used for the name of the nested stack in cloudformation.
  * template is a relative path to the <CloudToolsBucket>/<release>/<path to cloudformation template>. This will typically point to 'cloudformation/DMZ-Top.json'
  * parameters are used to pass values to the template parameters. See Parameters section above.
3. Boot the Network Environment
  * `./deployer.py -c sandbox-us-east-1.yml -p profileName -e Network -x create`
4. Create a Environment in configuration
  * Environments require release, stack_name, template and parameters
  * release corresponds to a tag or branch which is a prefix to the S3 object keys stored in s3.
    * To sync with S3 see [s3_sync.sh](/scripts/)
    * This is automated by Jenkins.
  * stack_name can be any name, this will be used for the name of the nested stack in cloudformation
  * template is a relative path to the <CloudToolsBucket>/<release>/<path to cloudformation template>. This will typically point to 'cloudformation/Environment.json'
  * parameters are used to pass values to the template parameters. See Parameters section above.
  * Environment also allows for lookup_parameters. See Lookup Parameters section above.
5. Boot the Environment
  * `./deployer.py -c prototype-us-east-1.yml -p profileName -e Dev -x create`
6. Follow up by watching the CloudFormation console. 