#!/bin/bash

# Cabeçalho da tabela com espaçamento fixo
printf "%-20s %-15s\n" "Namespace" "Endereço IP"

# Loop para percorrer todos os namespaces
for ns in $(sudo ip netns list); do
  # Ignorando entradas inválidas ou não desejadas
  if [[ "$ns" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    # Pegando o primeiro IP não loopback do namespace
    ip_info=$(sudo ip netns exec $ns ip addr show | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | grep -v '127.0.0.1' | head -n 1)
    
    # Se houver IP no namespace
    if [ -n "$ip_info" ]; then
      # Exibindo os resultados em formato tabular e alinhado
      printf "%-20s %-15s\n" "$ns" "$ip_info"
    fi
  fi
done
