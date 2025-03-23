# IronWare 平台选项

IronWare 是 [`community.network`](https://galaxy.ansible.com/ui/repo/published/community/network) 专辑的一部分，支持 `enable` 模式（权限提升）。本页提供了有关如何在 Ansible 中于 IronWare 上使用 `enable` 模式的详细介绍。


> **译注**：IronWare，或 Brocade Multi-Service IronWare OS，是搭载于已被 [Brocade](http://www.brocade.com/) 收购的Foundry 网络设备上的网络操作系统。
>
> 参考：
>
> - [Networking/ONIE/NOS Status](https://www.opencompute.org/wiki/Networking/ONIE/NOS_Status)
>
> - [BROCADE NETIRON CER 2000 SERIES](../../images/NetIron_CER_2000_DS.pdf)

## 可用连接


{{#include ./cnos.md:22:31}}


## 在 Ansible 中使用 CLI

### 示例 CLI `group_vars/mlx.yml`

```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.ironware
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
- name: Backup current switch config (ironware)
  community.network.ironware_config:
    backup: yes
  register: backup_ironware_location
  when: ansible_network_os == 'community.network.ironware'
```

{{#include ./ce.md:193:}}
