#!/bin/bash

# this scripts deletes old downloads in the sabnzbd download directory

logger -t "cleansabnzbd" "starting sabnzbd cleanup script"
# check if the download directory exist
if [ -d "{{ cleanupdir }}" ]; then
  # delete files older then 2 days in the download subdirectories
  logger -t "cleansabnzbd" "check {{ cleanupdir }} for downloads older then 7 days"
  find "{{ cleanupdir }}" -mindepth 1 -mtime +7 -delete -exec logger -t "cleansabnzbd" delete {} \;
fi
logger -t "cleansabnzbd" "finished sabnzbd cleanup script"
