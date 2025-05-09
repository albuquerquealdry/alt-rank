declare -A namespaces
namespaces=(
  ["vm1-r1"]=172.16.0.11
  ["vm2-r1"]=172.16.0.12
  ["vm3-r1"]=172.16.0.13
  ["vm1-r2"]=172.17.0.11
  ["vm2-r2"]=172.17.0.12
  ["vm3-r2"]=172.17.0.13
  ["vm1-r3"]=172.18.0.11
  ["vm2-r3"]=172.18.0.12
  ["vm3-r3"]=172.18.0.13
)

for ns1 in "${!namespaces[@]}"; do
  ip netns exec "$ns1" ping -c 1 "${namespaces[$ns1]}" > /dev/null
  if [ $? -eq 0 ]; then
    echo "Conectividade bem-sucedida entre $ns1 e ${namespaces[$ns1]}"
  else
    echo "Falha na conectividade entre $ns1 e ${namespaces[$ns1]}"
  fi
done

# Imprimindo a última frase em vermelho
echo -e "\033[31mMas tu pode pingar na mao se duvidar.\033[0m"
