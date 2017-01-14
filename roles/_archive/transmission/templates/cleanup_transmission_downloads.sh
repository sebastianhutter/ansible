#!/bin/bash

# this scripts deletes old downloads in the transmission downloads directories

logger -t "cleantransmission" "starting transmission cleanup script"
# check if the download directory exist
if [ -d "{{ transmissionroot }}/downloads" ]; then
  # delete files older then 2 days in the download subdirectories
  logger -t "cleantransmission" "check {{ transmissionroot }}/downloads for downloads older 7 days minutes"
  find "{{ transmissionroot }}/downloads" -mindepth 2 -mtime +7  -delete -exec logger -t "cleantransmission" delete {} \;
fi
logger -t "cleantransmission" "finished transmission cleanup script"
