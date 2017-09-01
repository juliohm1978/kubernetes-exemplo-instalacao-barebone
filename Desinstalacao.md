# 4 Desinstalação

Caso precise, também é possível remover tudo que foi instalado e recomeçar do zero.

```
ansible-playbook reset.yml -i inventory/inventory
```

**ATENÇÃO: Este procedimento remove QUASE TUDO. Sem um backup, todas as configurações e estado atual do cluster serão perdidos.** Isto inclui todos os containers que estiverem executando no momento, todos arquivos de configuração, toda a base de dados etcd e todos os certificados que foram criados para o cluster.

Note que o script `reset.yml` remove QUASE tudo. Docker é único componente que permanece instalado. Além dele, interfaces virtuais de rede que foram criadas para a comunicação do cluster também podem ficar ativas. O resultado é aleatório e imprevisível, podendo afetar e atrapalhar instalações subsequentes no mesmo ambiente. Para um ambiente limpo, retorne o snapshots de suas VMs para um ponto inicial antes de instalar qualquer componente.

