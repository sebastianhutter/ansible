#!/usr/bin/env python

# filename: ansible-role.py
# author: sebastian hutter <huttersebastian@gmail.com>
#
# description: this short python script enables you to run single ansible roles
#              it creates a temporary ansible playbook with the specified role
#              or roles and executes it with ansible-playbook
#
#              you can use all parameters you normale use in ansible-playbook
#              to control ansibles behaviour (become, limit, ...)
#
# add the script to your path by creating a softlink to /usr/local/bin
# sudo ln -rs ansible-role.py /usr/local/bin/

import argparse
import os
import tempfile
from subprocess import call


# parse the given arguments
parser = argparse.ArgumentParser(prog='ansible-role', description='Run a single or multiple ansible role.')
parser.add_argument('-r', '--role', action='append', required=True)
args = parser.parse_known_args()

# create a temporary playbook which will be used by ansible-playbook
playbook = tempfile.NamedTemporaryFile(mode='w', delete=False)
# create dynamic playbook with the defined roles
playbook.write(
  '---\n\n' + \
  '- hosts: all\n' + \
  '  roles:\n'
)
for role in args[0].role:
  playbook.write('    - ' + role + '\n')
# close the playbook to enable it being parsed by ansible-playbook
playbook.close()

# create the ansible-playbook command line
cmd = list()
cmd.append('ansible-playbook')
cmd.extend(args[1])
cmd.append(playbook.name)

# execute the ansible command line
call(cmd)

# delete the temporary playbook
os.remove(playbook.name)