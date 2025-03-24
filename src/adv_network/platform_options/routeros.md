# RouterOS 平台选项

RouterOS 是 [`community.network`](https://galaxy.ansible.com/ui/repo/published/community/network) 专辑的一部分，仅支持 CLI 连接和直接的 API 访问。本页提供了有关如何在 Ansible 中于 RouterOS 上使用 `ansible.netcommon.network_cli` 的详细说明。更多信息请参阅 [`community.routeros` 专辑的 SSH 指南](https://docs.ansible.com/ansible/latest/collections/community/routeros/docsite/ssh-guide.html#ansible-collections-community-routeros-docsite-ssh-guide)。


> **译注**：RouterOS 是 MicroTik 公司设备上搭载的网络操作系统。
>
> _MikroTik（正式名称为 SIA “Mikrotīkls”）是一家拉脱维亚网络设备制造公司。MikroTik 开发并销售有线和无线网络路由器、网络交换机、接入点以及操作系统和辅助软件。该公司成立于 1996 年，据报道，截至 2022 年，该公司共有 351 名员工_。
>
> _MikroTik RouterOS 是基于 Linux 内核的操作系统，专为路由器设计。他安装在该公司生产的网络硬件 RouterBOARD 和标准 x86 型计算机上，使这些设备能够实现路由器功能。RouterOS 是针对互联网服务提供商（ISP）开发的，他包含了网络管理和互联网连接的所有基本功能，包括路由选择、防火墙、带宽管理、无线接入点功能、回程链路、热点网关和 VPN 服务器功能_。
>
> _与该操作系统的通信主要通过 Winbox 进行，他提供了一个与安装在网络路由器上的 RouterOS 的图形用户界面。Winbox 为设备配置和监控提供了便利。RouterOS 还允许通过 FTP、Telnet、串行控制台、API、移动应用程序、SSH，甚至直接通过 MAC 地址（通过 WinBox）进行访问_。
>
> 参考：
>
> - [RouterOS](https://help.mikrotik.com/docs/spaces/ROS/pages/328059/RouterOS)
>
> - [MicroTik](https://en.wikipedia.org/wiki/MikroTik)


有关如何使用 RouterOS API 的信息，请参阅 [`community.routeros` 专辑的 API 指南](https://docs.ansible.com/ansible/latest/collections/community/routeros/docsite/api-guide.html#ansible-collections-community-routeros-docsite-api-guide)。


|  | `CLI` |
| :-- | :-- |
| 协议 | SSH |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 |
| 间接访问 | 通过堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` |
| `enable` 模式（权限提升） | 不受 RouterOS 支持 |
| 返回数据格式 | `stdout[0].` |


RouterOS SSH 模组不支持 `ansible_connection: local`。咱们必须使用 `ansible_connection: ansible.netcommon.network_cli`。

RouterOS API 模组则要求 `ansible_connection: local`。更多信息，请参阅 [`community.routeros` 专辑的 API 指南](https://docs.ansible.com/ansible/latest/collections/community/routeros/docsite/api-guide.html#ansible-collections-community-routeros-docsite-api-guide)。


## 在 Ansible 中使用 CLI

### 示例 CLI  `group_vars/routeros.yml`

```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.routeros
ansible_user: myuser
ansible_password: !vault...
ansible_become: true
ansible_become_method: enable
ansible_become_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```


{{#include ./ce.md:43:45}}
- 若咱们收到超时错误，则可能就要在用户名后添加 `+cet1024w` 后缀，这将禁用控制台颜色，而启用终端 `dumb` 模式，告诉 RouterOS 不要尝试检测终端能力，并将终端宽度设置为 1024 列。更多信息，请参阅 MikroTik wiki 中的 [“控制台登录过程”](https://wiki.mikrotik.com/wiki/Manual:Console_login_process) 一文；
- 更多说明请参阅 [`community.routeros` 专辑的 SSH 指南](https://docs.ansible.com/ansible/latest/collections/community/routeros/docsite/ssh-guide.html#ansible-collections-community-routeros-docsite-ssh-guide)。



### 示例 CLI 任务


```yaml
- name: Display resource statistics (routeros)
  community.network.routeros_command:
    commands: /system resource print
  register: routeros_resources
  when: ansible_network_os == 'community.network.routeros'
```



{{#include ./ce.md:193:}}
