# 5 Backup e Restauração

Com o tempo, você acabará criando vários objetos do tipo Service, Deployment, DaemonSet, Ingress, etc. Todos os objetos Kubernetes são armazenados no banco `etcd`, que representa o estado atual do cluster.

Com base em diversas experiências que foram feitas, encontramos duas formas de recuperação do cluster no caso de um desastre.

1. Recuperar um cluster parcialmente danificado.
2. Criar um novo cluster e recriar todos os objetos.

Seja qual for a opção, antes de tudo, é preciso ter um backup.

## 5.1 Backup do /etc/kubernetes

Este diretório possui todos os certificados e configurações internas do cluster. Cada host (master ou worker) possui um diretório `/etc/kubernetes` próprio. Em especial, uma cópia de backup para cada master é essencial para recuperar uma eventual corrupção dos dados.

O backup deste diretório dos workers não se mostra tão necessário, pois este tipo de host pode ser facilmente recriado executando o playbook `cluster.yml` novamente.

## 5.2 Considerações Sobre o Etcd

A instalação feita pelo Kubespray prepara o Kubernetes para usar o primeiro nó etcd como primário e os demais como *failover*.

De modo geral, um cluster etcd de três instâncias é capaz de perder um nó e continuar operando normalmente. Ao perder dois nós, ele para de funcionar, mas ainda pode ser facilmente recuperado. Nós adicionais podem ser adicionados a qualquer momento para replicar a base de dados. Esta é uma tarefa relativamente simples com o Kubespray, pois basta executar o playbook `cluster.yml` novamente com um inventário ajustado.

Por baixo dos panos, o etcd executa dentro de um container independente, fora do Kubernetes. No host Ubuntu, ele é mantido como um *systemd service*. O container executa em modo privilegiado, ligado diretamente à rede do host e montando o diretório de dados e configuração como volumes.

A partir do host, os parâmetros passados ao etcd ficam em `/etc/etcd.env` ou diretamente no arquivo `/usr/local/bin/etcd`. Ao modificar estes arquivos, basta reiniciar o serviço.

```
service etcd restart
```

## 5.3 Backup do Etcd

Para fazer um backup, é preciso usar a ferramenta `etcdctl` de dentro do container e depois copiar o backup para fora.

```
## cria backup
docker exec etcd1 etcdctl --endpoints https://IP_DO_HOST:2379 backup --data-dir /var/lib/etcd --backup-dir /backup

## complementa backup com o snapshot atual (pegadinha do Faustão)
docker cp etcd1:/var/lib/etcd/member/snap/db /backup/member/snap/

## compacta o backup (ainda dentro do container)
docker exec -it etcd1 tar -czf /tmp/backup.tgz /backup

## copia backup para fora
docker cp etcd1:/tmp/backup.tgz /algum/lugar/seguro/
```

## 5.4 Restauração do Etcd

O backup parece simples, mas uma eventual restauração é mais complicada.

Como dito anteriormente, isto deve ser necessário somente quando:

* Houve um desastre completo e todas as instâncias etcd foram perdidas.
* Uma versão corrompida da base foi replicada para todo o cluster.

> NOTA: Vale lembrar que o Kubernetes é preparado para ser o mais resiliente possível. Hosts do tipo worker estão sempre tentando manter seus containers funcionando. Ao desligar todos os masters, perde-se a capacidade de modificar os objetos do cluster. Apesar disso, o que já estiver funcionando no cluster deve continuar funcionando.

Antes de iniciar uma restauração, recomenda-se fazer uma parada completa do conjunto master do cluster.

Em cada master, desligue o kubelet para evitar que ele atue reiniciando containers locais.

```
service kubelet stop
```

Em cada master, pare todas as instâncias do etcd.

```
service etcd stop
```

Escolha um nó onde será feita a restauração do backup, ex: node1.

Remova o diretório atual `/var/lib/etcd/members`, substituindo-o pelo backup.

```
rm -fr /var/lib/etcd/members
cd /var/lib/etcd/
tar -xzf /caminho/para/meu/backup.tgz 
```

Modifique o script `/usr/local/bin/etcd` adicionando a flag `--force-new-cluster` como parâmetro ao etcd, conforme o exemplo abaixo:

