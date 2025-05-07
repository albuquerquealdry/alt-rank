#!/bin/bash

# Função para verificar o status de um comando
check_status() {
  if [ $? -ne 0 ]; then
    echo "Erro no comando: $1"
    exit 1
  fi
}

# Listando todos os namespaces
NAMESPACES=$(ip netns list)

if [ -z "$NAMESPACES" ]; then
  echo "Nenhum namespace encontrado."
  exit 0
fi

echo "Namespaces encontrados: $NAMESPACES"

# Deletando os namespaces
for NS in $NAMESPACES; do
  echo "Deletando o namespace: $NS"
  sudo ip netns del $NS
  check_status "sudo ip netns del $NS"
done

echo "Todos os namespaces foram deletados."
