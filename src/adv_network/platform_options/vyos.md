# VyOS 平台选项

[VyOS](https://galaxy.ansible.com/ui/repo/published/vyos/vyos) 专辑支持 `ansible.netcommon.network_cli` 连接类型。本页提供了有关使用 Ansible 管理 VyOS 的连接选项详细信息。


## 可用连接


|  | `CLI` |
| :-- | :-- |
| 协议 | SSH |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 |
| 间接访问 | 通过堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` |
| `enable` 模式（权限提升） | 不受支持 |
| 返回数据格式 | 请参阅各个模组的文档 |

`ansible_connection: local` 已被弃用。请使用 `ansible_connection: ansible.netcommon.network_cli` 代替。


## 在 Ansible 中使用 CLI


### 示例 CLI `group_vars/vyos.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: vyos.vyos.vyos
ansible_user: myuser
ansible_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

{{#include ./ce.md:43:45}}


### 示例 CLI 任务

```yaml
- name: Retrieve VyOS version info
  vyos.vyos.vyos_command:
    commands: show version
  when: ansible_network_os == 'vyos.vyos.vyos'
```



{{#include ./ce.md:193:}}
