# 1 Introdução

Este repositório pretende hospedar um exemplo completo de uma instalação Kubernetes em barebone na língua portuguesa. Isto deve ajudar analistas e desenvolvedores a criar um cluster Kubernetes em uma infraestrutura própria usando a ferramenta [Kubespray](https://github.com/kubernetes-incubator/kubespray).

Para instalações menores, o [kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/) funciona muito bem. Muitos exemplos e tutoriais já existem. Entretanto, kubeadm não suporta um cluster de alta disponibilidade (HA); consegue instalar somente um master com apenas uma instância etcd. Ademais, vários exemplos podem ser encontrados mostrando a instalação do Kubernetes no GCE ou AWS. Caso você precise fazer isso em sua própria infraestrutura (barebone), minha experiência pessoal tem mostrado o Kubespray como a melhor ferramenta.

Os passos deste guia foram criados a partir de experiência própria com a instalação do Kubernetes, experimentando e recriando o mesmo ambiente de várias formas para observar o resultado. Fontes recomendadas de leitura e pesquisa incluem:

* [Documentação oficial do Kubernetes](https://kubernetes.io/docs/home/): Indispensável e sem comentários.
* [Kubernetes Anywhere](https://github.com/kubernetes/kubernetes-anywhere): Um guia detalhado de como instalar manualmente o Kubernetes no GCE ou AWS.
* [Kubernetes on CoreOS](https://coreos.com/kubernetes/docs/latest/): Apesar de ser direcionado à solução proprietária da CoreOS, contém muitos detalhes necessários para uma instalação manual.
* [Repositório oficial Kubernetes](https://github.com/kubernetes/kubernetes): A comunidade no Github está muito ativa e dinâmica. Diversas discussões e solução de problemas já existem na seção de issues. Antes de desistir, confira se alguém já passou pelos problemas que você enfrenta.

Confira adiante os demais capítulos do guia:

## 2 [Pré-requisitos](PreRequisitos.md)  
## 3 [Instalação Kubernetes](Instalacao.md)  
## 4 [Desinstalação](Desinstalacao.md)  
## 5 [Backup e Restauração](BackupRestauracao.md)