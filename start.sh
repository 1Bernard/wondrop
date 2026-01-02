#!/bin/bash

# Function to get local IP
get_local_ip() {
    # Try looking for a common Wi-Fi interface first (Mac/Linux)
    ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | grep -v '172.' | awk '{print $2}' | head -n 1)
    
    # Fallback/alternative methods
    if [ -z "$ip" ]; then
        # Mac specific
        ip=$(ipconfig getifaddr en0 2>/dev/null)
    fi

    if [ -z "$ip" ]; then
        echo "localhost"
    else
        echo "$ip"
    fi
}

HOST_IP=$(get_local_ip)

echo "🚀 Starting Wondrop..."
echo "📱 Detected LAN IP: $HOST_IP"
echo "👉 After startup, access the app at: http://$HOST_IP:4000"
echo ""

# Export variable for docker-compose
export HOST_IP=$HOST_IP

# Run docker-compose
docker-compose up --build
