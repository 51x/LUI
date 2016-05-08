LUI
------
Linux User Info - Simple tool to speed up linux system administration.

How to install?
------

      cd /tmp/
      git clone https://github.com/51x/LUI
      cd LUI
      mv lui_debian.sh /sbin/lu
      chmod +x /sbin/lu
      lu

How to use?
------
    lui
        -h This help message.
        -i User information, use as "-i user".
        -x eXtended information.
        -a List all users.
        -l List all users with locked password.
        -u List all users with unlocked password.
        -n List users with nologin shell.

        You can use multiple arguments too, eg. "./lui_deb.sh -l -u"
