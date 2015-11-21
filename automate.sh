#/bin/bash
#
# Automate ByJG
############################################################

echo "-----------------------------------------"
echo "Automate ByJG"
echo "Automate tasks in a multiple servers"
echo "-----------------------------------------"
echo 

if [ ! -f "IPs" ]
then
	echo "You need to create a file called 'IPs' with the server names and IPs of the server you want to execute "
	echo
	exit 1;
fi


TARGET_SERVERS=`cat IPs`
PLUGIN=`echo $1 | cut -d. -f1`".plugin"
EXECID=$2
EXTRA1=$3
EXTRA2=$4
EXTRA3=$5

if [ ! -r $PLUGIN ]
then
	echo "Usage:"
	echo "   automate PLUGIN-NAME [server-number] [extra1] [extra2] [extra3]"
	echo
	echo "Where:"
	echo "   server-number: The number of the server in the IPs file, or 'ALL' (default)"
	echo "   extra-n: Extra arguments passed to the plugin script named EXTRA1, EXTRA2 and EXTRA3"
	echo
	echo "Available Scripts:"
	for lista in `ls *.plugin`; do
		pluginame=`echo $lista | cut -d. -f1`
		echo "   $pluginame: "`cat $lista | grep '#PLUGIN' | cut -b 9-`
	done
	echo
	exit
fi

ID=1
for LINE in $TARGET_SERVERS
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

	# Execute PLUGIN or Ignore it if is commentted
	echo 
	echo "Running Server $ID: $LINE"
	echo 
	if [[ $LINE != ";"* ]]
	then
		echo "#!/bin/bash"      >  /tmp/automatetmp
		echo "ID='$ID'"         >> /tmp/automatetmp
		echo "USER='$USER'"     >> /tmp/automatetmp
		echo "SERVER='$SERVER'" >> /tmp/automatetmp
		echo "PORT='$PORT'"     >> /tmp/automatetmp
		echo "EXTRA1='$EXTRA1'" >> /tmp/automatetmp
		echo "EXTRA2='$EXTRA2'" >> /tmp/automatetmp
		echo "EXTRA3='$EXTRA3'" >> /tmp/automatetmp
		cat $PLUGIN             >> /tmp/automatetmp
		chmod a+x /tmp/automatetmp

		( [ -z "$EXECID" ] || [ "$EXECID" = "ALL" ] || [ "$EXECID" = "$ID" ] ) && \
		scp -q /tmp/automatetmp $FULLSERVER:/tmp/automatesrv && \
		ssh $FULLSERVER /tmp/automatesrv || \
		echo "Not executed."

	else
		echo "Ignored."
	fi
	echo "--"

	# Increment Server ID
	ID=`expr $ID + 1`
done;

