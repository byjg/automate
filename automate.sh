#!/usr/bin/env bash
#
# Automate ByJG
############################################################

echo "----------------------------------------------"
echo "Automate ByJG v1.1.1"
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

PLUGIN=$WORKDIR/${1%.*}.plugin
EXECID=$2
EXTRA1=$3
EXTRA2=$4
EXTRA3=$5

# Check if Plugin was passed
if [ -z "$1" ] || [ ! -r $PLUGIN ]
then
    echo "Usage:"
    echo "   automate PLUGIN-NAME [server-number] [extra1] [extra2] [extra3]"
    echo
    echo "Where:"
    echo "   server-number: The number of the server in the IPs file, or 'ALL' (default)"
    echo "   extra-n: Extra arguments passed to the plugin script named EXTRA1, EXTRA2 and EXTRA3"
    echo
    echo "Available Scripts:"
    for lista in `ls $WORKDIR/*.plugin`; do
        pluginame=${lista%.*}
        echo "   ${pluginame##*/}: "`cat $lista | grep '#PLUGIN' | cut -b 9-`
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
    FULLSERVER=`echo $LINE | cut -f1 -d ':'`
    PORT=`echo $LINE | awk -F':' '{ print $2 }'`
    if [ -z "$PORT" ]
    then
        PORT=22
    fi
    USER=`echo $FULLSERVER | cut -f1 -d '@'`
    if [ ! -z "$USER" ]
    then
        SERVER=`echo $FULLSERVER | cut -f2 -d '@'`
    fi

    # Execute PLUGIN
    echo 
    echo "Running Server: " `grep $LINE ${WORKDIR}/IPs`
    echo 
    echo "#!/bin/bash"         >  /tmp/automatetmp
    echo "ID='`grep $LINE ${WORKDIR}/IPs`'" >> /tmp/automatetmp
    echo "USER='$USER'"        >> /tmp/automatetmp
    echo "SERVER='$SERVER'"    >> /tmp/automatetmp
    echo "PORT='$PORT'"        >> /tmp/automatetmp
    echo "EXTRA1='$EXTRA1'"    >> /tmp/automatetmp
    echo "EXTRA2='$EXTRA2'"    >> /tmp/automatetmp
    echo "EXTRA3='$EXTRA3'"    >> /tmp/automatetmp
    cat $PLUGIN                >> /tmp/automatetmp
    chmod a+x /tmp/automatetmp

    scp -q /tmp/automatetmp $FULLSERVER:/tmp/automatesrv && \
    ssh $FULLSERVER /tmp/automatesrv

    echo 
    echo "--"

done

