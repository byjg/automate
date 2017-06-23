#!/usr/bin/env bash
#
# Automate ByJG
############################################################

echo "----------------------------------------------"
echo "Automate ByJG v2.0.0"
echo "Automate run scripts in a multiple servers"
echo "----------------------------------------------"
echo 

# ---
WORKDIR="${AUTOMATE_WORKDIR}"
if [ -z "$WORKDIR" ]
then
    WORKDIR="."
fi

# ---
if [ ! -f "${WORKDIR}/IPs" ]
then
    echo "You need to create a file called 'IPs' with the server names and IPs of the server you want to execute "
    echo
    exit 1;
fi

RECIPE=$WORKDIR/${1%.*}.recipe
EXECID=$2
EXTRA1=$3
EXTRA2=$4
EXTRA3=$5

# Check if Plugin was passed
if [ -z "$1" ] || [ ! -r $RECIPE ]
then
    echo "Usage:"
    echo "   automate RECIPE-NAME [server-number] [extra1] [extra2] [extra3]"
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
      && scp -q /tmp/automatetmp ${REMOTESERVER}:/tmp/automatesrv \
      && ssh ${REMOTESERVER} /tmp/automatesrv \
      && eval ${COPYAFTER}

    echo 
    echo "--"

done

