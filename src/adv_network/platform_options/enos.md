# ENOS 平台选项


ENOS 是 `community.network` 专辑的一部分，支持 `enable` 模式（权限提升）。本页提供了如何在 Ansible 中于 ENOS 上使用  `enable` 模式的详细说明。

> **译注**：Enterprise Networking Operating System, ENOS 是联想公司交换机所搭载的操作系统，参见 [CNOS 平台选项](./cnos.md)。


## 可用连接


{{#include ./cnos.md:22:31}}


## 在 Ansible 中使用 CLI

### 示例 CLI `group_vars/enos.yml`

```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.enos
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
- name: Retrieve ENOS OS version
  community.network.enos_command:
    commands: show version
  when: ansible_network_os == 'community.network.enos'
```



{{#include ./ce.md:193:}}
