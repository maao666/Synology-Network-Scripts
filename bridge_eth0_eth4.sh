#!/bin/bash

# Function to remove a port from its current bridge
remove_from_bridge() {
    local port=$1
    local current_bridge=$(sudo ovs-vsctl port-to-br $port)
    if [ -n "$current_bridge" ]; then
        echo "$port is already in bridge $current_bridge, removing it..."
        sudo ovs-vsctl del-port $current_bridge $port
    fi
}

# Check if eth4 is present
if ip link show eth4 >/dev/null 2>&1; then
    echo "eth4 found, creating bridge between eth4 and eth0..."

    # Remove eth4 from its current bridge
    remove_from_bridge eth4

    # Create a bridge named "br_eth4_eth0"
    sudo ovs-vsctl add-br br_eth4_eth0

    # Add eth4 to the bridge
    sudo ovs-vsctl add-port br_eth4_eth0 eth4

    # Remove eth0 from its current bridge
    remove_from_bridge eth0

    # Add eth0 to the bridge
    sudo ovs-vsctl add-port br_eth4_eth0 eth0

    echo "Bridge between eth4 and eth0 created successfully."
else
    echo "eth4 not found, no action needed."
fi

