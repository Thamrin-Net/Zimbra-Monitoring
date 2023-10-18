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
#Generate Account & Domain Status
stats=/tmp/zmbstats.log
generate_stat=$(su - zimbra -c '/opt/zimbra/bin/zmaccts' > $stats)

# Account on Domain Status (active, closed, locked, maintenance, total)
domain_status=$(cat $stats | awk '/domain summary/,0' | tail -n +5)
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
  echo "domain_status,domain=$domain active=$active"
  echo "domain_status,domain=$domain closed=$closed"
  echo "domain_status,domain=$domain locked=$locked"
  echo "domain_status,domain=$domain maintenance=$mainte"
  echo "domain_status,domain=$domain total=$total"
done <<< "$domain_status"

# Total Account on Mail Server
account_status_total=$(cat $stats |
awk '/domain summary/,0' |
tail -n +5 |
awk '{a+=$2; c+=$3; l+=$4; m+=$5; t+=$6} END {print a, c, l, m, t}')
account_lockout_total=$(cat $stats | 
grep lockout | 
wc -l | 
awk '{o=$1} END {print o}')
# Process Data column by column
read a c l m t <<< "$account_status_total"
echo "domain_status,domain=all active=$a"
echo "domain_status,domain=all closed=$c"
echo "domain_status,domain=all locked=$l"
echo "domain_status,domain=all maintenance=$m"
echo "domain_status,domain=all total=$t"
read o <<< $account_lockout_total
echo "account_status,domain=all lockout=$o"

# Account Details with Status Active
account_status_active=$(cat $stats | grep active | head -n -1)
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract account and last sign in values
  username=$(echo "$line" | awk '{print $1}')
  created=$(echo "$line" | awk '{print $3, $4}')
  lastlogon="$(echo "$line" | awk '{print $5}' |
awk -F'\t' '{
    if ($NF ~ /^[0-9]+[.]$/) {
        sub(/[.]/, "", $NF);
        formatted_date = substr($NF, 1, 4) "-" substr($NF, 5, 2) "-" substr($NF, 7, 2) " " substr($NF, 9, 2) ":" substr($NF, 11, 2) ":" substr($NF, 13, 2);
        $NF = formatted_date;
    } else if ($NF == "never") {
        $NF = "Never Login";
    }
    print $0;
}')"
  # Print the Influxdb-style
  echo "account_status,status=active,username=$username created_date=\"$created\",lastlogon=\"$lastlogon\""
done <<< "$account_status_active"

# Account Details with Status Closed
account_status_closed=$(cat $stats | grep closed | head -n -1)
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract account and last sign in values
  username=$(echo "$line" | awk '{print $1}')
  created=$(echo "$line" | awk '{print $3, $4}')
  lastlogon="$(echo "$line" | awk '{print $5}' |
awk -F'\t' '{
    if ($NF ~ /^[0-9]+[.]$/) {
        sub(/[.]/, "", $NF);
        formatted_date = substr($NF, 1, 4) "-" substr($NF, 5, 2) "-" substr($NF, 7, 2) " " substr($NF, 9, 2) ":" substr($NF, 11, 2) ":" substr($NF, 13, 2);
        $NF = formatted_date;
    } else if ($NF == "never") {
        $NF = "Never Login";
    }
    print $0;
}')"
  # Print the Influxdb-style
  echo "account_status,status=closed,username=$username created_date=\"$created\",lastlogon=\"$lastlogon\""
done <<< "$account_status_closed"

# Account Details with Status Locked
account_status_locked=$(cat $stats | grep locked | head -n -1)
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract account and last sign in values
  username=$(echo "$line" | awk '{print $1}')
  created=$(echo "$line" | awk '{print $3, $4}')
  lastlogon="$(echo "$line" | awk '{print $5}' |
awk -F'\t' '{
    if ($NF ~ /^[0-9]+[.]$/) {
        sub(/[.]/, "", $NF);
        formatted_date = substr($NF, 1, 4) "-" substr($NF, 5, 2) "-" substr($NF, 7, 2) " " substr($NF, 9, 2) ":" substr($NF, 11, 2) ":" substr($NF, 13, 2);
        $NF = formatted_date;
    } else if ($NF == "never") {
        $NF = "Never Login";
    }
    print $0;
}')"
  # Print the Influxdb-style
  echo "account_status,status=locked,username=$username created_date=\"$created\",lastlogon=\"$lastlogon\""
done <<< "$account_status_locked"

# Account Details with Status Lockout
account_status_lockout=$(cat $stats | grep lockout | head -n -1)
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract account and last sign in values
  username=$(echo "$line" | awk '{print $1}')
  created=$(echo "$line" | awk '{print $3, $4}')
  lastlogon="$(echo "$line" | awk '{print $5}' |
awk -F'\t' '{
    if ($NF ~ /^[0-9]+[.]$/) {
        sub(/[.]/, "", $NF);
        formatted_date = substr($NF, 1, 4) "-" substr($NF, 5, 2) "-" substr($NF, 7, 2) " " substr($NF, 9, 2) ":" substr($NF, 11, 2) ":" substr($NF, 13, 2);
        $NF = formatted_date;
    } else if ($NF == "never") {
        $NF = "Never Login";
    }
    print $0;
}')"
  # Print the Influxdb-style
  echo "account_status,status=lockout,username=$username created_date=\"$created\",lastlogon=\"$lastlogon\""
done <<< "$account_status_lockout"

# Remove Temporary File
rm -rf $stats

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
