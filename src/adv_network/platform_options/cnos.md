# CNOS 平台选项


CNOS 是 `community.network` 专辑的一部分，支持 `enable` 模式（权限提升）。本页提供了如何在 Ansible 中使用 CNOS  `enable` 模式的详细说明。

> **译注**：Cloud Network Operating System, CNOS 平台是联想 LENOVO 交换机搭载的操作系统平台。Enterprise Networking Operating System, ENOS 是联想 LENOVO 的另一交换机操作系统平台。二者都是基于 [Yotoco 项目](https://www.yoctoproject.org/)。
>
> _“CNOS 提供可靠、开放和可编程的网络基础架构，可根据您的业务需求进行扩展网络基础设施。其智能的云规模性能可提供软件定义的以太网解决方案，使用通用管理工具即可轻松管理和部署。管理，使用通用管理工具即可轻松部署。CNOS 基于行业标准，可实现数据中心内更好的支持自动化和协调应用，从而在数据中心内实现更好的互操作性。与数据中心生态系统紧密集成。”_
>
> 由于无法在 GNS3 中运行虚拟的 CNOS/ENOS 交换机，因此译者无法完成对这些设备的实验。
>
> 参考：
>
> - [`CNOS_QSG.pdf`](https://systemx.lenovofiles.com/help/topic/com.lenovo.rackswitch.g8272.doc/CNOS_QSG.pdf)
>
> - [Networking/ONIE/NOS Status](https://www.opencompute.org/wiki/Networking/ONIE/NOS_Status)


## 可用连接


|  | `CLI` |
| 协议 | SSH |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 |
| 间接访问 | 通过堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` |
| `enable` 模式（权限提升） | 受支持的：与 `ansible_become_method: enable` 及 `ansible_become_password:` 一起使用 `ansible_become: true` |
| 返回数据格式 | `stdout[0].` |


`ansible_connection: local` 已被弃用。使用 `ansible_connection: ansible.netcommon.network_cli` 代替。

## 在 Ansible 中使用 `CLI`

### 示例的 `CLI` `group_vars/cnos.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.cnos
ansible_user: myuser
ansible_password: !vault...
ansible_become: true
ansible_become_method: enable
ansible_become_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

{{#include ./ce.md:43:45}}

### 示例 `CLI` 任务

```yaml
- name: Retrieve CNOS OS version
  community.network.cnos_command:
    commands: show version
  when: ansible_network_os == 'community.network.cnos'
```

{{#include ./ce.md:193:200}}
