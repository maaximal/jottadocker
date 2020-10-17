#!/bin/bash
set -e

apt-get update
apt-get upgrade
#jotta-cli ignores set '/root/ignorelist'
jottad $@
