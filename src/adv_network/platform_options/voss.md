# VOSS 平台选项

Extreme VOSS 是 [`community.network`](https://galaxy.ansible.com/ui/repo/published/community/network) 专辑的一部分，目前仅支持 CLI 连接。本页提供了有关如何在 Ansible 中于 VOSS 上使用 `ansible.netcommon.network_cli` 的详细介绍。

> **译注**：有关 Extreme networks 的平台，已有：
>
> - [Extreme ERIC_ECCLI](./eric_eccli.md)
>
> - [Extreme EXOS](./exos.md)
>
> - [Extreme SLX-OS](./slx-os.md)
>
> 参考：
>
> - [VSP Operating System Software (VOSS)](https://supportdocs.extremenetworks.com/support/documentation/vsp-operating-system-software-voss-8-0-0/)


## 可用连接

|  | `CLI` |
| :-- | :-- |
| 协议 | SSH |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 |
| 间接访问 | 通过堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` |
| `enable` 模式（权限提升） | 受支持的：与 `ansible_become_method: enable` 一起使用 `ansible_become: true` |
| 返回数据格式 | `stdout[0].` |

VOSS 不支持 `ansible_connection: local`。咱们必须使用 `ansible_connection: ansible.netcommon.network_cli`。


## 在 Ansible 中使用 CLI

### 示例 CLI `group_vars/voss.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.voss
ansible_user: myuser
ansible_become: true
ansible_become_method: enable
ansible_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

{{#include ./ce.md:43:45}}


### 示例 CLI 任务

```yaml
- name: Retrieve VOSS info
  community.network.voss_command:
    commands: show sys-info
  when: ansible_network_os == 'community.network.voss'
```


{{#include ./ce.md:193:}}
