#!/usr/bin/bash
sudo service ssh start

if [ ! -f ~/.makCluster ]
then
    touch ~/.makCluster;
fi
tail -f /dev/null
