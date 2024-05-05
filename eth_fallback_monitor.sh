#!/bin/bash

# Set the delay between each network check (in seconds)
delay=15

# Set the delay after the script starts (in seconds)
startup_delay=45

# Set the logging mode (synology or print)
logging_mode="synology"

# Set the number of ping packets to send
ping_count=3

# Function to log messages
log_message() {
    message="$1"
    if [ "$logging_mode" == "synology" ]; then
        /usr/syno/bin/synologset1 sys info 0x11100000 "Fallback monitor: $message"
    else
        echo "$(date): $message"
    fi
}

# Function to get the default gateway IP
get_default_gateway() {
    ip route | awk '/default/ { print $3 }'
}

# Function to check network connectivity
check_network() {
    gateway=$(get_default_gateway)
    if ping -c "$ping_count" -W 1 "$gateway" >/dev/null 2>&1; then
        true
    else
        log_message "Gateway $gateway unreachable after $ping_count ping attempts"
        false
    fi
}

# Function to enable ovs_eth0
enable_ovs_eth0() {
    ip link set ovs_eth0 up
    log_message "ovs_eth0 is now enabled"
}

# Function to disable ovs_eth0
disable_ovs_eth0() {
    ip link set ovs_eth0 down
    log_message "ovs_eth0 is now disabled"
}

# Delay for 1 minute at the beginning
log_message "Script started. Waiting for $startup_delay seconds"
sleep "$startup_delay"

# Main loop
while true; do
    if check_network; then
        # Network is up
        if ip link show ovs_eth2 >/dev/null 2>&1; then
            # ovs_eth2 is present
            if ip link show ovs_eth0 | grep -q "state UP"; then
                # ovs_eth0 is up, disable it
                disable_ovs_eth0
            fi
        else
            log_message "ovs_eth2 is not present. Skipping ovs_eth0 disable"
        fi
    else
        # Network is down
        if ip link show ovs_eth0 | grep -q "state DOWN"; then
            # ovs_eth0 is down, enable it
            enable_ovs_eth0
            
            # Check if ovs_eth2 is up and network is reachable every 15 seconds
            while true; do
                if ip link show ovs_eth2 >/dev/null 2>&1 && check_network; then
                    log_message "ovs_eth2 is up and network is reachable. Disabling ovs_eth0"
                    disable_ovs_eth0
                    break
                else
                    log_message "ovs_eth2 is down or network is not reachable. Waiting for 15 seconds..."
                    sleep "$delay"
                fi
            done
        fi
    fi
    
    # Wait for the specified delay before the next check
    sleep "$delay"
done
