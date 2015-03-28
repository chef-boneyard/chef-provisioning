# Chef-Provisioning Docker Demo

This demo runs on both Azure and AWS.

## Initial setup

1. Grab the chef-provisioning demo repository.
   ```bash
   git clone https://github.com/chef/chef-provisioning.git
   cd chef-provisioning
   git checkout jk/demo
   cd docs/demos/docker_app
   ```
2. Set up the gem bundle and download the demo cookbooks
   ```bash
   bundle install
   bundle exec rake init
   ```

## Running On Azure

1. Install the cross-platform CLI from [here](http://azure.microsoft.com/en-us/documentation/articles/xplat-cli/#install).
2. Download your Azure credentials, as describe [here](http://azure.microsoft.com/en-us/documentation/articles/xplat-cli/#configure).  (Note: the `azure login` credentials method will not currently work with chef-provisioning; you need to use `account import` as described here.)

   ```bash
   azure account download
   azure account import <filename>
   ```
3. Run Chef.
   ```ruby
   bundle exec chef-client -z -o "myapp::azure,myapp::cluster"
   ```

Repeating the last command will repeat the installation.

## Running On AWS

1. Install the AWS CLI from [here](http://docs.aws.amazon.com/cli/latest/userguide/installing.html#choosing-an-installation-method).
2. Input your AWS credentials, as described [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration):
   ```bash
   $ aws configure
   AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
   AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   Default region name [None]: us-west-2
   Default output format [None]: json
   azure account download
   azure account import <filename>
   ```
3. Run Chef.
   ```ruby
   bundle exec chef-client -z -o "myapp::aws,myapp::cluster"
   ```

Repeating the last command will repeat the installation.
