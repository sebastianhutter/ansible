#!/bin/bash

# stops all services and umounts all nfs mounts

systemctl stop sabnzbd2
systemctl stop sonarr
systemctl stop couchpotato2
systemctl stop squid
systemctl stop calibre-david
systemctl stop calibre-privat
systemctl stop nginx
systemctl stop openvpnas

# umount all nfs
umount /mnt/docker 
umount /mnt/library 
umount /mnt/calibre 
umount /mnt/backup 
umount /mnt/web 