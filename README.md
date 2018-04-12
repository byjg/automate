# Automate ByJG 2.0.0

A *very* simple script management for automate tasks and run scripts (recipes)
across a multiple servers

## How it works?

Automate run scripts called "recipes" across a multiple servers. 
Each recipe is created in your local machine and the it is spreaded to all the servers.

## Why this is better than ansible, chef and others?

The answer is not "BETTER THAN SOMETHING" but "DIFFERENT WAY TO DO THINGS".
Ansible and Chef have your own syntax. You have to learn it. 
Automate just use BASH SCRIPT and there is no other commands. 

During this document we'll highlighting the differences and similarity with the ansible and chef. 

## Install

The first step is to install 'automate.sh' 

```
curl -sS https://raw.githubusercontent.com/byjg/automate/master/automate.sh | sudo tee /usr/local/bin/automate > /dev/null
sudo chmod a+x /usr/local/bin/automate
```

## Define the servers list

Once installed the 'automate' you need to create the 'IPs' file with a list of all servers you want to automate.
 
Each line must have on IP following the format below:

```
[username@]IP[:PORT]   THE-SERVER-NAME-WITHOUT-SPACE
```

Example:

```
10.10.1.1:2200        connection-name
10.10.1.2             other-name
;10.10.1.3            commented
ubuntu@10.10.1.4      with-user-name
server.name.com:1100  with-port

```

Comments starts with a ';'. This file cannot have white spaces. The comments after the server are ignored. 
They can be used as filter

It is important named carefully because you can filter the execution by this name.

#### Note for Ansible Users

Ansible have the inventory and groups of servers. 

For example, the ansible inventory is:

```
[webservers]
www1.example.com
www2.example.com

[dbservers]
db0.example.com
db1.example.com
```

and the AUTOMATE IPs list is:

```
www1.example.com    webservers
www2.example.com    webservers
db0.example.com     dbservers
db1.example.com     dbservers
```

In fact automate comments is more flexible when we want to mix
different groups. For example, imagine we have webservers and dbservers for
homolog and live systems? Using automate we could do it:

```
www1.example.com    live-webservers
www2.example.com    test-webservers
db0.example.com     live-dbservers
db1.example.com     test-dbservers
```

and we could call the recipe like:

```
automate recipe live
automate recipe webservers
```

## Create your first RECIPE

A recipe is a regular bash script with the extension ".recipe". This file must reside inside your current folder
alongside with the IPs file.

See below an example of the a recipe file called 'showip.recipe':

```bash
#RECIPE Show the IP server is currently running and the current ubuntu version

echo "$ID: $USER $SERVER $PORT"
lsb_release --all
```

Note that the line started with "#RECIPE" is a comment of your recipe.

Each script also have five pre-defined variable:
* $ID: The server ID is the position of the server in the IPs file.
* $USER: The ssh username
* $SERVER: The server address
* $PORT: The SSH server port
* $EXTRA1: The extra parameter 1
* $EXTRA2: The extra parameter 2
* $EXTRA3: The extra parameter 3

#### Note for Ansible Users

The Automate Recipe looks like to a Ansible Playbook. Ansible Playbook are a YAML file and are more rich 
with a lot of useful plugins. Some functions like start a service, notify commands, etc are well defined. 
As stated in the ansible documentation: "Reading an ansible playbook is easy". Automate recipes are just scripts. 
Do what you scripted. There is no magic.

## RECIPE commands

The recipe is PURE bash with some comments and environment variables pre-defined.

The commands are:

### #RECIPE comment

It is used only for document your recipe. The syntax is:

```
#RECIPE This is the comment

(Your recipe here)
```

### #COPY-BEFORE local remote

Copy-Before will copy a file or directory using "scp" **before** start the recipe. Use the variable 
$REMOTESERVER to define the remote server. 

```
#COPY-BEFORE locafile $REMOTESERVER:remotepath
```

### #COPY-AFTER local remote

Copy-After will copy a file or directory using "scp" **after** the end of the recipe execution.

```
#COPY-AFTER $REMOTESERVER:remotefile localfile
```

### #ONLY-IF-MATCH string

This recipe only will be executed if the current server match with the string. 
This is ideal for avoid running scripts in other servers. 

### #SSH-ARGS arguments

Ssh-args will add extra arguments do the SSH command used to connect to the server.

```
#SSH-ARGS -t
```

### #SSH-KEY /path/to/key

Ssh-key will use the key provided as argument instead to use the system ssh-agent

```
#SSH-KEY ~/.ssh/id.rsa
```

### #TIMEOUT argument

Defines how much time (in seconds) the SSH will try to connect to the SSH server. 

```
#TIMEOUT 5
```

## Other options

### Auto-generate IP from AWS and Digital Ocean

If your servers are from AWS or Digital Ocean, automate 2.0.x can create the IPs file for you. 

#### Amazon EC2

Just type:

```
automate get-ip aws > IPs
```

It is necessary you have the [AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) 
installed and run the command `aws configure` in order the this working

#### Digital Ocean

Just type:

```
automate get-ip digitalocean > IPs
```

It is necessary you have the [Doctl](https://github.com/digitalocean/doctl)
installed and run the command `doctl auth init` in order the this working


## Running

To run just type:

```bash
automate showip
```

where 'showip' is the name of the recipe.

After each execution a file '/tmp/automate-result.txt' will be generated with each server as executed
and the exit status code. If the exit status code is '0' the execution was successfull. 

Example:

```text
server, status
10.10.1.1, 0
10.10.1.2, 0
ubuntu@10.10.1.4, 0
server.name.com, 255
```

### Running a specific line matching with the comment in the file

```bash
automate showip GROUP
```

### Running ALL servers and passing EXTRA parameters

```bash
automate showip ALL extra1 extra2
```

Inside the recipe you can use the extra parameters accessing the variables $EXTRA1 and $EXTRA2

### Setting up environment variable

Automate by default locate the "*.recipe" files at your current directory. You can specify a directory by setting up the
environment variable `AUTOMATE_WORKDIR` like this:

```
AUTOMATE_WORKDIR=/opt/recipedir
```

