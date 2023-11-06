#!/bin/bash
git clone https://github.com/Thamrin-Net/Zimbra-Monitoring /tmp/zmbmon
mv /tmp/zmbmon/* /etc/telegraf/
rm -rf /etc/telegraf/README.md
rm -rf /etc/telegraf/scripts/Readme.md
rm -rf /tmp/zmbmon
