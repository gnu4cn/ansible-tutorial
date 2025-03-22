# ERIC_ECCLI 平台选项


Extreme `ERIC_ECCLI` 是 [`community.network`](https://galaxy.ansible.com/ui/repo/published/community/network) 专辑的一部分，眼下仅支持 CLI 连接。本页给出了关于如何在 Ansible 中于 ERIC_ECCLI 上使用 `ansible.netcommon.network_cli` 的详细介绍。


> **译注**：这是爱立信 Ericsson 网络设备的操作系统平台，公开资料很少。将在 `community.network` 专辑 `6.0.0` 版本中弃用。


## 可用连接


{{#include ./cnos.md:22:31}}


`ERIC_ECCLI` 不支持 `ansible_connection: local`。咱们必须使用 `ansible_connection: ansible.netcommon.network_cli`。


## 在 Ansible 中使用 CLI


### 示例 CLI `group_vars/eric_eccli.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.eric_eccli
ansible_user: myuser
ansible_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```


{{#include ./ce.md:43:45}}


### 示例 CLI 任务


```yaml
- name: run show version on remote devices (eric_eccli)
  community.network.eric_eccli_command:
     commands: show version
  when: ansible_network_os == 'community.network.eric_eccli'
```



{{#include ./ce.md:193:}}
