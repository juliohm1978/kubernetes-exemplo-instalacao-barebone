# 2 Pré-requisitos

O Kubespray suporta uma variedade de topologias. Com ele, é possível instalar o Kubernetes dentro de um único host ou numa quantidade qualquer de máquinas.

Este guia é uma demonstração de como instalar o Kubernetse em um conjunto razoável de máquinas para obter um cluster de alta disponibilidade. Para facilitar as atividades, presume que hosts são máquinas virtuais de qualquer espécie (VMWare, VirtualBox, etc.), todas na mesma rede, com IPs fixos e nomes resolvíveis no DNS local.

Para criar sua topologia, basta modifiar o inventário Ansible antes de iniciar a instalação. Mesmo depois de instalado, o cluster pode ser atualizado ou crescer de tamanho simplesmente executando a instalação novamente.

Um total de 6 (seis) máquinas virtuais será usado. Este guia presume que as VMs já foram criadas e configuradas com algum sistema operacional suportado pelo Kubespray.

Ao final, você terá um cluster completo organizado da seguinte forma:

| Host     | Papél no Cluster |
| -------- | -------- |
| node01   | Master + etcd |
| node02   | Master + etcd |
| node03   | Master + etcd |
| node04   | Worker |
| node05   | Worker |
| node06   | Worker |

As instâncias etcd serão instaladas nos mesmos hosts que serão masters do Kubernetes. Entretanto, isto não é necessário. Em uma estrutura ainda maior, hosts exclusivos podem ser dedicados ao etcd. Apesar de ser um componente crítico, sua atualização pode ser feita de forma independete do restante do Kubernetes.

## 2.1 Antes de Começar

Faça snapshots de suas VMs no estado inicial, apenas com o sistema operacional do host instalado e limpo de qualquer configuração. Isto deve ajudar muito na hora de fazer experiências montando e desmontando seu cluster.

## 2.2 Sistema Operacional dos Hosts

Este guia usa o Ubuntu 16.04 LTS em todos os hosts. Pela natureza da solução de containers e Kubernetes, não devem haver muitos problemas usando outra distribuição conhecida. Confira a documentação do Kubespray para detalhes sobre distribuições suportadas.

## 2.3 Ansible

O Kubespray utiliza Ansible para realizar a instalação. Ele deve ser executado de sua estação de trabalho, instalando o Kubernetes remotamente via SSH. Assim, sua estação de trabalho precisa ter esta ferramenta instalada. Confira o [guia oficial de instalação do Ansible](http://docs.ansible.com/ansible/latest/intro_installation.html) antes de continuar. Ao momento, a versão mais recente 2.3.2.0 deve funcionar sem problemas, gerando apenas _warnings_ que podem ser ignorados.

Parte da configuração do Ansible envolve preparar todos os hosts do cluster para um acesso remoto sem senha. Será preciso configurá-los com uma chave ssh, dando **acesso remoto de sua estação como usuário root pela chave**. Confira [os diversos tutoriais pela Internet](https://www.google.com.br/search?q=ssh+chave+sem+senha&oq=ssh+chave+sem+senha&aqs=chrome..69i57j0l5.5311j0j9&sourceid=chrome&ie=UTF-8) sobre como fazer isso.

Certifique-se, também, de que o Python está instalado nos hosts, pois o Ansible precisa dele para executar suas tarefas. Em um host Ubuntu, o comando abaixo deve ser o suficiente.

```
sudo apt-get install -y python
```

## 2.4 Volumes NFS ou CIFS

Não é rara a necessidade de montar volumes NFS ou CIFS (samba) de fora do cluster Kubernetes dentro dos containers. Por baixo dos panos, o Kubernetes (que fundamentalmente usa essa funcionalidade do Docker) monta estes compartilhamentos no host em algum diretório dentro de `/var/lib/docker` e os repassas para os containers como um volume Docker.

Basicamente, o container recebe como volume um diretório do host onde o NFS/CIFS é originalmente montado.

```
/var/lib/docker/algum/nfs/montado/em/dir/do/host -> /dir/dentro/do/container
```

A montagem/desmontagem nos hosts é gerenciada automaticamente conforme o container morre e reinicia em qualquer lugar do cluster. Entretanto, é importante lembrar que o ponto original de montagem de um NFS/CIFS é no próprio host.

Serviços externos ao cluster Kubernetes não enxergam Pods e Services, muito menos os IPs destes objetos. Em uma configuração comum, a rede Kuberntes é isolada das rotas de seus hosts. Assim, para estes serviços externos, o acesso vem diretamente dos hosts.

Isto implica em duas consequências imediatas:

1. Regras firewall e autorização de acesso a estes compartilhamentos, quando necessárias, devem ser definidas com os IPs dos hosts. Será preciso liberar o acesso para todos os IPs do cluster Kubernetes, pois, pela natureza dinâmica dos containers, nunca se sabe em qual host ele será executado.

2. Pacotes relacionados a estas tecnologias de compartilhamento precisam ser instalados em todos os hosts do cluster. No caso do Ubuntu, basta instalar os pacotes `nfs-common` e `cifs-utils`.



