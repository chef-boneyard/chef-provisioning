# This script is currently intended to run separate from other tasks via Rake,
# hence the exits and aborts.  Maybe one day this can inspire a gem.
desc "Use the AWS SDK to terminate instances with tag 'chef-provisioning-test'"
task :aws_terminate do
  require 'aws-sdk-v1'
  require 'retryable'

  TAG_NAME = 'chef-provisioning-test'
  DRY_RUN = false

  # Create ec2 interface
  # Assumes AWS auth environment variables are set
  ec2 = AWS.ec2

  # Query for all instances matching the tag name
  # Do all the comparisons with string values before pulling all instances
  resp = ec2.client.describe_tags(filters: [
    { name: 'key', values: [TAG_NAME] }, 
    { name: 'resource-type', values: ['instance'] }
  ])

  # This will catch all instances with the tag regardless of status.
  # Circumvent here if there no instances exist.
  if resp[:tag_set].empty?
    puts "No instances found with tag '#{TAG_NAME}'. No action to take."
    exit
  end

  # select the instances ids and verify AWS only returned instances
  # with the correct tag name
  ids = []
  ids = resp[:tag_set].collect{ |t| t[:resource_id] if t[:key] == TAG_NAME }
  ids.compact! # remove nil values

  abort("AWS tag set size mismatch
    AWS: #{resp[:tag_set]}
    Collection: #{ids}") unless resp[:tag_set].size == ids.size

  # pull all instances once rather than requesting multiple queries per instance id
  all_instances = ec2.instances

  # remove instance ids from array less than 24 hours old
  twenty4_hours_ago = Time.now.utc - (60 * 60 * 24)
  #twenty4_hours_ago = Time.now.utc - (1) # uncomment line for testing!
  ids.delete_if { |id|
    instance = all_instances[id]
    instance.launch_time > twenty4_hours_ago
  }

  # now remove instances that are not running or stopped
  ids.delete_if { |id|
    instance = all_instances[id]
    ![:running, :stopped].include?(instance.status)
  }

  if ids.empty?
    puts "No running or stopped instances found with tag '#{TAG_NAME}'. No action to take."
    exit
  end

  puts "Attemping to terminate running and stopped instances with tag '#{TAG_NAME}'."
  puts ids.join("\n")

  resp = ec2.client.terminate_instances(options = { :instance_ids => ids, :dry_run => DRY_RUN })

  # check that the instances have started shutting down
  running_instances = []
  retryable(:tries => 5, :sleep => lambda { |n| 2**n }) do
    running_instances = ids.select { |id| ec2.instances[id].status == :running }
    raise StandardError, "Instances have not started shutting down: #{running_instances}." unless running_instances.empty?
  end

  puts "Instances terminated."

  exit

end
