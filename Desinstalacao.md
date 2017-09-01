# 4 Desinstalação

Caso precise, também é possível remover a estrutura que foi instalada e recomeçar.

```
ansible-playbook reset.yml -i inventory/inventory
```


## CUIDADO

O playbook `reset.yml` remove **QUASE TUDO**. Sem um backup, todas as configurações e estado atual do cluster serão perdidos. Isto inclui todos os containers que estiverem executando no momento, todos arquivos de configuração, toda a base de dados etcd e todos os certificados que foram criados para o cluster.

Como dito anteriomente, o `reset.yml` **remove quase tudo, mas não remove tudo.** O Docker permanece instalado. Imagens Docker que foram baixadas continuam armazenadas nos hosts.

Em especial, as interfaces virtuais de rede que foram criadas para a comunicação do cluster também podem ficar ativas e mal configuradas. O resultado é imprevisível, podendo afetar e atrapalhar instalações subsequentes no mesmo ambiente.

Para começar novamente com um ambiente limpo, retorne o snapshots de suas VMs para um ponto inicial antes da instalação de qualquer componente.


