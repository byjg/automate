#!/bin/bash

# -----------------------------------------------------
# Plese run "aws configure" in order to get this script working
# -----------------------------------------------------

echo Reading from amazon

RESULT=$( \
    aws ec2 describe-instances --filters "Name=tag:Name,Name=instance-state-name,Values=running" \
    | jq -r '.Reservations[].Instances[] | (.Tags[]//[]|select(.Key=="Name")|.Value), (.InstanceId), (.PrivateIpAddress), (.PublicIpAddress)' \
)

rm IPs

echo Parsing results

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
