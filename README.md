# Introdução

Este repositório pretende hospedar um exemplo completo de uma instalação Kubernetes em barebone na língua portuguesa. Isto deve ajudar analistas e desenvolvedores a criar um cluster Kubernetes do zero usando a ferramenta [Kubespray](https://github.com/kubernetes-incubator/kubespray).

Para instalações menores, o [kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/) funciona muito bem. Entretanto, não há suporte para um cluster de alta disponibilidade (HA); o kubeadm sabe instalar somente um master com apenas uma instância `etcd`. Vários exemplos podem ser encontrados na Internet mostrando a instalação do Kubernetes no GCE ou AWS. Caso você precise fazer isso em sua própria infraestrutura (barebone), minha experiência pessoal tem mostrado o Kubespray como a melhor ferramenta.

Detalhes sobre conceitos e o funcionamento do Kubernetes pode ser encontrado na documentação oficial (https://kubernetes.io/docs/home/), cuja leitura completa é recomendada antes de iniciar atividades práticas. Outras fontes recomendadas incluem:

* [Kubernetes Anywhere](https://github.com/kubernetes/kubernetes-anywhere): Um guia detalhado de como instalar manualmente o Kubernetes no GCE ou AWS.
* [Kubernetes on CoreOS](https://coreos.com/kubernetes/docs/latest/): Outro guia que, apesar de ser direcionado à solução proprietária da CoreOS, continua sendo uma fonte bem detalhada de todos os passos necessários para uma instalação manual.

# Pré-requisitos

