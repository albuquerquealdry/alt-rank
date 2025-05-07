#!/bin/bash

Função para verificar o status de um comando
check_status() {
  if [ $? -ne 0 ]; then
    echo "Erro no comando: $1"
    exit 1
  fi
}

# # Definindo os nomes dos namespaces como variáveis
NS1=${1:-"ns-UMAVAR1"}
NS2=${2:-"ns-UMAVAR2"}
NS3=${3:-"ns-UMAVAR3"}

# Colocando os namespaces em uma lista
NAMESPACES=($NS1 $NS2 $NS3)

echo "Criando routers: ${NAMESPACES[@]}..."


for NS in "${NAMESPACES[@]}"; do
  sudo ip netns add router-$NS
  check_status "sudo ip netns add router-$NS"
done

echo "Criando switchs: ${NAMESPACES[@]}..."


for NS in "${NAMESPACES[@]}"; do
  sudo ip netns add sw-$NS
  check_status "sudo ip netns add router-$NS"
done


sudo ip netns router-$NS1
sudo ip netns router-$NS2
sudo ip netns router-$NS3
sudo ip netns sw-$NS1
sudo ip netns sw-$NS2
sudo ip netns sw-$NS3