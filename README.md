# Automate ByJG 2.0.0

Native bash script for running scripts across a multiple servers

## How it works?

Automate run scripts called "recipes" across a multiple servers. 
Each recipe is created in your local machine and the it is spreaded to all the servers. 

### Install

The first step is to install 'automate.sh' 

```
curl -sS https://raw.githubusercontent.com/byjg/automate/master/automate.sh > /usr/local/bin/automate
chmod a+x /usr/local/bin/automate
```

### Define the servers list

Once installed the 'automate' you need to create the 'IPs' file with a list of all servers you want to automate. 

```
10.10.1.1:2200        connection-name
10.10.1.2             other-name
;10.10.1.3            commented
ubuntu@10.10.1.4      with-user-name
server.name.com:1100  with-port

```

Comments start with a ';'. This file cannot have white spaces. The comments after the server are ignored. 
They can be used as filter 

### Create your first RECIPE

A recipe is a regular bash script with the extension ".recipe". This file must reside inside your current folder
alongside with the IPs file.

See below an example of the a recipe file called 'showip.recipe':

```bash
#RECIPE Show the IP server is currently running and the current ubuntu version

echo "$ID: $USER $SERVER $PORT"
lsb_release --all
```

Note that the first line is nice to have the comment '#RECIPE' at the very first line. This will be showed when listing all
recipes. 

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

where 'showip' is the name of the recipe.

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

Automate by default locate the "*.recipe" files at your current directory. You can specify a directory by setting up the
environment variable `AUTOMATE_WORKDIR` like this:

```
AUTOMATE_WORKDIR=/opt/recipedir
```

