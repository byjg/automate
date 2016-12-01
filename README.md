# Automate ByJG 1.1.1

Native bash script for running scripts across a multiple servers

## How it works?

Automate run scripts called "plugins" across a multiple servers. 
Each plugin is created in your local machine and the it is spreaded to all the servers. 

### Install

The first step is to install 'automate.sh' 

```
curl -sS https://raw.githubusercontent.com/byjg/automate/master/automate.sh > /usr/local/bin/automate
chmod a+x /usr/local/bin/automate
```

### Define the servers list

Once installed the 'automate' you need to create the 'IPs' file with a list of all servers you want to automate. 

```
10.10.1.1:2200   COMMENTS OR GROUP
10.10.1.2   MORE COMMENTS OR GROUP
;10.10.1.3
ubuntu@10.10.1.4 
server.name.com:1100
```

Comments start with a ';'. This file cannot have white spaces. The comments after the server are ignored. 
They can be used as filter 

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

### Running a specific line in the IPs file

```bash
automate showip 3
```

### Running a specific line matching with the comment in the file

```bash
automate showip GROUP
```

### Running ALL servers and passing EXTRA parameters

```bash
automate showip ALL extra1 extra2
```

### Setting up environment variable

Automate by default locate the "*.plugin" files at your current directory. You can specify a directory by setting up the
environment variable `AUTOMATE_WORKDIR` like this:

```
AUTOMATE_WORKDIR=/opt/plugindir
```

