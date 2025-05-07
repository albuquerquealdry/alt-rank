#!/bin/bash

# Função para verificar o status de um comando
check_status() {
  if [ $? -ne 0 ]; then
    echo "Erro no comando: $1"
    exit 1
  fi
}

# Definindo os nomes dos namespaces como variáveis
NS1=${1:-"ns-UMAVAR1"}
NS2=${2:-"ns-UMAVAR2"}

# Criar namespaces
echo "Criando namespaces: $NS1 e $NS2..."
sudo ip netns add $NS1
check_status "sudo ip netns add $NS1"

sudo ip netns add $NS2
check_status "sudo ip netns add $NS2"

# Criar o par de interfaces veth
echo "Criando o par de interfaces veth..."
sudo ip link add veth-$NS1 type veth peer name veth-$NS2
check_status "sudo ip link add veth-$NS1 type veth peer name veth-$NS2"

# Mover as interfaces para os namespaces
echo "Movendo as interfaces para os namespaces..."
sudo ip link set veth-$NS1 netns $NS1
check_status "sudo ip link set veth-$NS1 netns $NS1"

sudo ip link set veth-$NS2 netns $NS2
check_status "sudo ip link set veth-$NS2 netns $NS2"

# Configurar IPs e ativar interfaces
echo "Configurando IPs e ativando interfaces..."

# No $NS1
sudo ip netns exec $NS1 ip addr add 10.10.1.1/24 dev veth-$NS1
check_status "sudo ip netns exec $NS1 ip addr add 10.10.1.1/24 dev veth-$NS1"

sudo ip netns exec $NS1 ip link set veth-$NS1 up
check_status "sudo ip netns exec $NS1 ip link set veth-$NS1 up"

sudo ip netns exec $NS1 ip link set lo up
check_status "sudo ip netns exec $NS1 ip link set lo up"

# No $NS2
sudo ip netns exec $NS2 ip addr add 10.10.1.2/24 dev veth-$NS2
check_status "sudo ip netns exec $NS2 ip addr add 10.10.1.2/24 dev veth-$NS2"

sudo ip netns exec $NS2 ip link set veth-$NS2 up
check_status "sudo ip netns exec $NS2 ip link set veth-$NS2 up"

sudo ip netns exec $NS2 ip link set lo up
check_status "sudo ip netns exec $NS2 ip link set lo up"

# Testar a comunicação entre os namespaces
echo "Testando comunicação entre $NS1 e $NS2..."

# Ping de $NS1 para $NS2
sudo ip netns exec $NS1 ping -c 4 10.10.1.2
check_status "Ping de $NS1 para $NS2"

# Ping de $NS2 para $NS1
sudo ip netns exec $NS2 ping -c 4 10.10.1.1
check_status "Ping de $NS2 para $NS1"


# echo "Laboratório concluído com sucesso!"
