#!/bin/bash

#
# replace old letsencrypt certificates
#

function log {
    level=$1
    shift
    message=$@
    echo "$(date) synology_certificates.sh - ${level}: ${message}"
}
function warn {
    echo $(log WARN $@)
}
function info {
    echo $(log INFO $@)
}
function error {
    echo $(log ERROR $@) 1>&2
    exit 1
}

function get_date_before {
    # get Not Before date from the fullchain.pem certificate in the specified directory
    local cert_date=$(openssl x509 -in ${1} -text -noout 2>/dev/null | awk '/Not Before/ {$1=$2=""; print $0}')
    # openssl does not seem to care about return values.
    # so if cert_date contains 'Error' we abort
    if [ -n "${cert_date}" ]; then
        echo $(date --date="${cert_date}" +"%s")
    fi
}

function get_date_after {
    # get Not Before date from the fullchain.pem certificate in the specified directory
    local cert_date=$(openssl x509 -in ${1} -text -noout 2>/dev/null | awk '/Not After/ {$1=$2=$3=""; print $0}')
    # openssl does not seem to care about return values.
    # so if cert_date contains 'Error' we abort
    if [ -n "${cert_date}" ]; then
        echo $(date --date="${cert_date}" +"%s")
    fi
}


#
# main
#

info "Running Script"

# if we are running as root start with the setup process
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
fi

# lets add the path to the certificates to replace
# and specify the services which nid restarting
declare -A certificates

certificates=(
    ["/usr/syno/etc/certificate/smbftpd/ftpd"]="ftpd ftpd-ssl" #root:root
    ["/usr/syno/etc/certificate/system/default"]="pkgctl-Apache2.2 pkgctl-WebStation nginx DSM" #root:root
    ["/usr/local/etc/certificate/HyperBackupVault/HyperBackupVault"]="pkgctl-HyperBackupVault" #root:root
    ["/usr/local/etc/certificate/CloudStation/CloudStationServer"]="pkgctl-CloudStation" #CloudStation:CloudStation
    ["/usr/local/etc/certificate/DirectoryServer/slapd"]="pkgctl-DirectoryServer" #root:root
)

# the path to the new certificate which may replace the certificates above is speficied as the first 
# parameter
new_certificate_path="$1"
[ -z "${new_certificate_path}" ] && error "please specify path to new certificate"
new_fullchain="${new_certificate_path}/fullchain.pem"
new_privkey="${new_certificate_path}/privkey.pem"

# first check if the new certificate exists
[ ! -f "${new_fullchain}" ] && error "unable to locate '${new_fullchain}'" 
[ ! -f "${new_privkey}" ] && error "unable to locate '${new_privkey}'" 

# now lets get the current system time as timestamp
current_systemtime=$(date +"%s")

# and now get the dates from the new certificate
new_before=$(get_date_before ${new_fullchain})
new_after=$(get_date_after ${new_fullchain})
[ -z "${new_before}" ] && error "unable to retrieve Not Before date from new fullchain.pem"
[ -z "${new_after}" ] && error "unable to retrieve Not After date from new fullchain.pem"

# if the current system timestamp is smaller then the certificates timestamp
# it is not valid yet and we will stop the process
if [ "${current_systemtime}" -lt "${new_before}" ]; then
    info "new certificate is not yet valid."
    exit 0
fi

# lets loop trough all specified certificates
for c in "${!certificates[@]}"; do 
    info "checking certificates in '${c}'"
    cert_fullchain="${c}/fullchain.pem"
    cert_cert="${c}/cert.pem"
    cert_privkey="${c}/privkey.pem"

    [ ! -f "${cert_fullchain}" ] && warn "unable to locate fullchain.pem." && continue
    [ ! -f "${cert_cert}" ] && warn "unable to locate cert.pem." && continue
    [ ! -f "${cert_privkey}" ] && warn "unable to locate privkey.pem" && continue

    cert_before=$(get_date_before ${cert_fullchain})
    [ -z "${cert_before}" ] && warn "unable to retrieve Not Before date" && continue

    # if the the before timestamp is equal to the before timestamp of the new
    # certificate we dont have to do a thing
    if [ "${cert_before}" -eq "${new_before}" ]; then
        info "certificate is already in place. doing nothing"
        continue
    fi
 
    # if the timestamp is bigger then the new timestamp we dont have to do anything
    if [ "${cert_before}" -gt "${new_before}" ]; then
        info "current certificate is newer then new one. doing nothing"
        continue
    fi

    info "current certificate is older then new certificate. replacing it"
    cp -f "${cert_fullchain}" "${cert_fullchain}.bak"
    cp -f "${cert_cert}" "${cert_cert}.bak"
    cp -f "${cert_privkey}" "${cert_privkey}.bak"
    cp -f "${new_fullchain}" "${cert_fullchain}"
    cp -f "${new_fullchain}" "${cert_cert}"
    cp -f "${new_privkey}" "${cert_privkey}"

    info "set ownership of certificates"
    if [ "$(basename ${c})" == "CloudStationServer" ]; then
        chown CloudStation:CloudStation "${cert_fullchain}" "${cert_cert}" "${cert_privkey}"
    else
        chown root:root "${cert_fullchain}" "${cert_cert}" "${cert_privkey}"
    fi
    chmod 400 "${cert_fullchain}" "${cert_cert}" "${cert_privkey}"

    # with the certificate replaced, lets restart the services
    info "restarting services used by certificate"
    for s in ${certificates[$c]}; do
        info "stop service '${s}'"
        synoservicectl --hard-stop ${s}
    done

    for s in ${certificates[$c]}; do
        info "start service '${s}'"
        synoservicectl --hard-start ${s}
    done

done

info "Finish Script"


