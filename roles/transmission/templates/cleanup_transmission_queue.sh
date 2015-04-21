#!/bin/bash

# this script stops the transmission daemon and cleans up torrents
# it is possible that we loose an active download trough it but the risk is small

logger -t "cleantransmissionqueue" "starting transmission queue cleanup script"
# check if the download directory exist
if [ -d "{{ queue }}" ]; then
  systemctl stop transmission-daemon
  # delete files
  logger -t "cleantransmissionqueue" "check {{ queue }} for torrents older then 7 days"
  find "{{ queue }}" -mtime +7 -delete -exec logger -t "cleantransmissionqueue" delete {} \;
  systemctl start transmission-daemon
fi
logger -t "cleantransmissionqueue" "finished transmission queue cleanup script"
