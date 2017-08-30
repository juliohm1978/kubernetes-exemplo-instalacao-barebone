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

