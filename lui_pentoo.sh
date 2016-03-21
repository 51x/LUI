#!/bin/bash
# LUI for Pentoo - Version 2.1.6b
#
# Description: This script searches and organizes information about users on Pentoo/Gentoo systems. It is written to make administration easier and for better transparency.
#
# Note: this program has been tested on Pentoo 4.6.
#
# Author: 51x
# License: GNU AFFERO GENERAL PUBLIC LICENSE - Version 3, 19 November 2007
#
# Copyright (C) 2016 51x
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
    Linux User Info

        -h This help message.
        -i User information, use as "-i user".
        -x eXtended information.
        -a List all users.
        -l List all users with locked password.
        -u List all users with unlocked password.
        -n List users with nologin shell.

        You can use multiple arguments too, eg. "./lui_deb.sh -l -u"
  '''
}

function user_info {
  data=$(grep ^$OPTARG: /etc/passwd)
  if [ -z "$data" ]
    then
      echo "User not found in /etc/passwd."
      exit ;
  fi
  user=$(echo $data | cut -d: -f1)
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
  homepriv=$(ls -ld $home | awk {'print $1,$3,$4'})
  if [ -z "$homepriv" ]
    then
      homepriv="Home directory does not exist."
  fi
  pass=$(passwd -S $OPTARG | cut -d' ' -f2-)
  groups=$(groups $user | cut -d: -f2)
  if [ -z "$groups" ]
    then
      groups="-"
  fi
  shell=$(echo $data | cut -d: -f7)
  groupid=$(echo $data | cut -d: -f3)
  ID=$(echo $data | cut -d: -f4)

  echo
  echo "User name:   $user"
  echo "Comment:     $comment"
  echo "Password:    $pass"
  echo "Home dir:    $home"
  echo "Home perm:   $homepriv"
  echo "Groups:     $groups"
  echo "Login shell: $shell"
  echo "User ID:     $ID"
  echo "Group ID:    $groupid"
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
  last | grep $user | tail -4 | tr -s ' '
  echo
  fails=$(pam_tally --user $user | rev | cut -d ' ' -f1 | rev)
  echo "Numer of failed logins: " $fails
  echo
  fail_list=$(grep sshd.\*Failed /var/log/auth.log | grep $user)
  if [ ! -z "$fail_list" ]
    then
      echo "Last six login fails:"
      grep sshd.\*Failed /var/log/auth.log | grep $user | tail -6
  fi
}

function all_users {
  min_uid=$(grep "^UID_MIN" /etc/login.defs | tr -s ' ' | cut -d' ' -f2)
  echo "System users / Under UID $min_uid"
  echo "---------------------------------"
  awk -F':' -v "minuid=$min_uid" '{ if ( $3 < minuid ) print $0 }' /etc/passwd
  grep nobody /etc/passwd
   echo
  echo "Normal users / Below UID $min_uid"
  echo "---------------------------------"
  awk -F':' -v "minuid=$min_uid" '{ if ( $3 >= minuid ) print $0 }' /etc/passwd | grep -v ^nobody:
  echo
}

function locked_users {
  echo "Locked users:"
  cat /etc/passwd | cut -d : -f 1 | awk '{ system("passwd -S " $0) }' | grep -e "\sL\s"
  echo
}

function unlocked_users {
  echo "Unlocked users:"
  cat /etc/passwd | cut -d : -f 1 | awk '{ system("passwd -S " $0) }' | grep -v -e "\sL\s"
  echo
}

function nologin_users {
  echo "Users with nologin:"
  cat /etc/passwd | grep /nologin
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
        echo "Option -$OPTARG requires an argument." ;;
    esac
  done

if [ -z "$1" ]
  then
    help
fi
