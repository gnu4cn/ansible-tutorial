# 使用 Ansible 命令行工具

{{#include inventories_building.md:3:7}}

欢迎阅读 Ansible 命令行工具使用指南。Ansible 提供了一些临时命令及若干实用工具，用于执行各种操作和自动化任务。


## 临时命令简介

Ansible 临时命令使用 `/usr/bin/ansible` 命令行工具，在一或多个托管节点上自动执行单个任务。那么为什么要了解临时命令呢？因为临时命令展示了 Ansible 的简单性和强大功能。咱们在这里学到的概念，将直接移植到 playbook 语言。在阅读和执行这些示例之前，请先阅读 [“如何构建仓库”](inventories_building.md)。


## 为何要使用临时命令？

对于那些很少重复的任务来说，临时命令非常有用。例如，如果咱们想在圣诞节假期，关闭实验室里所有机器的电源，咱们就可以在 Ansible 中，执行个快速单行命令，而不用编写个 playbook。临时命令看起来像这样：

```console
ansible [pattern] -m [module] -a "[module options]"
```

其中的 `-a` 选项，通过 `key=value` 语法，或为获得更复杂的选项结构，而以 `{` 开头、`}` 结尾的 JSON 字符串接受选项。你可以在其他页面了解更多关于模式和模组的信息。


## 临时任务用例


临时任务可用于重启服务器、复制文件、管理软件包与用户等。咱们可在某项临时任务中，使用任何的 Ansible 模组。与 playbook 一样，临时任务用到声明式模型，a declarative model，计算并执行达到指定最终状态的所需操作。通过在开始前检查当前状态，并除非在当前状态与指定最终状态不同时执行，从而实现某种形式的幂等性。


### 重启服务器

`ansible` 命令行实用工具的默认模组，是 `ansible.builtin.command` 模组。咱们可使用临时任务，调用该命令模组，重启亚特兰大的所有 web 服务器，每次 10 台。在 Ansible 可执行此任务前，必须将亚特兰大的所有服务器，都列在仓库中名为 `[atlanta]` 的组中，且该组中的每台机器都必须有可用的 SSH 凭据。重启 `[atlanta]` 组中的所有服务器：

```console
ansible atlanta -a "/sbin/reboot"
```

默认情况下，Ansible 只使用五个并发进程。如果主机数量超过了这个分叉数，the fork count，设定值，就会增加 Ansible 与主机通信的时间。以 10 个并行分叉，重启 `[atlanta]` 服务器：

```console
ansible atlanta -a "/sbin/reboot" -f 10
```

`/usr/bin/ansible` 将默认以咱们的用户账户运行。要以其他用户身份连接：

```console
ansible atlanta -a "/sbin/reboot" -f 10 -u username
```

重启可能需要权限提升。咱们可以使用 [`become`](playbooks.md) 关键字，以 `username` 连接服务器并以 `root` 用户身份运行命令：

```console
ansible atlanta -a "/sbin/reboot" -f 10 -u username --become [--ask-become-pass]
```

如果添加了 `--ask-become-pass` 或 `-K`，Ansible 就会提示咱们，输入用于权限提升（`sudo`/`su`/`pfexec`/`doas`等）的密码。

> **注意**：
>
> [命令模组](../collections/ansible_builtin.md) 不支持管道和重定向等扩展 `shell` 语法（尽管 `shell` 变量始终有效）。如果咱们的命令需要 `shell` 特定的语法，就要使用 `shell` 模组。


到目前为止我们的所有示例，都使用了默认的 `command` 模组。要使用其他模组，可通过 `-m` 来指定模组名称。例如，要使用 [`ansible.builtin.shell` 模组](../collections/ansible_builtin.md)：

```console
ansible raleigh -m ansible.builtin.shell -a 'echo $TERM'
```

使用 Ansible *临时* CLI（与 playbook 相反）运行任何命令时，都要特别注意 shell 的引号规则，以便本地 shell 保留变量并将其传递给 Ansible。例如，如果在上例中使用双引号而非单引号，就会在咱们所在的服务器上，对变量进行求值。


### 管理文件


临时任务可利用 Ansible 与 SCP 的强大功能，将许多文件，并行传输到多台机器上。将文件直接传输到 `[atlanta]` 组中所有服务器：

```console
ansible atlanta -m ansible.builtin.copy -a "src=/etc/hosts dest=/tmp/hosts"
```

如果计划重复执行类似任务，就要 playbook 中，使用 [`ansible.builtin.template` 模组](../collections/ansible_builtin.md)。


[`ansible.builtin.file` 模组](../collections/ansible_builtin.md) ，则允许更改文件的所有权与权限。这些选项也可以直接传递给 `copy` 模组：


```console
ansible webservers -m ansible.builtin.file -a "dest=/srv/foo/a.txt mode=600"
ansible webservers -m ansible.builtin.file -a "dest=/srv/foo/b.txt mode=600 owner=mdehaan group=mdehaan"
```

`file` 模组还可以创建目录，类似于 `mkdir -p`：


```console
ansible webservers -m ansible.builtin.file -a "dest=/path/to/c mode=755 owner=mdehaan group=mdehaan state=directory"
```

以及删除目录（递归地）与删除文件：

```console
ansible webservers -m ansible.builtin.file -a "dest=/path/to/c state=absent"
```


### 管理软件包

咱们还可以使用软件包管理模组（如 `yum`），在托管节点上安装、更新或移除软件包。软件包管理模组支持安装、移除及一般管理软件包等常用功能。包管理器的某些特定功能，可能不会出现在 Ansible 模组中，因为他们不是通用包管理的一部分。

要确保某个软件包已被安装而不进行更新：

```console
ansible webservers -m ansible.builtin.yum -a "name=acme state=present"
```
