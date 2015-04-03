require 'chef/provisioning/machine/basic_machine'
require 'digest'

class Chef
module Provisioning
  class Machine
    class UnixMachine < BasicMachine
      def initialize(machine_spec, transport, convergence_strategy)
        super

        @tmp_dir = '/tmp'
      end

      # Options include:
      #
      # command_prefix - prefix to put in front of any command, e.g. sudo
      attr_reader :options

      # Delete file
      def delete_file(action_handler, path)
        if file_exists?(path)
          action_handler.perform_action "delete file #{path} on #{machine_spec.name}" do
            transport.execute("rm -f #{path}").error!
          end
        end
      end

      def is_directory?(path)
        result = transport.execute("stat -c '%F' #{path}", :read_only => true)
        return nil if result.exitstatus != 0
        result.stdout.chomp == 'directory'
      end

      # Return true or false depending on whether file exists
      def file_exists?(path)
        result = transport.execute("ls -d #{path}", :read_only => true)
        result.exitstatus == 0 && result.stdout != ''
      end

      def files_different?(path, local_path, content=nil)
        if !file_exists?(path) || (local_path && !File.exists?(local_path))
          return true
        end

        # Get remote checksum of file
        result = transport.execute("md5sum -b #{path}", :read_only => true)
        unless result.exitstatus == 0
          result = transport.execute("md5 -r #{path}", :read_only => true)
        end
        result.error!
        remote_sum = result.stdout.split(' ')[0]

        digest = Digest::MD5.new
        if content
          digest.update(content)
        else
          File.open(local_path, 'rb') do |io|
            while (buf = io.read(4096)) && buf.length > 0
              digest.update(buf)
            end
          end
        end
        remote_sum != digest.hexdigest
      end

      def create_dir(action_handler, path)
        if !file_exists?(path)
          action_handler.perform_action "create directory #{path} on #{machine_spec.name}" do
            transport.execute("mkdir -p #{path}").error!
          end
        end
      end

      # Set file attributes { mode, :owner, :group }
      def set_attributes(action_handler, path, attributes)
        if attributes[:mode] || attributes[:owner] || attributes[:group]
          current_attributes = get_attributes(path)
          if attributes[:mode] && current_attributes[:mode].to_i != attributes[:mode].to_i
            action_handler.perform_action "change mode of #{path} on #{machine_spec.name} from #{current_attributes[:mode].to_i} to #{attributes[:mode].to_i}" do
              transport.execute("chmod #{attributes[:mode].to_i} #{path}").error!
            end
          end
          if attributes[:owner] && current_attributes[:owner] != attributes[:owner]
            action_handler.perform_action "change group of #{path} on #{machine_spec.name} from #{current_attributes[:owner]} to #{attributes[:owner]}" do
              transport.execute("chown #{attributes[:owner]} #{path}").error!
            end
          end
          if attributes[:group] && current_attributes[:group] != attributes[:group]
            action_handler.perform_action "change group of #{path} on #{machine_spec.name} from #{current_attributes[:group]} to #{attributes[:group]}" do
              transport.execute("chgrp #{attributes[:group]} #{path}").error!
            end
          end
        end
      end

      # Get file attributes { :mode, :owner, :group }
      def get_attributes(path)
        result = transport.execute("stat -c '%a %U %G %n' #{path}", :read_only => true)
        return nil if result.exitstatus != 0
        file_info = result.stdout.split(/\s+/)
        if file_info.size <= 1
          raise "#{path} does not exist in set_attributes()"
        end
        result = {
          :mode => file_info[0],
          :owner => file_info[1],
          :group => file_info[2]
        }
      end

      def dirname_on_machine(path)
        path.split('/')[0..-2].join('/')
      end
    end

    def detect_os(action_handler)
      #
      # Use detect.sh to detect the operating system of the remote machine
      #
      # TODO do this in terms of commands rather than writing a shell script
      self.write_file(action_handler, "#{@tmp_dir}/detect.sh", detect_sh)
      detected = self.execute_always("sh #{@tmp_dir}/detect.sh")
      if detected.exitstatus != 0
        raise "detect.sh exited with nonzero exit status: #{detected.exitstatus}"
      end
      platform = nil
      platform_version = nil
      machine_architecture = nil
      detected.stdout.each_line do |line|
        if line =~ /^PLATFORM: (.+)/
          platform = $1
        elsif line =~ /^PLATFORM_VERSION: (.+)/
          platform_version = $1
        elsif line =~ /^MACHINE: (.+)/
          machine_architecture = $1
        end
      end
      [ platform, platform_version, machine_architecture ]
    end

    private

    def detect_sh
      result = <<EOM
