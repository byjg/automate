#!/usr/bin/env bash
#
# Automate ByJG
############################################################

header() {
    echo "----------------------------------------------"
    echo "Automate ByJG v2.0.2"
    echo "Automate run scripts in a multiple servers"
    echo "----------------------------------------------"
    echo
}


automate() {
    EXECID=$1
    EXTRA1=$2
    EXTRA2=$3
    EXTRA3=$4

    # EXTRACT THE IPs
    ID=1
    TARGET_SERVER=()
    while read LINE
    do
        LINEAR=($LINE)

        if [[ $LINE != ";"* ]]
        then
           ( [ -z "$EXECID" ] || [ "$EXECID" = "ALL" ] || [ "$EXECID" = "$ID" ] || [[ "$LINE" == *"$EXECID"* ]] ) && \
           TARGET_SERVER+=(${LINEAR[0]})
        fi

        ID=`expr $ID + 1`
    done <${WORKDIR}/IPs;


    # Execute
    for LINE in ${TARGET_SERVER[@]}
    do
        # Get Server NAME and PORT
        REMOTESERVER=`echo $LINE | cut -f1 -d ':'`
        PORT=`echo $LINE | awk -F':' '{ print $2 }'`
        if [ -z "$PORT" ]
        then
            PORT=22
        fi
        USER=`echo $REMOTESERVER | cut -f1 -d '@'`
        if [ ! -z "$USER" ]
        then
            SERVER=`echo $REMOTESERVER | cut -f2 -d '@'`
        fi

        COPYBEFORE=`cat ${RECIPE} | grep -i "#COPY-BEFORE" | cut -c14-`
        if [ -z "$COPYBEFORE" ]; then
            COPYBEFORE="echo"
        else
            COPYBEFORE="echo 'Copying files...' && scp $COPYBEFORE && echo 'End copy' && echo"
        fi

        COPYAFTER=`cat ${RECIPE} | grep -i "#COPY-AFTER" | cut -c13-`
        if [ -z "$COPYAFTER" ]; then
            COPYAFTER="echo"
        else
            COPYAFTER="echo && echo 'Copying files...' && scp $COPYAFTER && echo 'End copy'"
        fi

        SSHARGS=`cat ${RECIPE} | grep -i "#SSH-ARGS" | cut -c11-`
        SSHKEY=`cat ${RECIPE} | grep -i "#SSH-KEY" | cut -c10-`
        if [ ! -z "$SSHKEY" ]; then
            SSHKEY="-i $SSHKEY"
        fi

        ID=`grep $LINE ${WORKDIR}/IPs | cut -d" " -f2- | tr -d '[:space:]'`

        echo
        ONLYIFMATCH=`cat ${RECIPE} | grep -i "#ONLY-IF-MATCH" | cut -c16-`
        if [ -z "$ONLYIFMATCH" ]; then
            ONLYIFMATCH="$ID"
        fi
        if [[ "$ID" == *"$ONLYIFMATCH"* ]]; then
            echo "Running Server: " `grep $LINE ${WORKDIR}/IPs`
        else
            echo "Skipping Server: " `grep $LINE ${WORKDIR}/IPs`
            echo
            continue
        fi
        echo

        # Execute RECIPE
        echo
        echo "#!/bin/bash"         >  /tmp/automatetmp
        echo "ID='$ID'" >> /tmp/automatetmp
        echo "REMOTESERVER='$REMOTESERVER'"        >> /tmp/automatetmp
        echo "USER='$USER'"        >> /tmp/automatetmp
        echo "SERVER='$SERVER'"    >> /tmp/automatetmp
        echo "PORT='$PORT'"        >> /tmp/automatetmp
        echo "EXTRA1='$EXTRA1'"    >> /tmp/automatetmp
        echo "EXTRA2='$EXTRA2'"    >> /tmp/automatetmp
        echo "EXTRA3='$EXTRA3'"    >> /tmp/automatetmp
        cat ${RECIPE}              >> /tmp/automatetmp
        chmod a+x /tmp/automatetmp

        eval ${COPYBEFORE} \
          && scp ${SSHKEY} -q /tmp/automatetmp ${REMOTESERVER}:/tmp/automatesrv \
          && ssh ${SSHKEY} ${SSHARGS} ${REMOTESERVER} /tmp/automatesrv \
          && eval ${COPYAFTER}

        echo
        echo "--"

    done
}

getAwsIp() {
    echo Reading from amazon

    RESULT=$( \
        aws ec2 describe-instances --filters "Name=tag:Name,Name=instance-state-name,Values=running" \
        | jq -r '.Reservations[].Instances[] | (.Tags[]//[]|select(.Key=="Name")|.Value), (.InstanceId), (.PrivateIpAddress), (.PublicIpAddress)' \
    )

    RETCODE=$?
    if [ $RETCODE -ne 0 ]; then
        echo "An error occured. Did you run: 'aws configure' and have the library 'jq' installed? "
        exit $RETCODE
    fi

    echo Parsing results
    rm IPs
    for LINE in $RESULT; do
        if [ -z "$NAME" ]; then
            NAME="$LINE"
        elif [ -z "$INSTANCE" ]; then
            INSTANCE="$LINE"
        elif [ -z "$PRIVATEIP" ]; then
            PRIVATEIP="$LINE"
        elif [ -z "$PUBLICIP" ]; then
            PUBLICIP="$LINE"
        else
            echo "ubuntu@$PUBLICIP public-$NAME $INSTANCE  "  >> IPs
            echo "ubuntu@$PRIVATEIP private-$NAME $INSTANCE"  >> IPs
            NAME="$LINE"
            INSTANCE=""
            PRIVATEIP=""
            PUBLICIP=""
        fi
    done
    echo "ubuntu@$PUBLICIP public-$NAME $INSTANCE  "  >> IPs
    echo "ubuntu@$PRIVATEIP private-$NAME $INSTANCE"  >> IPs
    exit
}

getDigitalOceanIp() {

    exit
}

##################################################################
#
# AUTOMATE
#
##################################################################

# ---
WORKDIR="${AUTOMATE_WORKDIR}"
if [ -z "$WORKDIR" ]
then
    WORKDIR="."
fi

# --- Check if get aws ip
if [ "$1" == "get-aws-ip" ]; then
    header
    getAwsIp
fi

# --- Check if get aws ip
if [ "$1" == "get-digitalocean-ip" ]; then
    header
    getDigitalOceanIp
fi

# ---
if [ ! -f "${WORKDIR}/IPs" ]
then
    header
    echo "You need to create a file called 'IPs' with the server names and IPs of the server you want to execute "
    echo
    exit 1;
fi

RECIPE=$WORKDIR/${1%.*}.recipe

# Check if Plugin was passed
if [ -z "$1" ] || [ ! -r $RECIPE ]
then
    header
    echo "Usage:"
    echo "   automate RECIPE-NAME [server-number] [extra1] [extra2] [extra3]"
    echo "   automate get-aws-ip"
    echo "   automate get-digitalocean-ip"
    echo
    echo "Where:"
    echo "   server-number: The number of the server in the IPs file, or 'ALL' (default)"
    echo "   extra-n: Extra arguments passed to the recipe script named EXTRA1, EXTRA2 and EXTRA3"
    echo
    echo "Available Recipes:"
    for lista in `ls $WORKDIR/*.recipe`; do
        recipename=${lista%.*}
        echo "   ${recipename##*/}: "`cat $lista | grep -i '#RECIPE' | cut -b 9-`
    done
    echo
    exit
fi

automate $2 $3 $4 $5
