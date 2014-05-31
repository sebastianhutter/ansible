#!/bin/bash

# this script prepares the centos host for the management by ansible
# setup for centos 6.5

# if we are running as root start with the setup process
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

USERNAME=ansible
# cant specify sudo password in ansible playbook yet. user will be created without password
#USERPASS='$1$66MhpGge$MmeSG8PtFaxojKLhBHQhv/'
ANSIBLEHOME=/var/ansible
SUDOERSFILE=/etc/sudoers.d/ansible
PAM=/etc/pam.d/sudo
PUBLICKEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqv5AqnC19iCzOFt+bpLgvs0y9gv2COrc0MLpmX6s3xJa5FPDZZpQiqCnQ94ik7AbJwjJImfyfTV8dx+1W+xUFr1252GO+0QHQC9uPI2rDL/KVKb9gHKZFGrXd9uPW3FlY66mWGtKMQYSqpsOpnkhqfHrj4gvi3MKCsJlackSsIw3+E19jMwkfPvQRvV1nWt60I1z9m4r4eHUYo1TZ3mY2yutJcusbHl36cSxFnu+5KGlGnnPaGZFEZYB24xloXRvwGx92eJ22jaiS17FT/IRQ2XGYuXNneNueKsSMD/V7G3CzZMrs69iGheh3V7phnKitA5A4IfH4NXoTFJjp5nMkw=="

# the setup does the following

# create the user account
useradd -c 'ansible system user. used by our configuration management' -m -d $ANSIBLEHOME $USERNAME
if [[ $? -ne 0 ]]; then
	echo "could not create user $USERNAME. aborting..." 1>&2
	exit 2
fi

# set the selinux role for the ansible home directory
# only if selinux is enabled
ENABLED=`cat /selinux/enforce`
if [ "$ENABLED" == 1 ]; then
	chcon -h unconfined_u:object_r:user_home_dir_t:s0 /var/ansible     
fi

# create a sudoers configuration
# the sudoers config will allow all users in the group 'ansible' to execute commands
# without a passwd as long as they are authenticated via ssh key

# install the necessary pam module
## no pam ssh agent auth module necessary. will use nopasswd in sudo for the meantime
#yum -y install pam_ssh_agent_auth
#if [[ $? -ne 0 ]]; then
#	echo "could not install pam_ssh_agent_auth module. aborting ..." 1>&2
#	exit 3
#fi

# now create the sudoers file
touch $SUDOERSFILE
if [[ $? -ne 0 ]]; then
	echo "could not create file '$SUDOERSFILE'. aborting ..." 1>&2
	exit 4
fi

# allow ansible to execute any command without password
echo $USERNAME ALL=\(ALL\) NOPASSWD:ALL >> $SUDOERSFILE

## now configure pam to enable sudo authentication via ssh
## only the authorized keys for the ansible users are allowed
## http://siliconexus.com/blog/2012/11/sudo-authentication-via-ssh-agent/comment-page-1/
#sed -i "2i\auth sufficient pam_ssh_agent_auth.so file=$ANSIBLEHOME/.ssh/authorized_keys" $PAM
#if [[ $? -ne 0 ]]; then
#	echo "could not add pam auth to '$PAM'. aborting ..." 1>&2
#	exit 5
#fi

# create the ssh directory for the ansible user
mkdir $ANSIBLEHOME/.ssh
if [[ $? -ne 0 ]]; then
	echo "couldnt create .ssh directory in $ANSIBLEHOME. aborting ..." 1>&2
	exit 6
fi


# add the public key for the user
echo $PUBLICKEY > $ANSIBLEHOME/.ssh/authorized_keys
if [[ $? -ne 0 ]]; then
	echo "could not add the authoorized_keys file. aborting ..." 1>&2
	exit 7
fi


# set the correct permissions
chown -R $USERNAME:$USERNAME $ANSIBLEHOME/.ssh
chmod 0700 $ANSIBLEHOME/.ssh
chmod 0600 $ANSIBLEHOME/.ssh/authorized_keys
if [[ $? -ne 0 ]]; then
	echo "could not change permissions on .ssh directory. aborting ..." 1>&2
	exit 8
fi
