# 配置 Anisble

这个主题介绍如何控制 Ansible 设置。


## 配置文件

Ansible 中的某些设置项，可以通过配置文件（`ansible.cfg`）进行调整。对于大多数用户来说，现有配置应该足够了，但也可能有某些需要更改的原因。

搜索配置文件的路径，在 [参考文档](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings-locations) 中有列出。

可在配置文件中进行更改和使用，配置文件将按以下顺序进行搜索：

- `ANSIBLE_CONFIG` （若设置了该环境变量）

- `ansible.cfg` （当前目录下）

- `~/.ansible.cfg` （主目录下）

- `/etc/ansible/ansible.cfg`

Ansible 将处理上述列表，并使用找到的第一个文件，其他文件将被忽略。


### 获取最新配置

如果从软件包管理器安装 Ansible，那么最新的 `ansible.cfg` 文件应出现在 `/etc/ansible` 下，如果有更新，也可能是 `.rpmnew` 文件（或其他文件）。


如果咱们从 `pip` 或源代码安装了 Ansible，就可能需要创建此文件来覆盖 Ansible 中的默认设置。

咱们可以生成一个 Ansible 配置文件 `ansible.cfg`，其中列出了所有默认设置，如下所示：

```console
ansible-config init --disabled > ansible_quickstart/ansible.cfg
```

包含可用插件以创建更完整的 Ansible 配置，如下所示：

```console
ansible-config init --disabled -t all > ansible_quickstart/ansible.cfg
```

有关详细信息和可用配置的完整列表，请访问 [configuration_settings](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings)。

你可以使用 [ansible-config](usage/cli.md) 命令行工具列出可用选项，并检查当前值。

有关深入详情，请参阅 [Ansible 配置的设置](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings)。


## 环境配置

Ansible 还允许使用环境变量配置设置。

如果设置了这些环境变量，他们将覆盖从配置文件加载的任何相关设置。咱们可从以下网站，获取可用环境变量的完整列表：

- [Ansible 配置设置](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings)：用于配置核心功能；

- [全部专辑的环境变量索引](https://docs.ansible.com/ansible/latest/collections/environment_variables.html#list-of-collection-env-vars)：用于配置专辑中的插件。


## 命令行选项

命令行中并不包含所有配置选项，而只有那些被认为最有用，或最常用的选项。命令行中的设置，将覆盖通过配置文件与环境所传递的设置。

可用选项的完整列表，位于 [ansible-playbook](usage/cli.md) 和 [ansible](usage/cli.md) 中。


（End）


