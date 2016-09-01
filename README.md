# Fowaadaa: Docker image solely for SSH port forwarding (**No command shell**)

Fowaadaa provides SSH port forwarding service for Docker containers.

[No command shell](https://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/), no SCP, nor SFTP.

The image is available at Docker Hub: [akihirosuda/fowaadaa](https://hub.docker.com/r/akihirosuda/fowaadaa/).

    $ docker run -e PUBKEY="$(cat ~/.ssh/id_rsa.pub)" akihirosuda/fowaadaa

## Example

                                    +-----------------------+
                                    |      Docker Swarm     |
    +--------+                      |        +-----+        |
    |(laptop)|----------------------|--------|nginx|        |
    +--------+                      |        +-----+        |
                                    +-----------------------+
                                   80       80


The problem is that you cannot easily authenticate clients.
Ideally you should use TLS for that, but setting it up properly is very difficult.
(google search: ["tls client authentication nginx"](https://www.google.com/search?q=tls%20client%20authentication%20nginx))


## Solution using Fowaadaa
 
                                    +-----------------------+
                                    |      Docker Swarm     |
    +--------+                      |  +--------+  +-----+  |
    |(laptop)|--SSH port forwading--|--|fowaadaa|--|nginx|  |
    +--------+                      |  +--------+  +-----+  |
                                    +-----------------------+
           10080                 10022 22          80


Fowaadaa provides a Dockerized SSH port fowarding service, which is simpler than TLS client auth.

 - [X] No need to generate extra secret files. You can reuse your existing `~/.ssh/id_rsa[.pub]`.
 - [X] No need to copy files to inside of the container. You just need to set just a single environment variable (`$PUBKEY`).
 - [X] No need to configure apps.

## Instructions

Initialize the Swarm cluster if you have not done yet.

    $ docker swarm init

Create an overlay network named `n1`.

    $ docker network create --driver overlay n1

Create a nginx service and connect it to `n1`.

    $ docker service create --name nginx --network n1 --replicas 3 nginx

Create a Fowaadaa service and connect it to `n1`.
You need to specify a valid public key string (OpenSSH format or RFC4716 format) as `PUBKEY`.

    $ docker service create --name fowaadaa --network n1 -e PUBKEY="$(cat ~/.ssh/id_rsa.pub)" -p 10022:22 akihirosuda/fowaadaa
	
Start forwarding:

    $ ssh -N -p 10022 -L 10080:nginx:80 root@DOCKERHOST
	$ w3m http://localhost:10080
	

Note that you cannot run any command via SSH:

    $ ssh -p 10022 root@DOCKERHOST
	Fowaadaa does not allow any command execution
    $ ssh -p 10022 root@DOCKERHOST uname -a
	Fowaadaa does not allow any command execution	
	Connection to localhost closed.
	$ scp -P 10022 root@DOCKERHOST:/banner /tmp
    Fowaadaa does not allow any command execution
    $ sftp -P 10022 root@DOCKERHOST
	subsystem request failed on channel 0
	Couldn't read packet: Connection reset by peer

