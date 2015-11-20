# Automate ByJG

Native bash script for automate tasks in a multiple servers

## How it works?

Automate can you to run scripts called "plugin" across a multiple servers. 

### Install

The first step is to install 'automate.sh' 

```
curl -sS SERVER > /usr/local/bin/automate
```

### Define the servers list

Once installed the 'automate' you need to create the 'IPs' file with a list of all servers you want to automate. 

```
10.10.1.1:2200
10.10.1.2
;10.10.1.3
ubuntu@10.10.1.4
server.name.com:1100
```

Comments start with a ';'. This file cannot have white spaces.

### Create your first PLUGIN

A plugin is a regular bash script with the extension ".plugin". This file must reside inside your current folder
alongside with the IPs file.

See below an example of the a plugin file called 'showip.plugin':

```bash
#PLUGIN Show the IP server is currently running and the current ubuntu version

echo "$ID: $USER $SERVER $PORT"
lsb_release --all
```

Note that the first line is nice to have the comment '#PLUGIN' at the very first line. This will be showed when listing all
plugins. 

Each script also have five pre-defined variable:
* $ID: The server ID is the position of the server in the IPs file.
* $USER: The ssh username
* $SERVER: The server address
* $PORT: The SSH server port
* $EXTRA1: The extra parameter 1
* $EXTRA2: The extra parameter 2
* $EXTRA3: The extra parameter 3

### Running

To run just type:

```bash
automate showip
```

where 'showip' is the name of the plugin.


