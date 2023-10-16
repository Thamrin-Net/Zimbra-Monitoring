# This Script need Permission to Execute from telegraf user :
here the step to allow telegraf using this script

## Add PAM Rules
- open "/etc/pam.d/su" using your favorite text editor
- add this line after auth line :
  auth       [success=ignore default=1] pam_succeed_if.so user = zimbra
  auth       sufficient   pam_succeed_if.so use_uid user ingroup zimbra
- save it

## Add Telegraf to Zimbra Group
- type usermod -aG zimbra telegraf
