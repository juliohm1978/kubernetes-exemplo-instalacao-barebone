# Introdução

Este repositório pretende hospedar um exemplo completo de uma instalação Kubernetes em barebone na língua portuguesa. Isto deve ajudar analistas e desenvolvedores a criar um cluster Kubernetes em uma infraestrutura própria usando a ferramenta [Kubespray](https://github.com/kubernetes-incubator/kubespray).

Para instalações menores, o [kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/) funciona muito bem. Muitos exemplos e tutoriais já existem. Entretanto, kubeadm não suporta um cluster de alta disponibilidade (HA); consegue instalar somente um master com apenas uma instância etcd. Ademais, vários exemplos podem ser encontrados mostrando a instalação do Kubernetes no GCE ou AWS. Caso você precise fazer isso em sua própria infraestrutura (barebone), minha experiência pessoal tem mostrado o Kubespray como a melhor ferramenta.

Todos os detalhes e conceitos sobre Kubernetes podem ser encontrados na documentação oficial (https://kubernetes.io/docs/home/), cuja leitura completa é recomendada antes de iniciar atividades práticas. Outras fontes recomendadas incluem:

* [Kubernetes Anywhere](https://github.com/kubernetes/kubernetes-anywhere): Um guia detalhado de como instalar manualmente o Kubernetes no GCE ou AWS.
* [Kubernetes on CoreOS](https://coreos.com/kubernetes/docs/latest/): Outro guia que, apesar de ser direcionado à solução proprietária da CoreOS, continua sendo uma fonte bem detalhada de todos os passos necessários para uma instalação manual.

# Pré-requisitos

O Kubespray suporta uma variedade de topologias. Com ele, é possível instalar o Kubernetes dentro de um único host, algo que pode ser útil para criar um pequeno ambiente de testes. Para criar uma topologia diferente e adicionar novos hosts, basta modifiar o seu inventário Ansible antes de iniciar a instalação. Mesmo depois de instalado, o cluster pode crescer executando a instalação novamente com um inventário atualizado.

Para mostrar um exemplo completo, um total de 6 (seis) máquinas virtuais será usado. Este guia presume que as VMs já foram criadas e configuradas com algum sistema operacional suportado pelo Kubespray.

Ao final, você terá um cluster completo organizado da seguinte forma:

| Host     | Papél no Cluster |
| -------- | -------- |
| node01   | Master + etcd |
| node02   | Master + etcd |
| node03   | Master + etcd |
| node04   | Worker |
| node05   | Worker |
| node06   | Worker |

> NOTA: Neste exemplo, as instâncias etcd serão instaladas nos mesmos hosts que serão masters do Kubernetes. Entretanto, isto não é necessário. Em uma estrutura ainda maior, hosts exclusivos podem ser dedicados ao etcd. Apesar de ser um componente crítico, sua atualização pode ser feita de forma independete do restante do Kubernetes.

Este guia também presume que cada host mencionado acima possui um nome resolvível na rede DNS local e IPs fixos, acessíveis diretamente entre si na mesma rede.

## Sistema Operacional dos Hosts

Este guia usa o Ubuntu 16.04 LTS em todos os hosts. Pela natureza da solução de containers e Kubernetes, acredito que não deva encontrar maiores problemas usando outra distribuição conhecida do mercado. Confira a documentação do Kubespray para detalhes sobre distribuições suportadas.

## Ansible
O Kubespray utiliza Ansible para relizar a instalação. Ele deve ser executado de sua estação de trabalho, instalando o Kubernetes remotamente via SSH. Assim, sua estação de trabalho precisa ter esta ferramenta instalada. Confira o [guia oficial de instalação do Ansible](http://docs.ansible.com/ansible/latest/intro_installation.html) antes de continuar. Ao momento, a versão mais recente 2.3.2.0 deve funcionar sem problemas, gerando apenas _warnings_ de incompatibilidade.

Parte da configuração do Ansible envolve preparar todos os hosts do cluster para um acesso remoto sem senha. Será preciso configurá-los com uma chave ssh, dando **acesso remoto como usuário root pela chave**. Confira [os diversos tutoriais pela Internet](https://www.google.com.br/search?q=ssh+chave+sem+senha&oq=ssh+chave+sem+senha&aqs=chrome..69i57j0l5.5311j0j9&sourceid=chrome&ie=UTF-8) sobre como fazer isso.

Certifique-se, também, de que o Python está instalado nos hosts, pois o Ansible precisa dele para executar suas tarefas.

# Instalação Kubernetes

Faça o download do Kubespray na sua estação de trabalho.

```
git clone https://github.com/kubernetes-incubator/kubespray.git
cd kubespray
```

Faça uma cópia do arquivo `inventory/inventory.example` para montar um inventário com seus hosts.

```
cp inventory/inventory.example inventory/inventory.txt
```

O conteúdo do inventário é simples e direto. Se o host possui mais de uma interface de rede, use a propriedade `ip=x.x.x.x` para especificar qual delas será usada. Atente para este valor, pois este será o IP usado para criar certificados e configurações dos componentes no cluster.

```
node1 ansible_ssh_user=root ansible_ssh_host=node01 ip=x.x.x.x
node2 ansible_ssh_user=root ansible_ssh_host=node02 ip=x.x.x.x
node3 ansible_ssh_user=root ansible_ssh_host=node03 ip=x.x.x.x
node4 ansible_ssh_user=root ansible_ssh_host=node04 ip=x.x.x.x
node5 ansible_ssh_user=root ansible_ssh_host=node05 ip=x.x.x.x
node6 ansible_ssh_user=root ansible_ssh_host=node06 ip=x.x.x.x

[kube-master]
node1
node2
node3

[etcd]
node1
node2
node3

[kube-node]
node4
node5
node6

[k8s-cluster:children]
kube-node
kube-master
```

Faça uma revisão completa do arquivo `inventory/group_vars/k8s-cluster.yml` e modifique valores que fazem sentido para sua estrutura. Nele, estão os parâmetros gerais da instalação, como versão do kubernetes, versão de cada componente, plugin de rede que será usado (weave, flannel, calico), range de IPs de pods e serviços dentro do cluster e muito mais.

> NOTA: O Kubespray vem melhorando constantemente, mas alguns valores menos conhecidos da configuração do cluster talvez não estejam disponíveis diretamente pelo arquivo `k8s-cluster.yml`. Hoje, os parâmetos já são bem abrangentes. Caso precise de algum outro valor customizado e tenha experiência editando playbooks do Ansible, confira os scripts dentro do diretório `roles` para controlar todos os detalhes da instalação de cada componente. Mas, cuidado! Não há garantias de que tudo funcione bem com este nível de customização.

Com tudo pronto, basta executar o playbook `cluster.yml`.

```
ansible-playbook cluster.yml -i inventory/inventory.txt
```

A instalação deve demorar alguns minutos, mas deve fazer todo trabalho. Ao final (depois de muitas e muitas vaquinhas) um resumo será apresentado.

```
Wednesday 30 August 2017  13:50:31 -0300 (0:00:00.038)       0:09:54.442 ****** 
=============================================================================== 
download : Download containers if pull is required or told to always pull - 149.38s
kubernetes/master : Master | wait for the apiserver to be running ------ 19.10s
download : Download containers if pull is required or told to always pull -- 13.63s
etcd : wait for etcd up ------------------------------------------------ 11.89s
download : Download containers if pull is required or told to always pull -- 10.92s
kubernetes-apps/network_plugin/weave : Weave | wait for weave to become available -- 10.74s
etcd : reload etcd ----------------------------------------------------- 10.56s
docker : Docker | pause while Docker restarts -------------------------- 10.07s
download : Download containers if pull is required or told to always pull --- 8.23s
download : Download containers if pull is required or told to always pull --- 7.92s
download : Download containers if pull is required or told to always pull --- 7.71s
download : Download containers if pull is required or told to always pull --- 7.21s
download : Register docker images info ---------------------------------- 5.68s
kubernetes-apps/ansible : Kubernetes Apps | Start Resources ------------- 4.33s
download : Create dest directory for saved/loaded container images ------ 3.69s
kubernetes/preinstall : Install latest version of python-apt for Debian distribs --- 3.38s
kubernetes/secrets : Gen_certs | run cert generation script ------------- 3.35s
docker : Docker | reload docker ----------------------------------------- 3.15s
kubernetes/master : Copy kubectl from hyperkube container --------------- 3.11s
kubernetes/secrets : Check certs | check if a cert already exists on node --- 2.97s
```

Se tudo deu certo, seu cluster está pronto para ser usado. No console de um master, confira os pods do sistema:

```
kubectl get pods --all-namespaces
```

# Desinstalação

Caso precise, também é possível remover tudo que foi instalado e recomeçar do zero.

```
ansible-playbook reset.yml -i inventory/inventory
```

> **CUIDADO! Este comando remove TUDO. Sem um backup, todas as configurações e estado atual do cluster serão perdidos.** Isto inclui todos os containers que estiverem executando no momento, todos arquivos de configuração, toda a base de dados etcd e todos os certificados que foram criados para o cluster. Depois de executar um reset, Docker é único componente que permanece instalado.

# Backup e Restauração

Com o tempo, você acabará criando vários objetos do tipo Service, Deployment, DaemonSet, Ingress, etc. Todos os objetos Kubernetes são armazenados no banco `etcd`, que representa o estado atual do cluster.

Com base em diversas experiências que foram feitas, encontramos duas formas de recuperação do cluster no caso de um desastre.

1. Recuperar um cluster parcialmente danificado.
2. Criar um novo cluster e recriar todos os objetos.

Seja qual for a opção, antes de tudo, é preciso ter um backup.

## Considerações Sobre o Etcd

A instalação feita pelo Kubespray prepara o Kubernetes para usar o primeiro nó etcd como primário e os demais como *failover*.

De modo geral, um cluster etcd de três instâncias é capaz de perder um nó e continuar operando normalmente. Ao perder dois nós, ele para de funcionar, mas ainda pode ser facilmente recuperado. Nós adicionais podem ser adicionados a qualquer momento para replicar a base de dados. Esta é uma tarefa relativamente simples com o Kubespray, pois basta executar o playbook `cluster.yml` novamente com um inventário modificado.

Por baixo dos panos, o etcd executa dentro de um container independente, fora do Kubernetes. No host Ubuntu, ele é mantido como um *systemd service*. O container executa em modo privilegiado, ligado diretamente à rede do host e montando o diretório de dados e configuração como volumes.

A partir do host, os parâmetros passados ao etcd ficam em `/etc/etcd.env` ou diretamente no arquivo `/usr/local/bin/etcd`. Ao modificar estes arquivos, basta reiniciar o serviço.

```
service etcd restart
```

## Backup do Etcd

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

## Backup do /etc/kubernetes

Este diretório possui todos os certificados e configurações internas do cluster. Uma cópia de backup é essencial para recuperar uma eventual perda de um master.

## Restauração do Etcd

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

Escolha nó onde será feita a restauração do backup, ex: node1.

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

Somente depois de adicionados todos os membros, podemos reiniciar o etcd nos demais hosts.

```
## restart do etcd nos demais hosts

root@node2:~# service etcd restart

root@node3:~# service etcd restart
```

Por desencargo, confira os logs do etcd para garantir que o cluster foi corretamente iniciado. Será possível ver mensagens referentes à eleição de um novo líder.

Por fim, lembre-se de reiniciar o kubelet em cada master:

```
service kubelet restart
```

Neste ponto, caso queira garantir um ambiente renovado, faça o reboot de todos os masters, ou aguarde até todos os componentes do Kubernetes se recuperarem.

## Dump Completo dos Objetos

Outra forma de backup que pode ser útil é fazer um dump completo de todos os objetos que foram criados no Kubernetes (service accounts, persistente volumes, services, deployments, pods, secrets, configmaps, etc).

A princípio, espera-se que uma cópia destes objetos esteja disponível a partir do provisionamento das aplicações e serviços no cluster. Entretanto, a recuperação pode ser mais rápida se um dump completo estiver disponível.

## Restauração a Partir de um Dump
