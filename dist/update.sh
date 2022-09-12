#!/bin/ash

# Let's ensure normal operation on exit or if interrupted ...
function fuCLEANUP {
  exit 0
}
trap fuCLEANUP EXIT

### Vars
myOINKCODE="$1"

# Check internet availability 
function fuCHECKINET () {
mySITES=$1
error=0
for i in $mySITES;
  do
    curl --connect-timeout 5 -Is $i 2>&1 > /dev/null
      if [ $? -ne 0 ];
        then
	  let error+=1
      fi;
  done;
  echo $error
}

# Check for connectivity and download rules
myCHECK=$(fuCHECKINET "rules.emergingthreatspro.com rules.emergingthreats.net")
if [ "$myCHECK" == "0" ];
  then
    if [ "$myOINKCODE" != "" ] && [ "$myOINKCODE" != "OPEN" ];
      then
        suricata-update -q enable-source et/pro secret-code=$myOINKCODE > /dev/null
      else
        # suricata-update uses et/open ruleset by default if not configured
        rm -f /var/lib/suricata/update/sources/et-pro.yaml 2>&1 > /dev/null
    fi
    suricata-update -q --no-test --no-reload > /dev/null
    echo "/etc/suricata/capture-filter.bpf"
  else
    echo "/etc/suricata/null.bpf"
fi

# Download rules via URL
if [ "$FROMURL" != "" ] ; then
    SAVEIFS=$IFS ; IFS='|'
    for URL in $FROMURL; do
        if [ $(curl -I --silent --output /dev/null --write-out "%{http_code}" "$URL") -eq 200 ] ; then
           rm -rf /tmp/*
           curl "$URL" -o /tmp/rules.tar.gz
           tar -xvf /tmp/rules.tar.gz -C /tmp
           suricata-update --local /tmp/rules --no-test
           rm -rf /tmp/*
        else
          continue
        fi
    done
    IFS=$SAVEIFS
fi
