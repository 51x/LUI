#!/bin/bash
# LUI for RedHat Linux / CheckPoint Firewall - Version 2.11
#
# Description: This script searches and organizes information about users on RedHat systems. It is written to make administration easier and for better transparency.
#
# Note: LUI has been tested on most CheckPoint firewalls (before 2015).
#
# Author: s1x
# License: GNU AFFERO GENERAL PUBLIC LICENSE - Version 3, 19 November 2007
#
# Copyright (C) 2015 s1x, pgp key 0xF673700F
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
 

function help {
  echo '''
     Linux User Info v2.1

        -h This help message.
        -i User information, use as "-i user".
        -x eXtended information.
        -a List all users.
        -l List all users with locked password.
        -u List all users with unlocked password.
        -n List users with nologin shell.

        You can user multiple arguments too, eg. "sh lui_checkpoint_fw.sh -l -u"
'''
}

function user_info {
  data=$(grep ^$OPTARG: /etc/passwd)
  if [ -z "$data" ]
    then
      echo "User not found in /etc/passwd."
      exit ;
  fi
  user=$(echo $data | cut -d: -f1 | head -1)
  comment=$(grep ^$user /etc/passwd | cut -d: -f5)
  if [ -z "$comment" ]
    then
      comment="-"
  fi
  home=$(echo $data | cut -d: -f6)
  if [ -z "$home" ]
    then
      home="-"
  fi
  homepriv=$(ls -ld $home)
  if [ -z "$homepriv" ]
    then
      homepriv="Home directory does not exist."
  fi
  pass=$(passwd -S root)
  groups=$(grep "^$user:" /etc/group | rev | cut -d: -f1 | rev)
  if [ -z "$groups" ]
    then
      groups="-"
  fi
  shell=$(echo $data | cut -d: -f7)
  group=$(echo $data | cut -d: -f3)
  ID=$(echo $data | cut -d: -f4)

  echo
  echo "User name:      $user"
  echo "Comment:        $comment"
  echo "Password:       $pass"
  echo "Home dir:       $home"
  echo "Home perm:      $homepriv"
  echo "Groups:         $groups"
  echo "Login shell:    $shell"
  echo "User ID:        $ID"
  echo "Group ID:       $group"
  echo
}

function eXtended {
#Experimental function!
  echo
  echo "User information"
  echo "----------------"
  user_info
  chage -l $user | tr -d '\t'
  echo
  echo
  echo "Login information"
  echo -e "----------------- \n"
  echo "Last four logins:"
  last | grep $user | tail -4
  echo
  fails=$(pam_tally2 --user root | sed -n '1!p' | rev | tr -s ' ' | rev | cut -d ' ' -f 2)
  echo "Numer of current failed logins: " $fails
  echo "(Couter reset with pam_tally2.)"
  echo
  fail_list=$(grep sshd.\*Failed /var/log/secure | grep $user)
  if [ ! -z "$fail_list" ]
    then
      echo "Last six login fails:"
      grep sshd.\*Failed /var/log/secure | grep $user | tail -6
  fi
  echo
}

function all_users {
  min_uid=$(grep "^UID_MIN" /etc/login.defs | tr -s ' ' | cut -d' ' -f2)
  echo "System users / Under UID $min_uid"
  echo "---------------------------------"
  awk -F':' -v "minuid=$min_uid" '{ if ( $3 < minuid ) print $0 }' /etc/passwd
  echo
  echo "Normal users / Below UID $min_uid"
  echo "---------------------------------"
  awk -F':' -v "minuid=$min_uid" '{ if ( $3 >= minuid ) print $0 }' /etc/passwd
}

function locked_users {
  echo "Locked users:"
  cat /etc/passwd | cut -d : -f 1 | awk '{ system("passwd -S " $0) }' | grep "locked"
  echo
}

function unlocked_users {
  echo "Unlocked users:"
  cat /etc/passwd | cut -d : -f 1 | awk '{ system("passwd -S " $0) }' | grep -v "locked."
  echo
}

function nologin_users {
  echo "Users with nologin:"
   grep /nologin /etc/passwd
  echo
}


while getopts ":hi:x:alun" opt;
  do
case $opt in
      h) help ;;
      i) user_info ;;
      x) eXtended ;;
      a) all_users ;;
      l) locked_users ;;
      u) unlocked_users ;;
      n) nologin_users ;;
     \?)
         echo "Invalid option."
         exit 1 ;;
      :)
        echo "Option -$OPTARG requires an argument."

    esac
done

if [ -z "$1" ]
  then
    help
fi
