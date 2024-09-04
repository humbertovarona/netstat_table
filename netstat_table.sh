#!/bin/bash

output=$(netstat -tuln)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

get_port_description() {
    local proto=$1
    local port=$2
    description=$(grep -w "${port}/${proto}" /etc/services | awk '{print $1}' | head -n 1)
    if [ -z "$description" ]; then
        echo "Unknown"
    else
        echo "$description"
    fi
}

get_queues() {
    local proto=$1
    local port=$2
    queues=$(ss -tuln | grep "$proto" | grep ":$port" | awk '{print $2 "/" $3}' | head -n 1)
    if [ -z "$queues" ]; then
        echo "0/0"
    else
        echo "$queues"
    fi
}

printf "%-7s | %-21s | %-6s | %-21s | %-6s | %-10s | %-8s | %-15s\n" \
       "PROTO" "LOCAL IP" "L.PORT" "FOREIGN IP" "F.PORT" "STATE" "QUEUES" "PORT DESC"
printf "%s\n" "---------------------------------------------------------------------------------------------------------------"

echo "$output" | tail -n +3 | while read -r line; do
    if [[ $line == tcp* ]] || [[ $line == udp* ]]; then
        protocol=$(echo "$line" | awk '{print $1}')
        local_address=$(echo "$line" | awk '{print $4}')
        foreign_address=$(echo "$line" | awk '{print $5}')
        state=$(echo "$line" | awk '{print $6}')

        local_ip=$(echo "$local_address" | rev | cut -d':' -f2- | rev)
        local_port=$(echo "$local_address" | rev | cut -d':' -f1 | rev)

        foreign_ip=$(echo "$foreign_address" | rev | cut -d':' -f2- | rev)
        foreign_port=$(echo "$foreign_address" | rev | cut -d':' -f1 | rev)

        queues=$(get_queues "$protocol" "$local_port")

        port_desc=$(get_port_description "$protocol" "$local_port")

        if [[ $protocol == tcp* ]]; then
            printf "${GREEN}%-7s | %-21s | %-6s | %-21s | %-6s | %-10s | %-8s | %-15s${NC}\n" \
                   "$protocol" "$local_ip" "$local_port" "$foreign_ip" "$foreign_port" "$state" "$queues" "$port_desc"
        elif [[ $protocol == udp* ]]; then
            printf "${YELLOW}%-7s | %-21s | %-6s | %-21s | %-6s | %-10s | %-8s | %-15s${NC}\n" \
                   "$protocol" "$local_ip" "$local_port" "$foreign_ip" "$foreign_port" "-" "$queues" "$port_desc"
        fi
    fi
done

printf "%s\n" "---------------------------------------------------------------------------------------------------------------"
