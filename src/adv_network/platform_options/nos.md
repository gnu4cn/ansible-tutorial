# NOS 平台选项


Extreme NOS 是 `community.network` 专辑的一部分，目前仅支持 CLI 连接。未来可能会添加 `httpapi` 模组。本页详细提供了关于如何在 Ansible 中于 NOS 上使用 `ansible.netcommon.network_cli` 的详细介绍。

> **译注**：Extreme NOS 是 [Extreme Networks](https://www.extremenetworks.com/) 公司搭载于其生产设备上的网络操作系统。
>
> 参考：
>
> - [Network OS (software)](https://supportdocs.extremenetworks.com/support/documentation/network-os-software-7-3-0/)


## 可用连接


|  | `CLI` |
| :-- | :-- |
| 协议 | SSH |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 |
| 间接访问 | 通过堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` |
| `enable` 模式（权限提升） | 不受 NOS 支持 |
| 返回数据格式 | `stdout[0].` |


NOS 不支持 `ansible_connection: local`。咱们必须使用 `ansible_connection: ansible.netcommon.network_cli`。


## 在 Ansible 中使用 CLI


### 示例 CLI `group_vars/nos.yml`

```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.nos
ansible_user: myuser
ansible_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

{{#include ./ce.md:43:45}}


### 示例 CLI 任务

```yaml
- name: Get version information (nos)
  community.network.nos_command:
    commands: "show version"
  register: show_ver
  when: ansible_network_os == 'community.network.nos'
```



{{#include ./ce.md:193:}}
