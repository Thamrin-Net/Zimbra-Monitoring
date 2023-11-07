#!/bin/bash
# Created By : I-Fun | 20231106
# Assorted Zimbra Scripts that run every 1 minute

## GLOBAL VARIABLE & FUNCTION
# ---------- Function to convert k,m,g to bytes -------------------------
function ConvertToBytes() {
  local input="$1"
  local suffix="${input: -1}"  # Get the last character of the input

  if [[ "$suffix" == "k" ]]; then
    local value="${input%k}"  # Remove the 'k' suffix
    local bytes=$((value * 1024))
    echo "$bytes"
  elif [[ "$suffix" == "m" ]]; then
    local value="${input%m}"  # Remove the 'm' suffix
    local bytes=$((value * 1024 * 1024))
    echo "$bytes"
  elif [[ "$suffix" == "g" ]]; then
    local value="${input%g}"  # Remove the 'g' suffix
    local bytes=$((value * 1024 * 1024 * 1024))
    echo "$bytes"
  else
    echo "$1"
  fi
}

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
t_held=$(cat $stats | awk '/Grand Total/,0' | tail -n +5 | head -n +10 | grep held | awk '{print $1}')
t_discarded=$(cat $stats | awk '/Grand Total/,0' | tail -n +5 | head -n +10 | grep discarded | awk '{print $1}')
t_bytesrcvd=$(cat $stats | awk '/Grand Total/,0' | tail -n +15 | head -n +6 | grep received | awk '{print $1}')
t_bytesdeliv=$(cat $stats | awk '/Grand Total/,0' | tail -n +15 | head -n +6 | grep delivered | awk '{print $1}')
t_senders=$(cat $stats | awk '/Grand Total/,0' | tail -n +15 | head -n +6 | grep senders | awk '{print $1}')
t_sendtodomain=$(cat $stats | awk '/Grand Total/,0' | tail -n +15 | head -n +6 | grep sending | awk '{print $1}')
t_recipients=$(cat $stats | awk '/Grand Total/,0' | tail -n +15 | head -n +6 | grep "recipients" | awk '{print $1}')
t_reciptdomain=$(cat $stats | awk '/Grand Total/,0' | tail -n +15 | head -n +6 | grep "recipient hosts" | awk '{print $1}')

  # Print the Influxdb-style
  echo "zimbra_today,today=received value=$t_received"
  echo "zimbra_today,today=delivered value=$t_delivered"
  echo "zimbra_today,today=forwarded value=$t_forwarded"
  echo "zimbra_today,today=deferred value=$t_deferred"
  echo "zimbra_today,today=bounced value=$t_bounced"
  echo "zimbra_today,today=rejected value=$t_rejected"
  echo "zimbra_today,today=held value=$t_held"
  echo "zimbra_today,today=discarded value=$t_discarded"
  
  echo "zimbra_today,today=UniqueSenders value=$t_senders"
  echo "zimbra_today,today=SentToDomain value=$t_sendtodomain"
  echo "zimbra_today,today=Recipients value=$t_recipients"
  echo "zimbra_today,today=DomainReceiver value=$t_reciptdomain"

  bytesr=$(ConvertToBytes "$t_bytesrcvd")
  bytesd=$(ConvertToBytes "$t_bytesdeliv")
  echo "zimbra_today,today=BytesReceived sizeH=\"$t_bytesrcvd\""
  echo "zimbra_today,today=BytesDelivered sizeH=\"$t_bytesdeliv\""
  echo "zimbra_today,today=BytesReceived sizeB=$bytesr"
  echo "zimbra_today,today=BytesDelivered sizeB=$bytesd"
 
