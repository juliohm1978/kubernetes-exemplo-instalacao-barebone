# Introdução

Este repositório pretende hospedar um exemplo completo de uma instalação Kubernetes em barebone na língua portuguesa. Isto deve ajudar analistas e desenvolvedores a criar um cluster Kubernetes do zero usando a ferramenta [Kubespray](https://github.com/kubernetes-incubator/kubespray).

Para instalações menores, o [kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/) funciona muito bem. Entretanto, não há suporte para um cluster de alta disponibilidade (HA); o kubeadm sabe instalar somente um master com apenas uma instância `etcd`.
