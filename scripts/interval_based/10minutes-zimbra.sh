#!/bin/bash
# Created By : I-Fun | 20231106
# Assorted Zimbra Scripts that run every 10 minutes

# Global Variable :
log=/var/log/zimbra.log
MAILSERVER=$(/opt/zimbra/bin/zmhostname)
TOP=10    #Change This Value if you want

# --------------- TOP SENDER ------------------------------------
topsender=$(cat "$log" | grep -v unknown |
awk -F 'from=<' '{print $2}' |
awk -F'>' '{print $1}' |
sed '/^$/d'|  tr '=' '_' |
sort | uniq -c | sort -nk1 -r |
head -n $TOP)
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
  echo "zimbra_topstats,top=sender,email=$email total=$sent"
done <<< "$topsender"

# --------------- TOP SENDER DOMAIN ------------------------------------
topsenderdom=$(cat "$log" | grep -v unknown |
grep "RCPT from" |
awk -F '@' '{print $2}' |
awk -F '>:' '{print $1}' |
sed '/^$/d'|  tr '=' '_' |
sort | uniq -c | sort -nk1 -r |
head -n $TOP)
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  sentdom=$(echo "$line" | awk '{print $1}')
  domain=$(echo "$line" | awk '{print $2}')
  # Print the Influxdb-style
  echo "zimbra_topstats,top=sender-domain,domainname=$domain total=$sentdom"
done <<< "$topsenderdom"

# --------------- TOP RECEIVER ------------------------------------
topreceiver=$(cat "$log" |
awk -F 'to=<' '{print $2}' |
awk -F'>' '{print $1}' |
sed '/^$/d'|  tr '=' '_' |
sort | uniq -c | sort -nk1 -r |
head -n $TOP)
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
  echo "zimbra_topstats,top=receiver,email=$email total=$receive"
done <<< "$topreceiver"

# --------------- TOP RECEIVER DOMAIN ------------------------------------
topreceiverdom=$(cat "$log" | grep "status=sent" |
awk -F '@' '{print $2}' |
awk -F '>,' '{print $1}' |
sed '/^$/d'|  tr '=' '_' |
sort | uniq -c | sort -nk1 -r |
head -n $TOP)
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  recdom=$(echo "$line" | awk '{print $1}')
  domain=$(echo "$line" | awk '{print $2}')
  # Print the Influxdb-style
  echo "zimbra_topstats,top=receiver-domain,domainname=$domain total=$recdom"
done <<< "$topreceiverdom"

# --------------- TOP REJECTED SENDER ------------------------------------
toprejectsender=$(cat "$log" | grep reject: |
awk -F 'from=<' '{print $2}' |
awk -F '>' '{print $1}' |
sed '/^$/d'|  tr '=' '_' |
sort | uniq -c | sort -nk1 -r |
head -n $TOP)
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
  echo "zimbra_topstats,top=rejected-sender,email=\"$sender\" total=$reject"
done <<< "$toprejectsender"

# --------------- TOP REJECTED MAIL SERVER ------------------------------------
toprejectsrv=$(cat "$log" | grep reject: |
awk -F 'from ' '{print $2}' |
awk -F ':' '{print $1}' |
sed '/^$/d'|  tr '=' '_' |
sort | uniq -c | sort -nk1 -r |
head -n $TOP)
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  rejectsrv=$(echo "$line" | awk '{print $1}')
  host=$(echo "$line" | awk '{print $2}')
  # Print the Influxdb-style
  echo "zimbra_topstats,top=rejected-server,servername=\"$host\" total=$rejectsrv"
done <<< "$toprejectsrv"

# ------------ CHECK ZIMBRA SERVICES STATUS -------------------------------------
get_sv=$(su - zimbra -c "/opt/zimbra/bin/zmcontrol status")
IFS=$'\n'
get_sv=($get_sv)

for i in "${!get_sv[@]}"; do
  sv_value=0
  sv_name=$(echo "${get_sv[$i]}" | cut -c 1-24 | 
  sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr ' ' '-')
  sv_status=$(echo "${get_sv[$i]}" | cut -c 26- | 
  sed -e 's/^[ \t]*//')

  if [[ "${get_sv[$i]}" != "Host"* ]]; then
    if [[ $sv_status == "Running" ]]; then
      sv_value=1
    else
      if [[ "${get_sv[$i]}" == *"Stopped"* ]]; then
        sv_name=$(echo "${get_sv[$i]}" | cut -c 1-24 | 
        sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr ' ' '-')
        sv_status="Stopped"
      elif [[ "${get_sv[$i]}" == *"is not running"* ]]; then
        continue
      fi
    fi
    echo "zimbra_service,service_name=$sv_name status=$sv_value"
  fi
done


