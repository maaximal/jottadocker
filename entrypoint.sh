#!/bin/bash
set -e

apt-get update
apt-get upgrade -y
#jotta-cli ignores set '/root/ignorelist'
jottad $@
