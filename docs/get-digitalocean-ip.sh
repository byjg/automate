#!/bin/bash

# -----------------------------------------------------
# To get the token access the address:
# https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2
# -----------------------------------------------------
TOKEN="--MY AUTHORIZATION--"
SERVER_PATTERN="--YOUR SERVER PATTERN--"


# -- YOU DO NOT NEED CHANGE BELOW HERE

curl -X GET \
	-H 'Content-Type: application/json' \
	-H "Authorization: Bearer $TOKEN" \
	"https://api.digitalocean.com/v2/droplets?page=1&per_page=20" > /tmp/droplets.txt 2> /dev/null

cat /tmp/droplets.txt \ 
	| jq -c '.droplets[] | {"name": .name, "id": .id, "ip": .networks .v4[0] .ip_address}' \ 
	| grep $SERVER_PATTERN > /tmp/temp_ip.txt

rm IPs

for ip in `cat /tmp/temp_ip.txt | jq -r '.ip'`
do 
	echo "$ip" >> IPs
done

