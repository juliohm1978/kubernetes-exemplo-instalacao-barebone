# 2 Pré-requisitos

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

## 2.1 Antes de Começar

Para um ambiente de testes, faça snapshots de suas VMs no estado inicial, apenas com o sistema operacional instalado e pronto para iniciar as atividades. Isto deve ajudar muito na hora de fazer experiências montando e desmontando seu cluster.

## 2.2 Sistema Operacional dos Hosts

Este guia usa o Ubuntu 16.04 LTS em todos os hosts. Pela natureza da solução de containers e Kubernetes, acredito que não deva encontrar maiores problemas usando outra distribuição conhecida do mercado. Confira a documentação do Kubespray para detalhes sobre distribuições suportadas.

## 2.3 Ansible
O Kubespray utiliza Ansible para relizar a instalação. Ele deve ser executado de sua estação de trabalho, instalando o Kubernetes remotamente via SSH. Assim, sua estação de trabalho precisa ter esta ferramenta instalada. Confira o [guia oficial de instalação do Ansible](http://docs.ansible.com/ansible/latest/intro_installation.html) antes de continuar. Ao momento, a versão mais recente 2.3.2.0 deve funcionar sem problemas, gerando apenas _warnings_ de incompatibilidade.

Parte da configuração do Ansible envolve preparar todos os hosts do cluster para um acesso remoto sem senha. Será preciso configurá-los com uma chave ssh, dando **acesso remoto de sua estação como usuário root pela chave**. Confira [os diversos tutoriais pela Internet](https://www.google.com.br/search?q=ssh+chave+sem+senha&oq=ssh+chave+sem+senha&aqs=chrome..69i57j0l5.5311j0j9&sourceid=chrome&ie=UTF-8) sobre como fazer isso.

Certifique-se, também, de que o Python está instalado nos hosts, pois o Ansible precisa dele para executar suas tarefas. Em um host Ubuntu, o comando abaixo deve ser o suficiente.

```
sudo apt-get install -y python
```

