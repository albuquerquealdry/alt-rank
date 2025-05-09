netns_list=$(ip netns list)

if [ -z "$netns_list" ]; then
  echo "Não há namespaces de rede para remover."
  exit 0
fi

for netns in $netns_list; do
  echo "Removendo o namespace: $netns"
  ip netns del "$netns"
done

echo "Todos os namespaces de rede foram removidos."