```
#!/bin/bash
/usr/bin/docker run \
  --restart=on-failure:5 \
  --env-file=/etc/etcd.env \
  --net=host \
  -v /etc/ssl/certs:/etc/ssl/certs:ro \
  -v /etc/ssl/etcd/ssl:/etc/ssl/etcd/ssl:ro \
  -v /var/lib/etcd:/var/lib/etcd:rw \
    --memory=512M \
      --name=etcd1 \
  quay.io/coreos/etcd:v3.2.4 \
    /usr/local/bin/etcd \
    \
    --force-new-cluster \
    \
    "$@"
```

Reinicie o etcd e confira os logs do container para garantir que tudo deu certo.

```
service etcd restart
docker logs -f etcd1
```

Remova a flag `--force-new-cluster` do arquivo `/usr/local/bin/etcd` e reinicie o etcd novamente.

```
service etcd restart
```

Se tudo deu certo, esta nova instância pensa que é um cluster de apenas um nó. Antes de adicionar outros membros, é preciso modificar sua propriedade *peer url*.

```
## confira os membros atuais do cluster
docker exec etcd1 etcdctl --endpoints https://IP_NODE1:2379 member list

## recupera o ID deste membro (etcd1)
MID=$(docker exec etcd1 etcdctl --endpoints https://IP_NODE1:2379 member list | awk '{print $1}' | sed 's/://g')

## modifica peer url de localhost para IP_NODE1
docker exec etcd1 etcdctl --endpoints https://IP_NODE1:2379 member update $MID https://IP_NODE1:2380

## adiciona os demais membros do cluster
docker exec etcd1 etcdctl --endpoints https://IP_NODE1:2379 member add etcd2 https://IP_NODE2:2380

docker exec etcd1 etcdctl --endpoints https://IP_NODE1:2379 member add etcd3 https://IP_NODE3:2380
```

Somente depois de adicionados todos os membros, podemos reiniciar o etcd nos demais hosts, lembrando de remover o diretório de dados atual para receber uma réplica do primeiro nó que foi recuperado acima.

```
root@node2:~# rm -fr /var/lib/etcd/members
root@node2:~# service etcd restart

root@node3:~# rm -fr /var/lib/etcd/members
root@node3:~# service etcd restart
```

Por desencargo, confira os logs do etcd para garantir que o cluster foi corretamente iniciado. Será possível ver mensagens referentes à eleição de um novo líder.

Por fim, lembre-se de reiniciar o kubelet em cada master:

```
service kubelet restart
```

Neste ponto, caso queira garantir um ambiente renovado, faça o reboot de todos os masters, ou aguarde até todos os componentes do Kubernetes se recuperarem.

## 5.6 Dump Completo dos Objetos

Outra forma de backup que pode ser útil é fazer um dump completo de todos os objetos que foram criados no Kubernetes (service accounts, persistente volumes, services, deployments, secrets, configmaps, etc).

A princípio, espera-se que uma cópia destes objetos já esteja disponível a partir do provisionamento das aplicações e serviços no cluster. Entretanto, a recuperação pode ser mais rápida a partir de um dump completo.

Ao contrário dos procedimentos anteriores mencionados, recuperando o cluster de um desastre parcial, este envolve criar um cluster completamente novo e restaurar um backup de todos os ojetos Kubernetes no cluster. Pode ser visto como um *export/import* das configurações, criando uma cópia do cluster original.

