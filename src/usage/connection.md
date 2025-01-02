# 连接方式与细节

本节展示了如何扩展和完善， Ansible 用于仓库的连接方法。


## `ControlPersist` 与 `paramiko`

默认情况下，Ansible 使用原生的 OpenSSH，因为他支持 `ControlPersist`（一项性能特性）、Kerberos 以及 `~/.ssh/config` 中的选项，比如跳转主机设置，Jump Host setup。如果咱们的控制机器，使用了是不支持 `ControlPersist` 的旧版 OpenSSH，那么 Ansible 将退回到名为 `paramiko` 的 OpenSSH Python 实现。


### 设置远端用户

默认情况下，Ansible 会使用控制节点上的用户名，连接所有远端设备。如果远端设备上不存在该用户名，则可以为连接设置别的用户名。如果咱们只需要以别的用户身份，完成某些任务，请参阅 [了解权限提升：`become`](playbooks.md)。咱们可以在 playbook 中设置连接用户：


```yaml
---
- name: update webservers
  hosts: webservers
  remote_user: admin

  tasks:
  - name: thing to do first in this playbook
  . . .
```

作为仓库中的主机变量：

```ini
other1.example.com     ansible_connection=ssh        ansible_user=myuser
other2.example.com     ansible_connection=ssh        ansible_user=myotheruser
```

或仓库中的组变量：


```yaml
cloud:
  hosts:
    cloud1: my_backup.cloud.com
    cloud2: my_backup2.cloud.com
  vars:
    ansible_user: admin
```

> **参阅**：
>
> - [`ssh_connection`](../collections/ansible_builtin.md)
>
> `remote_user` 关键字与 `ansible_user` 变量的细节。
>
> [控制 Ansible 的行为方式：优先级规则](../refs/precedence.md)
>
> 有关 Ansible 优先级的详情。


## 设置 SSH 密钥


默认情况下，Ansible 假定咱们正使用 SSH 密钥，连接远端机器。我们鼓励使用 SSH 密钥，但如果需要，也可以 `--ask-pass` 选项，使用口令认证。如果需要为 [权限提升](playbooks.md)（`sudo`、`pbrun` 等）提供密码，请使用 `--ask-become-pass` 选项。


> **注意**：在使用 `ssh` 连接插件时（默认情况），Ansible 没有提供允许用户与 `ssh` 进程通信，以便手动接受密码来解密 `ssh` 密钥的通道。强烈建议使用 `ssh-agent`。


要设置 SSH 代理以避免重复输入密码，咱们可以这样做：

```console
ssh-agent bash
ssh-add ~/.ssh/id_rsa
```

根据咱们的设置，咱们可能希望使用 Ansible 的 `--private-key` 命令行选项，来指定 `pem` 文件。咱们还可以添加私钥文件：

```console
ssh-agent bash
ssh-add ~/.ssh/keypair.pem
```

另一种不使用 `ssh-agent` 添加私钥文件的方法，是在仓库文件中使用 `ansible_ssh_private_key_file`，如此处所述： [如何创建咱们的仓库](inventories_building.md#ansible_ssh_private_key_file)。


## 针对 `localhost` 运行


咱们可使用 `localhost` 或 `127.0.0.1`，作为服务器名称，在控制节点上运行命令：


```console
ansible localhost -m ping -e 'ansible_python_interpreter="/usr/bin/env python"'
```

咱们可以通过将其添加到仓库文件中，显式指定出 `localhost`：


```ini
localhost ansible_connection=local ansible_python_interpreter="/usr/bin/env python"
```


## 管理主机密钥检查


Ansible 默认启用了主机密钥检查。检查主机密钥，可防止服务器欺骗和中间人攻击，但需要一定维护。


如果某台主机重新安装了系统，并在 `known_hosts` 中使用了不同密钥，就会出现错误信息，直到更正为止。如果新主机不在 `known_hosts` 中，那么控制节点就会提示确认密钥，这将导致在比如 `cron` 中使用 Ansible 时，出现交互式体验问题。你可能不希望这样。


如果咱们了解其影响，并希望禁用此行为，可以通过编辑 `/etc/ansible/ansible.cfg` 或 `~/.ansible.cfg` 来禁用：


```ini
[defaults]
host_key_checking = False
```

或者，也可以通过 [`ANSIBLE_HOST_KEY_CHECKING`](../refs/config.md) 环境变量来设置：


```console
export ANSIBLE_HOST_KEY_CHECKING=False
```


还请注意，`paramiko` 模式下的主机密钥检查速度相当慢，因此建议在使用这项功能时，切换到 `ssh` 模式。



## 其他连接方式


除 SSH 外，Ansible 还能使用多种连接方法。咱们可选择任何的连接插件，包括本地管理、`chroot` 管理、`lxc` 管理及 `jail` 容器管理等。名为 `ansible-pull` 的模式还能反转系统，通过计划的 Git 签出，从中心化代码仓库拉取配置指令，而让系统 “打电话回家，phone home”。
