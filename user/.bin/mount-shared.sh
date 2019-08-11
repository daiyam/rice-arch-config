#!/bin/sh

sudo mkdir -p /mnt/shared

sudo mount -t vboxsf -o uid=$UID,gid=$(id -g) shared /mnt/shared/
