#!/bin/bash

WHEREAMI=$(readlink -f $0)
PROGNAME=${WHEREAMI##*/}

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'

IP_CACHE=${WHEREAMI%/*}/cache/lastip.txt
SDWAN="$1"; shift
API_ENDPOINT="$1"

WIQ_USER=''
WIQ_PASSWORD=''

Usage () {
    cat >&2 <<- EOF

usage: $PROGNAME HOST_ADDRESS API_ENDPOINT

Enter the api-endpoint and optional host address.

EOF
exit 1
}

Error () {
    echo -e "-${PROGNAME%.*} error: $1\n" > /dev/stderr
    exit 1
}

set_ip_addr () {
    if [ "$SDWAN" ]; then
        make_cookie_cache
    elif [ -f "$IP_CACHE" ]; then
        load_from_cache
    else
        Error 'no route to host'
    fi
}

make_cookie_cache () {
    SDWAN="https://$SDWAN:45451/zm/api"
    ARGUMENTS="user=$WIQ_USER&pass=$WIQ_PASSWORD!&stateful=1"
    if ! curl -s -k -XPOST -c $IP_CACHE -d "$ARGUMENTS" "$SDWAN/host/login.json"; then
        Error "failed to create cookie cache"
    fi
}

load_from_cache () {
    if [ ! -r "$IP_CACHE" ]; then
        Error "no cookie please provide a host address"
    fi
    SDWAN="https://$(cat $IP_CACHE):45451/zm/api"
}

curl_api_call () {
    if ! $sh_c "curl -s -k -b $IP_CACHE -XGET $SDWAN/$API_ENDPOINT.json"; then
        Error "Failed to curl: $API_ENDPOINT"
    fi
}

set_ip_addr
curl_api_call
rm $IP_CACHE

