# EXOS 平台选项

Extreme EXOS 是 [`community.network`](https://galaxy.ansible.com/ui/repo/published/community/network) 专辑的一部分，支持多种连接。本页提供了有关在 Ansible 中各种连接工作原理及使用方法的详细介绍。


> **译注**：
> ExtremeXOS 是用于 Extreme Networks 较新型号网络交换机的软件或网络操作系统。他是 Extreme Networks 继基于 VxWorks 的 ExtremeWare 操作系统之后的第二代操作系统。
>
> ExtremeXOS 基于 Linux 内核和 BusyBox。2008 年 7 月，Extreme Networks 因涉嫌违反 GNU 通用公共许可证而遭到法律诉讼。三个月后，该诉讼达成庭外和解。
>
> 参考：
>
> - [ExtremeXOS](https://en.wikipedia.org/wiki/ExtremeXOS)


## 可用连接


|  | CLI | EXOS-API |
| 协议 | SSH | HTTP(S) |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 | 存在 HTTPS 证书时使用 HTTPS 证书 |
| 间接访问 | 通过堡垒机（跳转主机） | 经由 web 代理 |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` | `ansible_connection: ansible.netcommon.httpapi` |
| `enable` 模式（权限提升） | 不受 EXOS 支持 | 不受 EXOS 支持 |
| 返回的数据格式 | `stdout[0].` | `stdout[0].messages[0].` |


EXOS 不支持 `ansible_connection: local`。咱们必须使用 `ansible_connection: ansible.netcommon.network_cli` 或 `ansible_connection: ansible.netcommon.httpapi`。


## 在 Ansible 中使用 CLI


### 示例 CLI `group_vars/exos.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.exos
ansible_user: myuser
ansible_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

{{#include ./ce.md:43:45}}

### 示例 CLI 任务


```yaml
- name: Retrieve EXOS OS version
  community.network.exos_command:
    commands: show version
  when: ansible_network_os == 'community.network.exos'
```


## 在 Ansible 中使用 `EXOS-API`


### 示例 `EXOS-API` `group_vars/exos.yml`


```yaml
ansible_connection: ansible.netcommon.httpapi
ansible_network_os: community.network.exos
ansible_user: myuser
ansible_password: !vault...
proxy_env:
  http_proxy: http://proxy.example.com:8080
```


{{#include ./eos.md:112:113}}


### 示例 `EXOS-API` 任务

```yaml
- name: Retrieve EXOS OS version
  community.network.exos_command:
    commands: show version
  when: ansible_network_os == 'community.network.exos'
```

在这个示例中，`group_vars` 中定义的 `proxy_env` 变量，被传递给任务中模组的 `environment` 选项。


{{#include ./ce.md:193:}}
