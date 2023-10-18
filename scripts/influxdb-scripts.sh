#!/bin/bash
# Assorted Zimbra Scripts for InfluxDB using Telegraf inputs.exec
# Script By : I-Fun | 20231016

# --------------- TOP 10 SENDER ------------------------------------
topsender=$(cat /var/log/zimbra.log | awk -F 'from=<' '{print $2}' | awk -F'>' '{print $1}' | sed '/^$/d'| grep -v "bounce" | sort | uniq -c | sort -nk1 -r | sed -n '1,10p')
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
  echo "top_sender,email=$email total=$sent"
done <<< "$topsender"

# --------------- TOP 10 RECEIVER ------------------------------------
topreceiver=$(cat /var/log/zimbra.log | awk -F 'to=<' '{print $2}' | awk -F'>' '{print $1}' | sed '/^$/d'| grep -v "bounce" | sort | uniq -c | sort -nk1 -r | sed -n '1,10p')
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
  echo "top_receiver,email=$email total=$receive"
done <<< "$topreceiver"

# --------------- TOP 10 REJECTED MAIL SERVER ------------------------------------
toprejectsrv=$(cat /var/log/zimbra.log | grep reject | awk -F '<' '{print $2}' | awk -F '>' '{print $1}' | sed '/^$/d'| sort | uniq -c | sort -nk1 -r | sed -n '1,10p')
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
  echo "top_reject_server,servername=$host total=$reject"
done <<< "$toprejectsrv"

# --------------- TOP 10 REJECTED SENDER ------------------------------------
toprejectsender=$(cat /var/log/zimbra.log | grep reject | awk -F 'from=<' '{print $2}' | awk -F '>' '{print $1}' | sed '/^$/d'| sort | uniq -c | sort -nk1 -r | sed -n '1,10p')
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
  echo "top_reject_sender,sender=$sender total=$reject"
done <<< "$toprejectsender"

# -------------- Account Status -------------------------------------
# Account on Domain Status (active, closed, locked, maintenance, total)
account_status=$(su - zimbra -c '/opt/zimbra/bin/zmaccts' | grep -v "spam." | grep -v "virus-quarantine." | awk '/domain summary/,0' | tail -n +5)
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  domain=$(echo "$line" | awk '{print $1}')
  active=$(echo "$line" | awk '{print $2}')
  closed=$(echo "$line" | awk '{print $3}')
  locked=$(echo "$line" | awk '{print $4}')
  mainte=$(echo "$line" | awk '{print $5}')
  total=$(echo "$line" | awk '{print $6}')
  # Print the Influxdb-style
  echo "account_status,domain=$domain active=$active"
  echo "account_status,domain=$domain closed=$closed"
  echo "account_status,domain=$domain locked=$locked"
  echo "account_status,domain=$domain maintenance=$mainte"
  echo "account_status,domain=$domain total=$total"
done <<< "$account_status"

# Total Account on Mail Server
account_status_total=$(su - zimbra -c '/opt/zimbra/bin/zmaccts' |
grep -v "spam." |
grep -v "virus-quarantine." |
awk '/domain summary/,0' |
tail -n +5 |
awk '{print $2, $3, $4, $5, $6}' |
awk '{a+=$1; c+=$2; l+=$3; m+=$4; t+=$5} END {print a, c, l, m, t}')
# Process Data column by column
read a c l m t <<< "$account_status_total"
echo "account_status,domain=all active=$a"
echo "account_status,domain=all closed=$c"
echo "account_status,domain=all locked=$l"
echo "account_status,domain=all maintenance=$m"
echo "account_status,domain=all total=$t"
# Account Lockout Status
account_status_lockout_total=$(su - zimbra -c '/opt/zimbra/bin/zmaccts' | grep lockout | wc -l | awk '{lockout=$1} END {print lockout}')
read lockout <<< $account_status_lockout_total
echo "account_status,domain=all lockout=$lockout"

# Account with Status Lockout
account_status_lockout=$(su - zimbra -c '/opt/zimbra/bin/zmaccts' | grep lockout)
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract account and last sign in values
  username=$(echo "$line" | awk '{print $1}')
  lastsign="$(echo "$line" | awk '{print $5}' | awk '{gsub(/\./, "", $0); print}' | awk '{ gsub("never", "0"); print }')"
  formatted_date="$(date -d "$(echo "$lastsign" | sed -r 's/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3 \4:\5:\6/')" '+%Y-%m-%d %H:%M:%S')"
  lastsign="$(echo "$formatted_date" | awk '{ if ($2 == "00:00:00") $1 = "Never"; print $1, $2 }')"
  # Print the Influxdb-style
  echo "account_status,username=$username lastsignin=\"$lastsign\""

done <<< "$account_status_lockout"

# ----------- ACCOUNT SIZE USAGE -----------------------------------
MAILSERVER=$(/opt/zimbra/bin/zmhostname)
TOP=10
account_usage=$(su - zimbra -c "zmprov getQuotaUsage $MAILSERVER | grep -v 'spam.' | grep -v 'virus-quarantine.' | head -n $TOP")
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  account=$(echo "$line" | awk '{print $1}')
  quota=$(echo "$line" | awk '{print $2}')
  usage=$(echo "$line" | awk '{print $3}')
  # Print the Influxdb-style
  echo "account_details,account=$account usage=$usage"
  echo "account_details,account=$account quota=$quota"
done <<< "$account_usage"

# ------------ ZIMBRA STATUS -------------------------------------
get_sv=$(su - zimbra -c "/opt/zimbra/bin/zmcontrol status")
IFS=$'\n'
get_sv=($get_sv)

for i in "${!get_sv[@]}"; do
  sv_value=0
  sv_name=$(echo "${get_sv[$i]}" | cut -c 1-24 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr ' ' '-')
  sv_status=$(echo "${get_sv[$i]}" | cut -c 26- | sed -e 's/^[ \t]*//')

  if [[ "${get_sv[$i]}" != "Host"* ]]; then
    if [[ $sv_status == "Running" ]]; then
      sv_value=1
    else
      if [[ "${get_sv[$i]}" == *"Stopped"* ]]; then
        sv_name=$(echo "${get_sv[$i]}" | cut -c 1-24 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr ' ' '-')
        sv_status="Stopped"
      elif [[ "${get_sv[$i]}" == *"is not running"* ]]; then
        continue
      fi
    fi
    echo "zimbra_status,service=\"$sv_name\" status=$sv_value"

  fi
done
