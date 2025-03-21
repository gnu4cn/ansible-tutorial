# DELL OS9 平台选项


[`dellemc.os9`](https://github.com/ansible-collections/dellemc.os9) 专辑支持 `enable` 模式（权限提升）。本页提供了关于如何在 Ansible 中于 OS9 上使用 `enable` 模式的详细说明。


## 可用连接

{{#include ./cnos.md:22:31}}

# 在 Ansible 中使用 CLI

## 示例 CLI 的 `group_vars/dellos9.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: dellemc.os9.os9
ansible_user: myuser
ansible_password: !vault...
ansible_become: true
ansible_become_method: enable
ansible_become_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```


{{#include ./ce.md:43:45}}


### 示例 CLI 任务


```yaml
- name: Backup current switch config (dellos9)
  dellemc.os9.os9_config:
    backup: yes
  register: backup_dellos9_location
  when: ansible_network_os == 'dellemc.os9.os9'
```


{{#include ./ce.md:193:}}
