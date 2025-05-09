#!/bin/bash

# Print Inicial
echo -e "\033[1;32mALT-RANK (Esse script foi foda de fazer, mas o GPT Ajudou e deixou colorido!)\033[0m"
echo -e "\nIniciando a configuração do ambiente de rede...\n"

# Define List for 
ROUTERS=("r1" "r2" "r3")
SWITCHS=("sw-r1" "sw-r2" "sw-r3")
VM_SWITCH_1=("vm1-r1" "vm2-r1" "vm3-r1")
VM_SWITCH_2=("vm1-r2" "vm2-r2" "vm3-r2")
VM_SWITCH_3=("vm1-r3" "vm2-r3" "vm3-r3")

# Função para criar os namespaces
create_netns() {
  # Listas que receberão os namespaces
  local namespaces=("$@")

  for ns in "${namespaces[@]}"; do
    echo -e "\033[1;34mCriando o namespace: $ns\033[0m"
    ip netns add "$ns"
  done
}

create_veth_links() {
  local routers=("$@")

  # Criar os links veth entre cada par de roteadores
  for i in "${!routers[@]}"; do
    for j in $(seq $((i + 1)) $((${#routers[@]} - 1))); do
      router1="${routers[$i]}"
      router2="${routers[$j]}"

      # Criando link veth entre os roteadores
      echo -e "\033[1;34mCriando link veth entre $router1 e $router2\033[0m"
      ip link add "${router1}-${router2}" type veth peer name "${router2}-${router1}"
      ip link set "${router1}-${router2}" netns "$router1"
      ip link set "${router2}-${router1}" netns "$router2"
    done
  done
}

configure_router_interfaces() {
  echo -e "\033[1;33mConfigurando interfaces e IPs nos roteadores...\033[0m"

  # Roteador r1
  ip netns exec r1 ip addr add 10.0.1.1/30 dev r1-r2
  ip netns exec r1 ip addr add 10.0.2.1/30 dev r1-r3
  ip netns exec r1 ip link set r1-r2 up
  ip netns exec r1 ip link set r1-r3 up
  ip netns exec r1 ip link set lo up

  # Roteador r2
  ip netns exec r2 ip addr add 10.0.1.2/30 dev r2-r1
  ip netns exec r2 ip addr add 10.0.3.1/30 dev r2-r3
  ip netns exec r2 ip link set r2-r1 up
  ip netns exec r2 ip link set r2-r3 up
  ip netns exec r2 ip link set lo up

  # Roteador r3
  ip netns exec r3 ip addr add 10.0.2.2/30 dev r3-r1
  ip netns exec r3 ip addr add 10.0.3.2/30 dev r3-r2
  ip netns exec r3 ip link set r3-r1 up
  ip netns exec r3 ip link set r3-r2 up
  ip netns exec r3 ip link set lo up

  echo -e "\033[1;32mIPs configurados e interfaces ativadas.\033[0m"
}

enable_ip_forwarding() {
  echo -e "\033[1;33mHabilitando IP forwarding nos roteadores...\033[0m"

  for router in "${ROUTERS[@]}"; do
    ip netns exec "$router" sysctl -w net.ipv4.ip_forward=1
  done

  echo -e "\033[1;32mIP forwarding habilitado em todos os roteadores.\033[0m"
}

configure_lan() {
  local r_id="$1"         
  local rede="$2"         
  local sw_id="sw-$r_id"  
  local vm_prefix="vm"

  echo -e "\033[1;33mConfigurando LAN do roteador $r_id (rede $rede)...\033[0m"

  # Criar bridge no switch
  ip netns exec "$sw_id" ip link add br0 type bridge
  ip netns exec "$sw_id" ip link set br0 up

  # Criar veths entre VMs e switch
  for i in 1 2 3; do
    local vm="${vm_prefix}${i}-${r_id}"
    local vm_veth="${vm}-veth"
    local sw_veth="${sw_id}-vm${i}"

    ip link add "$vm_veth" type veth peer name "$sw_veth"
    ip link set "$vm_veth" netns "$vm"
    ip link set "$sw_veth" netns "$sw_id"

    # Conectar no bridge e subir interfaces
    ip netns exec "$sw_id" ip link set "$sw_veth" master br0
    ip netns exec "$sw_id" ip link set "$sw_veth" up

    ip netns exec "$vm" ip addr add "${rede%.*}.$((10 + i))/24" dev "$vm_veth"
    ip netns exec "$vm" ip link set "$vm_veth" up
    ip netns exec "$vm" ip link set lo up
    ip netns exec "$vm" ip route add default via "${rede%.*}.1"
  done

  # Criar veth entre switch e roteador
  local sw_r_veth="${sw_id}-${r_id}"
  local r_veth="${r_id}-lan"

  ip link add "$r_veth" type veth peer name "$sw_r_veth"
  ip link set "$r_veth" netns "$r_id"
  ip link set "$sw_r_veth" netns "$sw_id"

  ip netns exec "$sw_id" ip link set "$sw_r_veth" master br0
  ip netns exec "$sw_id" ip link set "$sw_r_veth" up
  ip netns exec "$r_id" ip addr add "${rede%.*}.1/24" dev "$r_veth"
  ip netns exec "$r_id" ip link set "$r_veth" up
}

add_static_routes() {
  echo -e "\033[1;33mAdicionando rotas estáticas...\033[0m"

  # R1
  ip netns exec r1 ip route add 172.17.0.0/24 via 10.0.1.2
  ip netns exec r1 ip route add 172.18.0.0/24 via 10.0.2.2

  # R2
  ip netns exec r2 ip route add 172.16.0.0/24 via 10.0.1.1
  ip netns exec r2 ip route add 172.18.0.0/24 via 10.0.3.2

  # R3
  ip netns exec r3 ip route add 172.16.0.0/24 via 10.0.2.1
  ip netns exec r3 ip route add 172.17.0.0/24 via 10.0.3.1

  echo -e "\033[1;32mRotas estáticas configuradas.\033[0m"
}

# Criando os namespaces
create_netns "${ROUTERS[@]}"
create_netns "${SWITCHS[@]}"
create_netns "${VM_SWITCH_1[@]}"
create_netns "${VM_SWITCH_2[@]}"
create_netns "${VM_SWITCH_3[@]}"
echo -e "\033[1;32mTodos os namespaces foram criados com sucesso.\033[0m"

create_veth_links "${ROUTERS[@]}"
echo -e "\033[1;32mTodos os links veth foram configurados entre os roteadores.\033[0m"

configure_router_interfaces
echo -e "\033[1;32mSubindo interfaces e atribuindo IP a elas.\033[0m"

enable_ip_forwarding "${ROUTERS[@]}"

configure_lan "r1" "172.16.0.0"
configure_lan "r2" "172.17.0.0"
configure_lan "r3" "172.18.0.0"

add_static_routes

# Mensagem final
echo -e "\n\033[1;32mHoje não tem discurso motivacional, se quiser desistir desista.\033[0m"