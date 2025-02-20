# 连接插件


连接插件允许 Ansible 连接到目标主机，从而他可在目标主机上执行任务。Ansible 随附了许多连接插件，但同一时间每台主机只能使用一种。

默认情况下，Ansible 附带多个连接插件。最常用到的是 [`paramiko` SSH](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/paramiko_ssh_connection.html#paramiko-connection)、原生 ssh（只称为 [`ssh`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html#ssh-connection)）与 [`local`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/local_connection.html#local-connection) 三种连接类型。所有这些插件都可用于 playbook 中和 `/usr/bin/ansible`，以决定咱们打算与远端机器对话的方式。如有必要，咱们还可 [创建定制连接插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-connection-plugins)。要更改咱们任务的连接插件，可使用 `connection` 关键字。


这些连接类型的基础知识，在 [入门](https://docs.ansible.com/ansible/2.9/user_guide/intro_getting_started.html#intro-getting-started) 小节中有讲到。


## `ssh` 插件

由于 SSH 是系统管理中用到的默认协议，也是 Ansible 中使用最多的协议，因此 SSH 的那些选项，就被包含在了命令行工具中。详情请参阅 [`ansible-playbook`](../cli/ansible-playbook.md)。


## 使用连接插件


咱们可以通过 [ Ansible 配置](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 全局地设置连接插件、通过命令行（`-c`、`--connection`）设置、通过咱们 play 中的 [关键字](https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html#playbook-keywords) 设置，或设置一个通常在咱们仓库中的 [变量](../inventories_building.md#连接主机行为清单参数)。例如，对于 Windows 机器，咱们可能需要将 `winrm` 插件设置为一个仓库变量。

大多数连接插件都只需最少配置即可运行。默认情况下，他们使用 [仓库主机名](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/inventory_hostnames_lookup.html#inventory-hostnames-lookup) 与默认设置，查找目标主机。

这些插件都自带文档。各个插件都应记录其配置选项。以下是大多数连接插件通用的及各连接变量：


- `ansible_host`：在不同于 [仓库](../inventories_building.md#如何建立仓库) 主机时，要连接的主机名；
- `ansible_port`：ssh 的端口号，对于 [`ssh`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html#ssh-connection) 与 [`paramikoo_ssh`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/paramiko_ssh_connection.html#paramiko-connection) 其默认为 `22`；
- `ansible_user`：用于登录的默认用户名。大多数连接插件都默认为 “运行 Ansible 的当前用户”。


各个插件还可能有覆盖某个变量通用版本的指定版本。例如，[`ssh`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html#ssh-connection) 插件的 `ansible_ssh_host` 变量。


## 插件列表

咱们可使用 `ansible-doc -t connection -l` 命令查看可用插件的列表。使用 `ansible-doc -t connection <plugin name>` 命令查看特定插件的文档与示例。


（End）

