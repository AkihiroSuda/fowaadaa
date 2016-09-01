#!/bin/sh
# exit on an error
set -e
cat /banner

if [ x$PUBKEY = x ]; then
    echo 'ERROR: $PUBKEY is not set!'
    echo 'Example: docker run -e PUBKEY="$(cat ~/.ssh/id_rsa.pub)" ..'
    exit 1
fi
echo "$PUBKEY" > /tmp/PUBKEY

if ssh-keygen -l -f /tmp/PUBKEY; then
    echo 'Registering $PUBKEY (OpenSSH format) to /root/.ssh/authorized_keys'
    cp /tmp/PUBKEY /root/.ssh/authorized_keys
elif grep "BEGIN SSH2 PUBLIC KEY" /tmp/PUBKEY; then
    echo 'Registering $PUBKEY (RFC4716 format) to /root/.ssh/authorized_keys'
    ssh-keygen -i -f /tmp/PUBKEY > /root/.ssh/authorized_keys
else
    echo 'ERROR: bad $PUBKEY format (must be OpenSSH for RFC4716)'
    exit 1
fi

chmod 600 /root/.ssh/authorized_keys
rm -f /tmp/PUBKEY

echo "Generating host keys"
ssh-keygen -A

echo "Starting OpenSSH server"
/usr/sbin/sshd -D
