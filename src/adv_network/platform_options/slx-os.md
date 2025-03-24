# SLX-OS 平台选项

Extreme SLX-OS 是 [`community.network`](https://galaxy.ansible.com/ui/repo/published/community/network) 专辑的一部分，目前仅支持 CLI 连接。未来可能会添加 `httpapi` 模组。本页提供了有关如何在 Ansible 中于 SLX-OS 上使用 `ansible.netcommon.network_cli` 的详细说明。

> **译注**：有关 Extreme networks 的平台，已有：
>
> - [Extreme ERIC_ECCLI](./eric_eccli.md)
>
> - [Extreme EXOS](./exos.md)
>
> 参考：
>
> - [SLX-OS Series (software)](https://supportdocs.extremenetworks.com/support/documentation/slx-os-20-6-1/)


## 可用连接


|  | `CLI` |
| :-- | :-- |
| 协议 | SSH |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 |
| 间接访问 | 通过堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` |
| `enable` 模式（权限提升） | 不受 SLX-OS 支持 |
| 返回数据格式 | `stdout[0].` |

SLX-OS 不支持 `ansible_connection: local`。咱们必须使用 `ansible_connection: ansible.netcommon.network_cli`。


## 在 Ansible 中使用 CLI

### 示例 CLI `group_vars/slxos.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.slxos
ansible_user: myuser
ansible_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

{{#include ./ce.md:43:45}}


### 示例 CLI 任务

```yaml
- name: Backup current switch config (slxos)
  community.network.slxos_config:
    backup: yes
  register: backup_slxos_location
  when: ansible_network_os == 'community.network.slxos'
```



{{#include ./ce.md:193:}}
