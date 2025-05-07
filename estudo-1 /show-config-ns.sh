#!/bin/bash

printf "%-20s %-15s\n" "Namespace" "Endereço IP"

for ns in $(sudo ip netns list); do
  if [[ "$ns" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    ip_info=$(sudo ip netns exec $ns ip addr show | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | grep -v '127.0.0.1' | head -n 1)
    
    if [ -n "$ip_info" ]; then
      printf "%-20s %-15s\n" "$ns" "$ip_info"
    fi
  fi
done
