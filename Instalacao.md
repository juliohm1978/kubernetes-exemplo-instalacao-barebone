# 3 Instalação Kubernetes

A instalação abrange os seguintes passos:

1. Obter o código fonte do Kubespray
2. Ajustar o inventário para refletir a topologia desejada
3. Ajustar algumas outras configurações do cluster que será criado
4. Executar o playbook `cluster.yml`

## 3.1 Download

Faça o download do Kubespray em sua estação de trabalho.

```
git clone https://github.com/kubernetes-incubator/kubespray.git
cd kubespray
```

## 3.2 Inventário

Faça uma cópia do arquivo `inventory/inventory.example` para montar um inventário com seus hosts.

```
cp inventory/inventory.example inventory/inventory.txt
```

O conteúdo do inventário é simples e direto. Se o host possui mais de uma interface de rede, use a propriedade `ip=x.x.x.x` para especificar qual delas será usada. Atente para este valor, pois este será o IP usado para criar certificados e configurações dos componentes no cluster.

É uma boa idéia configurar a propriedade `ip=x.x.x.x` para cada host, mesmo que não tenham várias interfaces de rede. Lembre-se de que a instalação Kubernetes envolve, primeiramente, a instalação do Docker. Este componente cria novas interfaces de rede virtuais com IPs e subredes variadas. Nada garante que o Kubespray escolherá a interface correta para configurar os demais componentes do cluster.

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

Faça uma revisão completa do arquivo `inventory/group_vars/k8s-cluster.yml` e modifique valores que fazem sentido para o seu ambiente. Nele, estão os parâmetros gerais da instalação, como versão do kubernetes, versão de cada componente, plugin de rede que será usado (weave, flannel, calico), range de IPs de pods e serviços dentro do cluster e muito mais.

Outro arquivo que possui parâmetros para instalação é o `inventory/group_vars/all.yml`. Confira se nada precisa ser customizado nele também.

## 3.3 Considerações Sobre a Configuração de Rede

Para funcionar, o Kubernetes cria uma rede interna usada somente pelos Pods e Containers de seu cluster. Dependendo de qual plugin de rede for usado e como este for configurado, estas configurações podem afetar ou conflitar com a topologia da rede de sua empresa/ambiente.

Tome tempo para ler e entender a documentação relacionada aos plugins de rede ([Cluster Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/), [Network Plugins](https://kubernetes.io/docs/concepts/cluster-administration/network-plugins/), [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)) e entender como o Kubernetes faz o roteamento de pacotes para dentro de sua rede interna ([Using Source IP](https://kubernetes.io/docs/tutorials/services/source-ip/)). Escolher o plugin de rede apropriado para sua instalação é um passo importante e pode precisar de revisão/aprovação dos administradores de sua rede.

## 3.4 Configurações Mais Avançadas

A versão atual do Kubespray já melhorou bastante, mas alguns valores menos conhecidos da configuração do cluster talvez não estejam disponíveis diretamente pelo arquivo `k8s-cluster.yml`.

Hoje, os parâmetos já são bem abrangentes. Caso precise modificar algum valor menos conhecido e tenha experiência suficiente para editar playbooks do Ansible, confira os scripts dentro do diretório `roles` para controlar a instalação de cada componente. Com cuidado, lembre-se: não há garantias de que tudo funcione bem com este nível de customização.

## 3.5 Mãos à Obra

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

Os componentes do cluster são instalados na seguinte ordem:

* Docker
* etcd
* kubelet e kube-proxy
* Plugin de Rede (calico, flannel ou weave)
* kube-apiserver, kube-scheduler, and kube-controller-manager
* Extensões (add-ons, como Kube-DNS)

Se tudo deu certo, nenhuma mensagem vermelha será vista no resumo da instalação e seu cluster estará pronto para ser usado. No console de um master, confira os pods do sistema:

```
kubectl get pods --all-namespaces
```

Para aumentar o diminuir a quantidade de hosts no cluster, utilize o playbook `scale.yml`

```
ansible-playbook scale.yml -i inventory/inventory.txt
```

# Atualizando a Versão do Kubernetes

O Kubespray suporta atualizações do cluster com os mesmos playbooks de instalação. Isto pode ser feito diretamente com o `cluster.yml`. Atualize o Kubespray para sua versão mais recente, modifique o `k8s-cluster.yml` e excute novamente:

```
ansible-playbook cluster.yml -i inventory/inventory.txt
```

Apesar de direto, o `cluster.yml` pode interferir na execução do containers e interromper algumas aplicações que estiverem no cluster. Para fazer uma atualização "elegante" (*graceful*) o playbook `upgrade-cluster.yml` pode ser usado.

```
ansible-playbook upgrade-cluster.yml -i inventory/inventory.txt
```

Ao contrário do `cluster.yml`, ele tenta drenar cada host antes de atualizar seus componentes. Isto realoca Pods e Containers para outros hosts enquanto a atualização ocorre. Enquanto que a atualização do `cluster.yml` ocorre em todos os hosts de forma paralela, o `upgrade-cluster.yml` executa as tarefas em um host de cada vez, sequencialmente.

Vale lembrar que esta atualização elegante do `upgrade-cluster.yml` só faz sentido se as aplicações conternizadas estiverem preparadas para oferecer sua própria alta disponibilidade com réplicas transparentes. Caso contrário, além de demorar mais, a realocação dos Pods e Containers pode causar mais interrupções e indisponibilidades que o `cluster.yml`. Analise suas necessidades na hora de realizar um upgrade.

> NOTA: O playbook `upgrade-cluster.yml` só pode ser usado para atualizar um cluster existente, não sendo capaz de criar um cluster novo.
