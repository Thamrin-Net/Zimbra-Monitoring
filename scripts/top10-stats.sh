#!/bin/bash
# Zimbra Scripts for Generate Top 10 Stats with InfluxDB using Telegraf inputs.exec
# Script By : I-Fun | 20231016

# Global Variable :
log=/var/log/zimbra.log
MAILSERVER=$(/opt/zimbra/bin/zmhostname)
TOP=10

# --------------- TOP 10 SENDER ------------------------------------
topsender=$(cat "$log" | 
awk -F 'from=<' '{print $2}' | 
awk -F'>' '{print $1}' | 
sed '/^$/d'| grep -v bounce | 
sort | uniq -c | sort -nk1 -r | 
sed -n '1,$TOPp')
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  sent=$(echo "$line" | awk '{print $1}')
  email=$(echo "$line" | awk '{print $2}')
  # Print the Influxdb-style
  echo "top_$TOP,top=sender,email=\"$email\" total=$sent"
done <<< "$topsender"

# --------------- TOP 10 RECEIVER ------------------------------------
topreceiver=$(cat "$log" | 
awk -F 'to=<' '{print $2}' | 
awk -F'>' '{print $1}' | 
sed '/^$/d'| grep -v bounce | 
sort | uniq -c | sort -nk1 -r | 
sed -n '1,$TOPp')
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  receive=$(echo "$line" | awk '{print $1}')
  email=$(echo "$line" | awk '{print $2}')
  # Print the Influxdb-style
  echo "top_$TOP,top=receiver,email=$email total=$receive"
done <<< "$topreceiver"

# --------------- TOP 10 REJECTED MAIL SERVER ------------------------------------
toprejectsrv=$(cat "$log" | 
grep reject | awk -F '<' '{print $2}' | 
awk -F '>' '{print $1}' | sed '/^$/d'| 
sort | uniq -c | sort -nk1 -r | sed -n '1,$TOPp')
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  reject=$(echo "$line" | awk '{print $1}')
  host=$(echo "$line" | awk '{print $2}')
  # Print the Influxdb-style
  echo "top_$TOP,top=rejected-server,servername=\"$host\" total=$reject"
done <<< "$toprejectsrv"

# --------------- TOP 10 REJECTED SENDER ------------------------------------
toprejectsender=$(cat "$log" | 
grep reject | awk -F 'from=<' '{print $2}' | 
awk -F '>' '{print $1}' | sed '/^$/d'| sort | 
uniq -c | sort -nk1 -r | sed -n '1,$TOPp')
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  reject=$(echo "$line" | awk '{print $1}')
  sender=$(echo "$line" | awk '{print $2}')
  # Print the Influxdb-style
  echo "top_$TOP,top=rejected-sender,email=\"$sender\" total=$reject"
done <<< "$toprejectsender"

# ----------- TOP 10 ACCOUNT SIZE USAGE -----------------------------------
account_usage=$(su - zimbra -c "zmprov getQuotaUsage $MAILSERVER | 
grep -v 'spam.' | grep -v 'virus-quarantine.' | head -n $TOP")
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  email=$(echo "$line" | awk '{print $1}')
  quota=$(echo "$line" | awk '{print $2}')
  usage=$(echo "$line" | awk '{print $3}')
  # Print the Influxdb-style
  echo "top_$TOP,top=usage,email=$email usage=$usage,quota=$quota"
done <<< "$account_usage"
