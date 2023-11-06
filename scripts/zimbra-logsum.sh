#!/bin/bash
# Assorted Zimbra Scripts for InfluxDB using Telegraf inputs.exec
# Script By : I-Fun | 20231016

# --------------- CHECK TODAY STATUS ------------------------------------

received=$(/etc/telegraf/script/zimbralogsumm.pl -d today /var/log/zimbra.log -zimbra-received)
delivered=$(/etc/telegraf/script/zimbralogsumm.pl -d today /var/log/zimbra.log -zimbra-delivered)
deferred=$(/etc/telegraf/script/zimbralogsumm.pl -d today /var/log/zimbra.log -zimbra-deferred)
bounced=$(/etc/telegraf/script/zimbralogsumm.pl -d today /var/log/zimbra.log -zimbra-bounced)
rejected=$(/etc/telegraf/script/zimbralogsumm.pl -d today /var/log/zimbra.log -zimbra-rejected)
forwarded=$(/etc/telegraf/script/zimbralogsumm.pl -d today /var/log/zimbra.log -zimbra-forwarded)
receivebyte=$(/etc/telegraf/script/zimbralogsumm.pl -d today /var/log/zimbra.log -zimbra-bytes-received)
delivebyte=$(/etc/telegraf/script/zimbralogsumm.pl -d today /var/log/zimbra.log -zimbra-bytes-delivered)

echo "zimbra_today,status=received value=$received"
echo "zimbra_today,status=delivered value=$delivered"
echo "zimbra_today,status=deferred value=$deferred"
echo "zimbra_today,status=bounced value=$bounced"
echo "zimbra_today,status=rejected value=$rejected"
echo "zimbra_today,status=forwarded value=$forwarded"
echo "zimbra_today,status=receivebyte value=$receivebyte"
echo "zimbra_today,status=delivebyte value=$delivebyte"

#----------------------------------------------------------
