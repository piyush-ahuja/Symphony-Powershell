#!/bin/bash
# This bash script functions with the PowerShell GreetingBot.ps1 to make an external call to Curl, which PowerShell can't do.
# If there is a Rooms directory, it will look for files with the meeting room name, and use the content in that file
# as a welcome greeting whenever a user is added to that room.

while getopts s:k:T:u:n:r:R: option
do
 case "${option}"
 in
 s) sessionAuthToken=${OPTARG};;
 k) keyManagerToken=${OPTARG};;
 T) StreamID=${OPTARG};;
 u) user=${OPTARG};;
 n) name=${OPTARG};;
 r) room=${OPTARG};;
 R) roomDir=${OPTARG};;
 esac
done

# If you don't want a Default file, you can enter a default message here:
default="Welcome to room $room"

# Look for a specific message for that room.  If none, look for a default.  If none, make something up.
if [ -f "$roomDir/$room" ]; then content=`cat "$roomDir/$room" | sed "s/<room>/$room/g" | sed "s/<name>/$name/g" `
  elif [ -f "$roomDir/Default" ]; then content=`cat "$roomDir/Default"` 
  else content=$default
fi

# Form our proper messageML from the content
msg="<messageML><mention uid=\"$user\"></mention> $content  </messageML>"

# Use curl to post the message
curl -X POST \
  https://sup-agent.symphony.com/agent/v4/stream/$StreamID/message/create \
  -H "cache-control: no-cache" \
  -H "content-type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW" \
  -H "keymanagertoken: $keyManagerToken" \
  -H "sessiontoken: $sessionAuthToken" \
  -H "postman-token: 38062fe7-1025-5646-3997-59384e86028a" \
  --form-string "message=$msg"