prerelease="false"

project="chef"

report_bug() {
echo "Please file a bug report at https://github.com/chef/chef-provisioning/issues"
echo "Project: Chef"
echo "Component: Packages"
echo "Label: Omnibus"
echo "Version: $version"
echo " "
echo "Please detail your operating system type, version and any other relevant details"
}


machine=`uname -m`
os=`uname -s`

# Retrieve Platform and Platform Version
if test -f "/etc/lsb-release" && grep -q DISTRIB_ID /etc/lsb-release; then
platform=`grep DISTRIB_ID /etc/lsb-release | cut -d "=" -f 2 | tr '[A-Z]' '[a-z]'`
platform_version=`grep DISTRIB_RELEASE /etc/lsb-release | cut -d "=" -f 2`
elif test -f "/etc/debian_version"; then
platform="debian"
platform_version=`cat /etc/debian_version`
elif test -f "/etc/redhat-release"; then
platform=`sed 's/^\\(.\\+\\) release.*/\\1/' /etc/redhat-release | tr '[A-Z]' '[a-z]'`
platform_version=`sed 's/^.\\+ release \\([.0-9]\\+\\).*/\\1/' /etc/redhat-release`

# If /etc/redhat-release exists, we act like RHEL by default
if test "$platform" = "fedora"; then
# Change platform version for use below.
platform_version="6.0"
fi
platform="el"
elif test -f "/etc/system-release"; then
platform=`sed 's/^\\(.\\+\\) release.\\+/\\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
platform_version=`sed 's/^.\\+ release \\([.0-9]\\+\\).*/\\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
# amazon is built off of fedora, so act like RHEL
if test "$platform" = "amazon linux ami"; then
platform="el"
platform_version="6.0"
fi
# Apple OS X
elif test -f "/usr/bin/sw_vers"; then
platform="mac_os_x"
# Matching the tab-space with sed is error-prone
platform_version=`sw_vers | awk '/^ProductVersion:/ { print $2 }'`

major_version=`echo $platform_version | cut -d. -f1,2`
case $major_version in
"10.6") platform_version="10.6" ;;
"10.7"|"10.8"|"10.9") platform_version="10.7" ;;
*) echo "No builds for platform: $major_version"
 report_bug
 exit 1
 ;;
esac

# x86_64 Apple hardware often runs 32-bit kernels (see OHAI-63)
x86_64=`sysctl -n hw.optional.x86_64`
if test $x86_64 -eq 1; then
machine="x86_64"
fi
elif test -f "/etc/release"; then
platform="solaris2"
machine=`/usr/bin/uname -p`
platform_version=`/usr/bin/uname -r`
elif test -f "/etc/SuSE-release"; then
if grep -q 'Enterprise' /etc/SuSE-release;
then
platform="sles"
platform_version=`awk '/^VERSION/ {V = $3}; /^PATCHLEVEL/ {P = $3}; END {print V "." P}' /etc/SuSE-release`
else
platform="suse"
platform_version=`awk '/^VERSION =/ { print $3 }' /etc/SuSE-release`
fi
elif test "x$os" = "xFreeBSD"; then
platform="freebsd"
platform_version=`uname -r | sed 's/-.*//'`
elif test "x$os" = "xAIX"; then
platform="aix"
platform_version=`uname -v`
machine="ppc"
# Linux supporting /etc/os-release
elif test -f "/etc/os-release"; then
platform=`awk -F'=' '/^ID=/ { print $2 }' /etc/os-release`
platform_version=`awk -F'=' '/^VERSION_ID=/ { print $2 }' /etc/os-release`
fi

if test "x$platform" = "x"; then
echo "Unable to determine platform version!"
report_bug
exit 1
fi

# Mangle $platform_version to pull the correct build
# for various platforms
major_version=`echo $platform_version | cut -d. -f1`
case $platform in
"el")
platform_version=$major_version
;;
"debian")
case $major_version in
"5") platform_version="6";;
"6") platform_version="6";;
"7") platform_version="6";;
esac
;;
"freebsd")
platform_version=$major_version
;;
"sles")
platform_version=$major_version
;;
"suse")
platform_version=$major_version
;;
esac

if test "x$platform_version" = "x"; then
echo "Unable to determine platform version!"
report_bug
exit 1
fi

if test "x$platform" = "xsolaris2"; then
# hack up the path on Solaris to find wget
PATH=/usr/sfw/bin:$PATH
export PATH
fi

echo "PLATFORM: $platform"
echo "PLATFORM_VERSION: $platform_version"
echo "MACHINE: $machine"
EOM
    end
  end
end
end
