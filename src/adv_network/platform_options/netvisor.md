# Pluribus NETVISOR 平台选项


Pluribus NETVISOR Ansible 是 [`community.network`](https://galaxy.ansible.com/ui/repo/published/community/network) 专辑的一部分，目前仅支持 CLI 连接。未来可能会添加 `httpapi` 模组。本页提供了有关如何在 Ansible 中于 NETVISOR 上使用 `ansible.netcommon.network_cli` 的详细介绍。


> **译注**：Pluribus 网络技术已被 Arista 于 2022 年 8 月收购。Pluribus NetVisor 操作系统、UNUM（管理）软件、Pluribus Freedom 9000 系列 10G、25G 及 100G 开放网络交换机家族等都已停售、停止支持，生命周期结束。
>
>
> 参考：
>
> - [Networking/ONIE/NOS Status](https://www.opencompute.org/wiki/Networking/ONIE/NOS_Status)
>
> - [Arista Networks](https://en.wikipedia.org/wiki/Arista_Networks)
>
> - [Pluribus Networks Resources](https://www.arista.com/en/support/pluribus-resources)


## 可用连接

|  | `CLI` |
| :-- | :-- |
| 协议 | SSH |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 |
| 间接访问 | 通过堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` |
| `enable` 模式（权限提升） | 不受 NETVISOR 支持 |
| 返回数据格式 | `stdout[0].` |

Pluribus NETVISOR 不支持 `ansible_connection: local`。咱们必须使用 `ansible_connection: ansible.netcommon.network_cli`。


## 在 Ansible 中使用 CLI


### 示例 CLI `group_vars/netvisor.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.netcommon.netvisor
ansible_user: myuser
ansible_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

{{#include ./ce.md:43:45}}


### 示例 CLI 任务

```yaml
- name: Create access list
  community.network.pn_access_list:
    pn_name: "foo"
    pn_scope: "local"
    state: "present"
  register: acc_list
  when: ansible_network_os == 'community.network.netvisor'
```



{{#include ./ce.md:193:}}
