# 已启用 `netconf` 的平台选项

本页提供了有关 Ansible 中 `netconf` 工作原理及使用方法的详细说明。


## 可用连接

|  | NETCONF，除 `junos_netconf` 外的那些启用了 NETCONF 的模组 |
| 协议 | 透过 SSH 的 XML |
| 凭据 | 若存在 SSH 密钥/ `ssh-agent`，则使用 SSH 密钥/ `ssh-agent`，若使用密码，则接受 `-u my_user -k` |
| 间接访问 | 经由堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.netconf` |



`ansible_connection: local` 已被弃用。请使用 `ansible_connection: ansible.netcommon.netconf`。


## 在 Ansible 中使用 NETCONF


### 启用 NETCONF


{{#include ./junos.md:56:59}}


要经由 Ansible 在新交换机上启用 NETCONF，就要通过 CLI 连接使用平台特定的模组或手动设置。比如像上面的 CLI 示例一样设置咱们的平台级变量，然后运行一个像下面这样的 playbook 任务：


{{#include ./junos.md:65:96}}


### 带有可配置变量的示例 NETCONF 任务


```yaml
- name: configure interface while providing different private key file path
  junipernetworks.junos.netconf_config:
    backup: yes
  register: backup_junos_location
  vars:
    ansible_private_key_file: /home/admin/.ssh/newprivatekeyfile
```


注意：有关 `netconf` 连接插件的可配置变量，请参阅 [`ansible.netcommon.netconf`](https://docs.ansible.com/ansible/latest/collections/ansible/netcommon/netconf_connection.html#ansible-collections-ansible-netcommon-netconf-connection)。


### 堡垒机/跳转主机配置

要使用跳转主机连接某个启用了 NETCONF 的设备，咱们必须设置 `ANSIBLE_NETCONF_SSH_CONFIG` 这个环境变量。


** `ANSIBLE_NETCONF_SSH_CONFIG` 可设置为以下其中之一**：

- `1` 或 `TRUE`（触发默认 SSH 配置文件 `~/.ssh/config` 的使用）；
- 某个自定义 SSH 配置文件的绝对路径。


SSH 配置文件看起来应是下面这样的：

```config
Host *
  proxycommand ssh -o StrictHostKeyChecking=no -W %h:%p jumphost-username@jumphost.fqdn.com
  StrictHostKeyChecking no
```

跳转主机的身份验证，必须使用基于密钥的身份验证。


咱们既可以在 SSH 配置文件中，指定出所使用的私钥：

```config
IdentityFile "/absolute/path/to/private-key.pem"
```

也可以使用某种 `ssh-agent`。


### `ansible_network_os` 的自动检测

如果没有为某个主机指定 `ansible_network_os` 变量，则 Ansible 将尝试自动检测要使用的 `network_os` 插件。


`ansible_network_os` 自动检测也可以通过使用 `auto` 作为 `ansible_network_os` 变量的值来触发。(注意：早先使用的是 `default` 代替 `auto`）。




{{#include ./ce.md:193:}}