O script bash [`dump-cluster.sh`](sctipts/dump-cluster.sh) é baseado nos [exemplos da CoreOS](https://github.com/coreos/docs/blob/master/kubernetes/cluster-dump-restore.md) e pode ser executado para criar dump completo. Ele cria um diretório `cluster-dump` e exporta todos os objetos em formato JSON.

> NOTA: Um pré-requisito do script de dump é a ferramente [jq](https://stedolan.github.io/jq/). Para instalar no Ubuntu, basta executar `apt-get install -y jq`

Para usar o script:

```
$ bash dump-cluster.sh

## output suprimido...

$ ls -l
total 684
-rw-r--r-- 1 lamento lamento 642020 Aug 30 14:58 cluster-dump.json
-rw-r--r-- 1 lamento lamento   2603 Aug 30 13:37 nodes.json
-rw-r--r-- 1 lamento lamento    700 Aug 30 13:37 ns.json
```

Ao final, os arquivos em formato JSON devem estar presentes:

* ns.json - Todos os namespaces
* nodes.json - Todos os hosts (masters e workers).
* cluster-dump.json - Demais objetos na seguinte ordem:
    - ServiceAccounts
    - ClusterRoles
    - Roles
    - ClusterRoleBindings
    - RoleBindings
    - StorageClasses
    - ResourceQuotas
    - Limits
    - NetworkPolicies
    - ConfigMaps
    - PersistentVolumes
    - PersistentVolumeClaims
    - Secrets
    - Services
    - Deployments
    - Statefulsets
    - ReplicationControllers
    - DaemonSets
    - Jobs
    - Ingresses

A exportação ignora objetos do namespace `kube-system` e `kube-public`. Caso sinta a necessidade de incluí-los, basta modificar o script. Eles foram excluídos cuidadosamente depois de constatado que os objetos de sistema do kubernetes não são portáveis para outra instalação.

O script também ignora propriedades voláteis, como UIDs, resourceVersion, creationTimestamp, etc.), deixando apenas o que for necessário para recriar os objetos.

> NOTA: Oficialmente, o Kubernetes não tem um bom suporte para uma exportação deste tipo. Há discussões em andamento sobre como implementar esta funcionalidade de forma nativa e mais intuitiva. Eis o motivo deste script ter sido criado por outras entidades. Apesar disso, testes realizados mostram que, na versão atual 1.7.3, ele funciona bem, não causando problemas ou inconsistências.

Objetos do tipo **Pod** e **ReplicaSet** não são incluídos. Como são voláteis e gerenciados pelos Deployments/ReplicationControllers/StatefulSets, não há muita necessidade de serem exportados. Devem ser recriados automaticamente quando o backup for importado em um novo ambiente.

Já os objetos do tipo **Node** são colocados em um arquivo separado por um bom motivo. Um novo cluster onde os objetos serão importados pode não ter a mesma topologia, ou sequer a mesma quantidade de hosts com os mesmos nomes e IPs. Entretanto, algumas informações podem estar contidas nestes objetos que afetam os serviços e aplicações -- por exemplo, alguns hosts podem ter labels e annotations que restringem quais pods podem ser executados, definindo seu papél no cluster. O arquivo `nodes.js` deve dispor estas informações. No pior dos casos, pode servir de referência para recriar o ambiente.

## 5.7 Restauração a Partir de um Dump

Esta etapa presume que um novo cluster foi criado e está pronto para receber novos objetos e aplicações. Para recuperar o backup, basta aplicar todos os objetos na ordem correta.

Os objetos de Nodes devem recuperar labels e annotations. Se o novo cluster é um ambiente idêntico a cluster antigo (mesmos hosts com nomes e IPs iguais), a importação é direta. Se a estrutura for diferente, sinta-se livre para modificar o arquivo `nodes.json` adaptando à nova estrutura, conforme a necessidade.

```
kubectl apply -f nodes.json
```

Importar os objetos Namespace.

```
kubectl apply -f ns.json
```

Importar o restante dos objetos.

```
kubectl apply -f cluster-dump.json
```

### Persistent Volumes e Claims

Cada Persistent Volume (PV) pode pertencer a um PersistentVolumeClaim (PVC). Esta conexão é feita pelo Kubernetes relacionando o UID do PVC no objeto PV. Normalmente, não é preciso se preocupar com isso. Mas como estamos recuperando de uma instalação antiga, os objetos PVC foram criados novamente e todos receberam um UID diferente dentro do novo cluster. Enquanto isso, os objetos PV foram importados com a referência de PVC antiga.

Sem esta correção de UIDs, Pods que usam PersistentVolumeClaims não conseguem subir corretamente e apresentam erro.

Para ajudar, o script [`recover-pv-binding.sh`](scripts/recover-pv-binding.sh) foi criado. Ao ser executado, ele varre todos os PVs do ambiente, procura pelo PVC relacionado através de seu nome e corrige a referência do UID.

Depois desta correção, os pods relacionados devem funcionar no próximo restart automático.

