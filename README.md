# Scripts for Synology Networking

## Ethernet-Fallback-Monitor

Monitors if a port fails. If so, enable another one as fallback.

This is usually used for dynamically enabling a 1GbE port when a faster port (such as 2.5GbE) one fails.

## Synology-Bridging

This script enables you to create a network bridge between two Ethernet ports on your Synology NAS.

### Usage
vswitch_bridge.sh start
