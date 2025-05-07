#!/bin/bash

NS1=${1:-"ns-UMAVAR1"}
NS2=${2:-"ns-UMAVAR2"}


# Limpeza
echo "Limpeza: Removendo namespaces e interfaces..."
sudo ip netns delete $NS1
sudo ip netns delete $NS2
sudo ip link delete veth-$NS1
