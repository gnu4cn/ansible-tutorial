# IOS-XR 平台选项

[思科 IOS-XR 专辑](https://galaxy.ansible.com/ui/repo/published/cisco/iosxr) 专辑支持多种连接。本页提供了有关每种连接在 Ansible 中工作原理及使用方法的详细介绍。


## 可用连接


|  | CLI | NETCONF，仅限于 `iosxr_banner`、`iosxr_interface`、`iosxr_logging`、`iosxr_system` 与 `ios_user` 模组 |
| 协议 | SSH | 透过 SSH 的 XML |
| 凭据 | 若存在 SSH 密钥/ `ssh-agent`，则使用 SSH 密钥/ `ssh-agent`，若使用密码，则接受 `-u my_user -k` | 若存在 SSH 密钥/ `ssh-agent`，则使用 SSH 密钥/ `ssh-agent`，若使用密码，则接受 `-u my_user -k` |
| 间接访问 | 使用堡垒机（跳转主机） | 使用堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` | `ansible_connection: ansible.netcommon.netconf` |
| `enable` 模式（权限提升） | 不支持 | 不支持 |
| 返回数据格式 | 请参考单独模组文档 | 请参考单独模组文档 |


`ansible_connection: local` 已被弃用。请使用 `ansible_connection: ansible.netcommon.netconf` 或 `ansible_connection=ansible.netcommon.network_cli` 代替。


## 在 Ansible 中使用 CLI

### 示例 CLI 仓库 `[iosxr:vars]`

```ini
[iosxr:vars]
ansible_connection=ansible.netcommon.network_cli
ansible_network_os=cisco.iosxr.iosxr
ansible_user=myuser
ansible_password=!vault...
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

{{#include ./ce.md:43:45}}


### 示例 CLI 任务

```yaml
- name: Retrieve IOS-XR version
  cisco.iosxr.iosxr_command:
    commands: show version
  when: ansible_network_os == 'cisco.iosxr.iosxr'
```


## 在 Ansible 中使用 NETCONF


### 启用 NETCONF

在咱们使用 NETCONF 连接交换机前，咱们必须：

- 使用 `pip install ncclient` 命令，在控制节点上安装 `ncclient` 这个 python 软件包；
- 在思科 IOS-XR 设备上启用 NETCONF。


要在 Ansible 下于某个新交换机上启用 NETCONF，可通过 CLI 连接使用 `cisco.iosxr.iosxr_netconf` 模组。像上面的 CLI 示例一样，设置咱们的平台级变量，然后运行一个如下的 playbook 任务：


```yaml
- name: Enable NETCONF
  connection: ansible.netcommon.network_cli
  cisco.iosxr.iosxr_netconf:
  when: ansible_network_os == 'cisco.iosxr.iosxr'
```

在 NETCONF 启用后，就要把咱们的变量修改为使用 NETCONF 连接。


### 示例 NETCONF 仓库 `[iosxr:vars]`


```ini
[iosxr:vars]
ansible_connection=ansible.netcommon.netconf
ansible_network_os=cisco.iosxr.iosxr
ansible_user=myuser
ansible_password=!vault |
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```


### 示例 NETCONF 任务

```yaml
- name: Configure hostname and domain-name
  cisco.iosxr.iosxr_system:
    hostname: iosxr01
    domain_name: test.example.com
    domain_search:
      - ansible.com
      - redhat.com
      - cisco.com
```

{{#include ./ce.md:193:}}
