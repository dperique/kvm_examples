#!/usr/bin/expect

# Usage:

#  setRoot.sh <aHost> <aPassword>
#
#  Turn on root login for ssh
#
set aHost [lindex $argv 0]
set aPass [lindex $argv 1]

set timeout 60
log_user 1

spawn ssh centos@$aHost

expect "password:" { send "$aPass\r" }
expect "$ " { send "sudo su\r" }
expect "# " { send "echo \"PermitRootLogin yes\" >> /etc/ssh/sshd_config\r" }
expect "# " { send "service sshd restart\r" }

expect "# " { send "exit\r" }
expect "$ " { send "exit\r" }
