# Introdução

Este repositório pretende hospedar um exemplo completo de uma instalação Kubernetes em barebone na língua portuguesa. Isto deve ajudar analistas e desenvolvedores a criar um cluster Kubernetes do zero usando a ferramenta [Kubespray](https://github.com/kubernetes-incubator/kubespray).

Para instalações menores, o [kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/) funciona muito bem. Entretanto, não há suporte para um cluster de alta disponibilidade (HA); o kubeadm sabe instalar somente um master com apenas uma instância `etcd`. Vários exemplos podem ser encontrados na Internet mostrando a instalação do Kubernetes no GCE ou AWS. Caso você precise fazer isso em sua própria infraestrutura (barebone), minha experiência pessoal tem mostrado o Kubespray como a melhor ferramenta.

Detalhes sobre conceitos e o funcionamento do Kubernetes podem ser encontrados na documentação oficial (https://kubernetes.io/docs/home/), cuja leitura completa é recomendada antes de iniciar atividades práticas. Outras fontes recomendadas incluem:

* [Kubernetes Anywhere](https://github.com/kubernetes/kubernetes-anywhere): Um guia detalhado de como instalar manualmente o Kubernetes no GCE ou AWS.
* [Kubernetes on CoreOS](https://coreos.com/kubernetes/docs/latest/): Outro guia que, apesar de ser direcionado à solução proprietária da CoreOS, continua sendo uma fonte bem detalhada de todos os passos necessários para uma instalação manual.

# Pré-requisitos

Para mostrar um exemplo completo, presume-se a existência de 6 (seis) máquinas virtuais já criadas e configuradas. Com esta quantidade, teremos um cluster completo organizado da seguinte forma:

| Host     | Papél no Cluster |
| -------- | -------- |
| node01   | Master + etcd |
| node02   | Master + etcd |
| node03   | Master + etcd |
| node04   | Worker |
| node05   | Worker |
| node06   | Worker |

Se necessário à sua infraestrutura, um número menor ou maior pode ser usado. O Kubespray suporta, inclusive, instalar um cluster com apenas um host, similar ao kubeadm.

Este guia também presume que cada host mencionado acima possui um nome resolvível na rede DNS local e um IP fixo publicamente acessível nesta mesma rede.

## Sistema Operacional do Host

Este guia usa o Ubuntu 16.04 LTS em todos os hosts. Pela natureza da solução de containers e Kubernetes, acredito que não deva encontrar maiores problemas usando outra distribuição conhecida do mercado. Confira a documentação do Kubespray para detalhes sobre distribuições suportadas.

## Ansible
O Kubespray utiliza Ansible para relizar a instalação. Ele deve ser executado de sua estação de trabalho, instalando o Kubernetes remotamente via SSH. Assim, sua estação de trabalho precisa ter esta ferramenta instalada. Confira detalhes no [guia oficial de instalação do Ansible](http://docs.ansible.com/ansible/latest/intro_installation.html). Ao momento, a versão mais recente 2.3.2.0 deve funcionar sem problemas, gerando apenas _warnings_ de incompatibilidade.

Parte da configuração do Ansible envolve preparar cada host do cluster para um acesso remoto sem senha. Será preciso configurar todos com uma chave ssh, dando **acesso remoto como usuário root pela chave**. Confira [os diversos tutoriais pela Internet](https://www.google.com.br/search?q=ssh+chave+sem+senha&oq=ssh+chave+sem+senha&aqs=chrome..69i57j0l5.5311j0j9&sourceid=chrome&ie=UTF-8) sobre como fazer isso.

Certifique-se, também, de que o Python está instalado em todos os hosts, pois o Ansible precisa dele para executar suas tarefas.

# Instalação Kubernetes

Faça o download do Kubespray para sua estação de trabalho.

```
git clone https://github.com/kubernetes-incubator/kubespray.git
cd kubespray
```

Faça uma cópia do arquivo `inventory/inventory.example` para montar o inventário com seus hosts.

```
cp inventory/inventory.example inventory/inventory.txt
```

O conteúdo do inventário é simples e direto. Se o host possui mais de uma interface de rede, use a propriedade `ip=x.x.x.x` para especificar qual delas será usada. Este IP será usado para criar certificados e configurações de componentes no cluster.

```
# ## Configure 'ip' variable to bind kubernetes services on a
# ## different ip than the default iface
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

Com tudo pronto, basta executar o script `cluster.yml`.

```
ansible-playbook cluster.yml -i inventory/inventory.txt
```

A instalação pode demorar alguns minutos, mas deve fazer todo trabalho sem erros. Ao final (depois de muitas e muitas vaquinhas) um resumo será apresentado.

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

Se tudo foi como esperado, seu cluster está pronto para ser usado. 

# Desinstalação

Caso precise, também é possível remover tudo que foi instalado e recomeçar do zero.

```
ansible-playbook reset.yml -i inventory/inventory
```

**CUIDADO! Este comando remove TUDO. Sem um backup, todas as configurações e estado atual do cluster será perdido.**

# Backup

Com o tempo, você acabará criando vários objetos do tipo Service, Deployment, DaemonSet, Ingress, etc. Todos estes objetos são armazenados no banco `etcd`, que representa o estado atual do cluster.

## Backup do Etcd

Recomenda-se manter um backup regular do `etcd` para que seja possível recuperar o cluster de um desastre. Se você realizou a instalação do `etcd` conforme este exemplo, em três hosts diferentes, a recuperação do backup somente será necessária se TODAS as instâncias `etcd` forem perdidas. De modo geral, um cluster de três instâncias é capaz de perder um nó e continuar operando normalmente. Nós adicionais podem ser adicionados a qualquer momento de forma transparente.

O Kubespray executa o `etcd` como um container privilegiado independente fora do Kubernetes. No host Ubuntu, ele é configurado como um systemd service. Os parâmetros do container ficam em `/etc/etcd.env` ou diretamente no script `/usr/local/bin/etcd`. Ao modificar estes arquivos, basta reiniciar o serviço.

```
service etcd restart
```

Para fazer um backup, é preciso usar a ferramenta `etcdctl` de dentro do container e depois copiar o backup para fora.

```
docker exec etcd1 etcdctl --endpoints https://IP_DO_HOST:2379 backup --data-dir /var/lib/etcd --backup-dir /backup
docker cp etcd1:/var/lib/etcd/member/snap/db /tmp/backup/member/snap/
docker cp etcd1:/backup /tmp/
```

Com isso, o backup estará no diretório `/tmp/backup` do host.

## Restauração do Etcd

Apesar do backup simplificado, uma eventual restauração é mais complicada. Como dito anteriormente, isto deve ser necessário somente no caso de um deastre completo, onde todas as instâncias foram perdidas. Um desastre parcial pode ser facilmente recuperado apenas incluindo outro nó `etcd` no cluster.

Antes de iniciar uma restauração, recomenda-se fazer uma para completa do cluster. Em cada host:

```
## evita que o kubelet fique tentando reiniciar containers
service kubelet stop

## opcional: limpa todos os containers, deixa serem recriados
docker ps -q | xargs docker stop
docker ps -qa | xargs docker rm
```

> NOTA: Apesar de ser um container, o runtime do `etcd` é mantido essencialmente pelo systemd do Ubuntu. Não adianta parar o container apenas usando `docker stop etcd1`, pois ele será reiniciado pelo systemd.

