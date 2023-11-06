#!/bin/bash
# Created By : I-Fun | 20231106
# Assorted Zimbra Scripts that run every 1 minute

# -------------- Email Today Status ------------------------------------
#Generate Zimbra Daily Report
stats=/tmp/zmbmailstats.log
generate_stat=$(/opt/zimbra/libexec/zmdailyreport > $stats)

# Today Mail Status (received, delivered, forwarded, deferred, bounced, rejected, held, discarded)
t_received=$(cat $stats | awk '/Grand Total/,0' | tail -n +5 | head -n +10 | grep received | awk '{print $1}')
t_delivered=$(cat $stats | awk '/Grand Total/,0' | tail -n +5 | head -n +10 | grep delivered | awk '{print $1}')
t_forwarded=$(cat $stats | awk '/Grand Total/,0' | tail -n +5 | head -n +10 | grep forwarded | awk '{print $1}')
t_deferred=$(cat $stats | awk '/Grand Total/,0' | tail -n +5 | head -n +10 | grep deferred | awk '{print $1}')
t_bounced=$(cat $stats | awk '/Grand Total/,0' | tail -n +5 | head -n +10 | grep bounced | awk '{print $1}')
t_rejected=$(cat $stats | awk '/Grand Total/,0' | tail -n +5 | head -n +10 | grep rejected | awk '{print $1}')
t_held=$(cat $stats | awk '/Grand Total/,0' | tail -n +5 | head -n +10 | grep help | awk '{print $1}')
t_discarded=$(cat $stats | awk '/Grand Total/,0' | tail -n +5 | head -n +10 | grep discarded | awk '{print $1}')

  # Print the Influxdb-style
  echo "zimbra_today,status=received value=$t_received"
  echo "zimbra_today,status=delivered value=$t_delivered"
  echo "zimbra_today,status=forwarded value=$t_forwarded"
  echo "zimbra_today,status=deferred value=$t_deferred"
  echo "zimbra_today,status=bounced value=$t_bounced"
  echo "zimbra_today,status=rejected value=$t_rejected"
  echo "zimbra_today,status=held value=$t_held"
  echo "zimbra_today,status=discarded value=$t_discarded"

# ------------ Top Domain Receiver -----------------------------------------------
topdomarcvr=$(cat $stats | sed -n '/Message Delivery/,/^$/{/./p}' | tail -n +5 )
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  total=$(echo "$line" | awk '{print $1}')
  bytes=$(echo "$line" | awk '{print $2}')
  defers=$(echo "$line" | awk '{print $3}')
  avgdelay=$(echo "$line" | awk '{print $4}')
  maxdelay=$(echo "$line" | awk '{print $5}')
  domain=$(echo "$line" | awk '{print $6}')
  # Print the Influxdb-style
    echo "zimbra_topstats,top=receiver-domain,domainname=$domain total=$total"
    echo "zimbra_topstats,top=receiver-domain,domainname=$domain bytes=$bytes"
    echo "zimbra_topstats,top=receiver-domain,domainname=$domain defers=$defers"
    echo "zimbra_topstats,top=receiver-domain,domainname=$domain avgdelay=$avgdelay"
    echo "zimbra_topstats,top=receiver-domain,domainname=$domain maxdelay=$maxdelay"
    
done <<< "$topdomarcvr"
