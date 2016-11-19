#!/bin/bash

# starts all services and mounts all nfs mounts

# mount all nfs
mount /mnt/docker 
mount /mnt/library 
mount /mnt/calibre 
mount /mnt/backup 
mount /mnt/web 

systemctl start sabnzbd2
systemctl start sonarr
systemctl start couchpotato2
systemctl start squid
systemctl start calibre-david
systemctl start calibre-privat
systemctl start nginx
systemctl start openvpnas

