# Junos OS 平台选项

[瞻博网络 Juniper Junos OS](https://galaxy.ansible.com/ui/repo/published/junipernetworks/junos) 支持多种连接。本页提供了有关在 Ansible 中每种连接工作原理及使用方法的详细介绍。


## 可用连接


|  | CLI，仅限 `junos_netconf`、`junos_command` 与 `junos_ping` 模组 | NETCONF，除 `junos_netconf` 外的那些启用了 NETCONF 的模组 |
| :-- | :-- | :-- |
| 协议 | SSH | 透过 SSH 的 XML |
| 凭据 | 若存在 SSH 密钥/ `ssh-agent`，则使用 SSH 密钥/ `ssh-agent`，若使用密码，则接受 `-u my_user -k` | 若存在 SSH 密钥/ `ssh-agent`，则使用 SSH 密钥/ `ssh-agent`，若使用密码，则接受 `-u my_user -k` |
| 间接访问 | 使用堡垒机（跳转主机） | 使用堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` | `ansible_connection: ansible.netcommon.netconf` |
| `enable` 模式（权限提升） | 不受 Junos OS 支持 | 不受 Junos OS 支持 |
| 返回数据格式 | `stdout[0].` | <li>json: <code>result[0]['software-information'][0]['host-name'][0]['data'] foo lo0</code></li><li>text: <code>result[1].interface-information[0].physical-interface[0].name[0].data foo lo0</code></li><li>xml: <code>result[1].rpc-reply.interface-information[0].physical-interface[0].name[0].data foo lo0</code></li>


`ansible_connection: local` 已被弃用。请使用 `ansible_connection: ansible.netcommon.netconf` 或 `ansible_connection=ansible.netcommon.network_cli` 代替。


## 在 Ansible 中使用 CLI

### 示例 CLI 仓库变量 `[junos:vars]`


```ini
[junos:vars]
ansible_connection=ansible.netcommon.network_cli
ansible_network_os=junipernetworks.junos.junos
ansible_user=myuser
ansible_password=!vault...
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```


{{#include ./ce.md:43:45}}


### 示例 CLI 任务


```yaml
- name: Retrieve Junos OS version
  junipernetworks.junos.junos_command:
    commands: show version
  when: ansible_network_os == 'junipernetworks.junos.junos'
```


## 在 Ansible 中使用 NETCONF

### 启用 NETCONF


在咱们可以使用 NETCONF 连接交换机前，咱们必须：

- 使用 `pip install ncclient`（`python -m pip install ncclient`）命令，在控制节点上安装 `ncclient` 这个 python 软件包；
- 在 Junos OS 设备上启用 NETCONF。


要经由 Ansible 在新交换机上启用 NETCONF，就要通过 CLI 连接使用 `junipernetworks.junos.junos_netconf` 这个模组。像上面的 CLI 示例中一样，设置咱们平台级变量，然后运行一个如下的 playbook 任务：


```yaml
- name: Enable NETCONF
  connection: ansible.netcommon.network_cli
  junipernetworks.junos.junos_netconf:
  when: ansible_network_os == 'junipernetworks.junos.junos'
```

启用 NETCONF 后，就要修改咱们的变量，以使用 NETCONF 连接。


### 示例 NETCONF 仓库的 `[junos:vars]`


```ini
[junos:vars]
ansible_connection=ansible.netcommon.netconf
ansible_network_os=junipernetworks.junos.junos
ansible_user=myuser
ansible_password=!vault |
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```


### 示例 NETCONF 任务

```yaml
- name: Backup current switch config (junos)
  junipernetworks.junos.junos_config:
    backup: yes
  register: backup_junos_location
  when: ansible_network_os == 'junipernetworks.junos.junos'
```

{{#include ./ce.md:193:}}
