#!/bin/bash
# Created By : I-Fun | 20231106
# Assorted Zimbra Scripts that run every 30 minutes

#GLOBAL VARIABLE
MAILSERVER=$(/opt/zimbra/bin/zmhostname)

# ----------- TOP ACCOUNT SIZE USAGE -----------------------------------
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
  echo "zimbra_topstats,top=usage,email=$email usage=$usage,quota=$quota"
done <<< "$account_usage"

# -------------- Domain & Account Status ------------------------------------
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
  echo "zimbra_domains,account_count=active,domain=$domain value=$active"
  echo "zimbra_domains,account_count=closed,domain=$domain value=$closed"
  echo "zimbra_domains,account_count=locked,domain=$domain value=$locked"
  echo "zimbra_domains,account_count=maintenance,domain=$domain value=$mainte"
  echo "zimbra_domains,account_count=total,domain=$domain value=$total"
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
echo "zimbra_domains,account_count=active,domain=all value=$a"
echo "zimbra_domains,account_count=closed,domain=all value=$c"
echo "zimbra_domains,account_count=locked,domain=all value=$l"
echo "zimbra_domains,account_count=maintenance,domain=all value=$m"
echo "zimbra_domains,account_count=total,domain=all value=$t"
read o <<< $account_lockout_total
echo "zimbra_domains,account_count=lockout,domain=all value=$o"

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
  echo "zimbra_accounts,account_status=active username=\"$username\",created_date=\"$created\",lastlogon=\"$lastlogon\""
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
  echo "zimbra_accounts,account_status=closed username=\"$username\",created_date=\"$created\",lastlogon=\"$lastlogon\""
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
  echo "zimbra_accounts,account_status=locked username=\"$username\",created_date=\"$created\",lastlogon=\"$lastlogon\""
done <<< "$account_status_locked"

# Account Details with Status Maintenance
account_status_locked=$(cat $stats | grep maintenance | head -n -1)
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
  echo "zimbra_accounts,account_status=maintenance username=\"$username\",created_date=\"$created\",lastlogon=\"$lastlogon\""
done <<< "$account_status_maintenance"

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
  echo "zimbra_accounts,account_status=lockout username=\"$username\",created_date=\"$created\",lastlogon=\"$lastlogon\""
done <<< "$account_status_lockout"

# Remove Temporary File
rm -rf $stats

# ----------------- CHECK ZIMBRA VERSION --------------------------
if [ -f /etc/redhat-release ]; then
  version=$(rpm -q --queryformat "%{version}" zimbra-core | awk -F. '{print $1"."$2"."$3 }' | awk -F_ '{print $1" "$2" "$3}')
  os=$(cat /etc/redhat-release | awk '{print $1, $4}')
  echo "zimbra_version,zimbra-server=$MAILSERVER version=\"$version\",OS=\"$os\""
fi

if [ -f /etc/lsb-release ]; then
  version=$(dpkg -s zimbra-core | awk -F"[ ',]+" '/Version:/{print $2}' | awk -F. '{print $1"."$2"."$3" "$4" "$5}')
  os=$(cat /etc/lsb-release | grep DESCRIPTION | awk -F'"' '{print $2}')
  echo "zimbra_version,zimbra-server=$MAILSERVER version=\"$version\",OS=\"$os\""
fi

# ------------------- CHECK ZIMBRA SSL STATUS ---------------------
FULLDATE=$(curl -Iv --stderr - https://$MAILSERVER | grep "expire date" | awk '{print $4,$5,$6,$7,$8}')
EXPDATE=$(echo "$FULLDATE" | awk '{print $1,$2,$3,$4}')
CONVERTDATE=$(date -d "$EXPDATE" +"%s")
CURRENTDATE=$(date +"%s")
DATEDIFFERENCE=$((CONVERTDATE - CURRENTDATE))
DAYSREMAINING=$((DATEDIFFERENCE / 86400))
echo "zimbra_ssl,zimbra-server=$MAILSERVER expired-date=\"$FULLDATE\",days-remaining=$DAYSREMAINING"