# ------------ Top Domain Delivered to -----------------------------------------------
topdomadeliv=$(cat $stats | sed -n '/Message Delivery/,/^$/{/./p}' | tail -n +5 )
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  domain=$(echo "$line" | awk '{print $8}')
  total=$(echo "$line" | awk '{print $1}')
  size=$(echo "$line" | awk '{print $2}')
  defers=$(echo "$line" | awk '{print $3}')
  avgdelay=$(echo "$line" | awk '{print $4}')
  maxdelay=$(echo "$line" | awk '{print $6}')

  # Print the Influxdb-style
    echo "zimbra_today,today=DeliveredToDomain,ToDomain=$domain total=$total"
    echo "zimbra_today,today=DeliveredToDomain,ToDomain=$domain defers=$defers"
    echo "zimbra_today,today=DeliveredToDomain,ToDomain=$domain avgdelay=$avgdelay"
    echo "zimbra_today,today=DeliveredToDomain,ToDomain=$domain maxdelay=$maxdelay"

    sizeB=$(ConvertToBytes "$bytes")
    echo "zimbra_today,today=DeliveredToDomain,ToDomain=$domain sizeH=\"$size\""
    echo "zimbra_today,today=DeliveredToDomain,ToDomain=$domain sizeB=$sizeB"
    
done <<< "$topdomdeliv"

# ------------ Top Domain Received from -----------------------------------------------
topdomarcvd=$(cat $stats | sed -n '/Message Received/,/^$/{/./p}' | tail -n +5 )
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  domain=$(echo "$line" | awk '{print $3}')
  total=$(echo "$line" | awk '{print $1}')
  size=$(echo "$line" | awk '{print $2}')
  sizeB=$(ConvertToBytes "$size")
  
  # Print the Influxdb-style
    echo "zimbra_today,today=ReceivedFromDomain,FromDomain=$domain total=$total"
    echo "zimbra_today,today=ReceivedFromDomain,FromDomain=$domain sizeH=\"$size\""
    echo "zimbra_today,today=ReceivedFromDomain,FromDomain=$domain sizeB=$sizeB"
    
done <<< "$topdomarcvd"

# ------------ Top Senders By Message Count -----------------------------------------------
topsendercount=$(cat $stats | sed -n '/top 50 Senders by message count/,/^$/{/./p}' | tail -n +3 | tr '=' '_' )
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  email=$(echo "$line" | awk '{print $2}')
  total=$(echo "$line" | awk '{print $1}')

  # Print the Influxdb-style
    echo "zimbra_today,today=SenderCount,SenderName=$email total=$total"
    
done <<< "$topsendercount"

# ------------ Top Receiver By Message Count -----------------------------------------------
toprecvcount=$(cat $stats | sed -n '/top 50 Recipients by message count/,/^$/{/./p}' | tail -n +3 | tr '&' '_' )
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  email=$(echo "$line" | awk '{print $2}')
  total=$(echo "$line" | awk '{print $1}')

  # Print the Influxdb-style
    echo "zimbra_today,today=ReceiverCount,ReceiverName=$email total=$total"
    
done <<< "$toprecvcount"

# ------------ Top Senders By Message Size -----------------------------------------------
topsendersize=$(cat $stats | sed -n '/top 50 Senders by message size/,/^$/{/./p}' | tail -n +3 | tr '=' '_' )
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  email=$(echo "$line" | awk '{print $2}')
  size=$(echo "$line" | awk '{print $1}')
  sizeB=$(ConvertToBytes "$size")

  # Print the Influxdb-style
    echo "zimbra_today,today=SenderBySize,SenderName=$email sizeH=\"$size\""
    echo "zimbra_today,today=SenderBySize,SenderName=$email sizeB=$sizeB"
    
done <<< "$topsendersize"

# ------------ Top Senders By Message Size -----------------------------------------------
toprcvsize=$(cat $stats | sed -n '/top 50 Recipients by message size/,/^$/{/./p}' | tail -n +3 | tr '=' '_' )
# Process the data line by line
while IFS= read -r line; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi
  # Extract domain and status values
  email=$(echo "$line" | awk '{print $2}')
  size=$(echo "$line" | awk '{print $1}')
  sizeB=$(ConvertToBytes "$size")

  # Print the Influxdb-style
    echo "zimbra_today,today=RecipientsBySize,ReceiverName=$email sizeH=\"$size\""
    echo "zimbra_today,today=RecipientsBySize,ReceiverName=$email sizeB=$sizeB"
    
done <<< "$toprcvsize"


# -------------- Remove Temporary File ---------------------------------------------------
rm -rf $stats
