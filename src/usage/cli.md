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
ansible webservers -m ansible.builtin.yum -a "name=nginx state=present"
```

> **译注**：运行以下命令，使用针对 Debian 12 的模组 `ansible.builtin.apt`，在远端 Debian 主机上安装 Nginx 也是成功的。

```console
ansible webservers -m ansible.builtin.apt -a "name=nginx state=present" --become -K
```


要确保安装了特定版本的某个软件包：


```console
$ ansible webservers -m ansible.builtin.yum -a "name=nginx-1.20.1 state=present"
```

确保软件包是最新版本：


```console
$ ansible webservers -m ansible.builtin.yum -a "name=nginx state=latest"
```

确保未安装（移除）某个软件包：

```console
$ ansible webservers -m ansible.builtin.yum -a "name=nginx state=absent"
```

> **译注**：Ansible 返回的输出如下：


```json
nginx_39 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": true,
    "msg": "",
    "rc": 0,
    "results": [
        "Removed: nginx-2:1.20.1-20.el9.alma.1.x86_64"
    ]
}
```


Ansible 有着在许多平台下，用于管理软件包的模组。如果没有用于咱们软件包管理器的模组，咱们可以使用 `command` 模组安装软件包，或者为咱们的软件包管理器创建个模组。


### 管理用户与用户组

咱们可以通过临时任务，在托管节点上创建、管理和删除用户账户：

```console
ansible all -m ansible.builtin.user -a "name=foo password=<encrypted password here>"

ansible all -m ansible.builtin.user -a "name=foo state=absent"
```

请参阅 [ansible.builtin.user](../collections/ansible_builtin.md) 模组文档，了解所有可用选项的详情，包括如何操作组和组成员。


### 管理服务

确保所有 `webservers` 上启动了某项服务：

```console
ansible webservers -m ansible.builtin.service -a "name=nginx state=started"
```

或者，重新启动所有 `webservers` 上的某项服务：

```console
ansible webservers -m ansible.builtin.service -a "name=nginx state=restarted"
```

确保某项服务已停止：

```console
ansible webservers -m ansible.builtin.service -a "name=nginx state=stopped"
```


### 收集事实

所谓事实，facts，表示所发现有关系统的一些变量。咱们可以使用事实，实现任务的有条件执行，也可以直接获取系统的一些信息。要查看所有事实：


```console
ansible all -m ansible.builtin.setup
```

咱们也可以过滤此输出，而只显示某些事实，详情请查看 [ansible.builtin.setup](../collections/ansible_builtin.md) 模组文档。


## 检查模式

在检查模式下，Ansible 不会对远端系统做任何更改。Ansible 只打印出命令。他不会运行命令。

```console
ansible all -m copy -a "content=foo dest=/root/bar.txt" -C
```

在上面的命令中启用检查模式（`-C` 或 `--check`），意味着 Ansible 不会在任何远端系统上，创建或更新 `/root/bar.txt` 文件。


## 模式与临时命令

有关所有可用选项的详细信息，包括如何在临时命令中使用模式加以限制，请参阅 [模式](patterns.md) 文档。

现在咱们已经了解了 Ansible 执行的基本要素，就可以学习使用 [Ansible Playbooks](playbooks.md)，自动执行重复性任务了。


## 使用命令行工具


大多数用户都熟悉 `ansible` 和 `ansible-playbook`，但他们并不是 Ansible 提供的仅有实用工具。下面是 Ansible 实用工具的完整列表。每个页面都包含该实用程序的说明，和支持的参数列表。


> **注意**：咱们不应针对相同目标，并行运行大多数 Ansible CLI 工具。

- [`ansible`](#ansible)
- [`ansible-config`](#ansible-config)
- [`ansible-console`](#ansible-console)
- [`ansible-doc`](#ansible-doc)
- [`ansible-galaxy`](#ansible-galaxy)
- [`ansible-inventory`](#ansible-inventory)
- [`ansible-playbook`](#ansible-playbook)
- [`ansible-pull`](#ansible-pull)
- [`ansible-vault`](#ansible-vault)

### `ansible`

定义和运行针对一组主机的单个任务 playbook。

**简介**

```console
usage: ansible [-h] [--version] [-v] [-b] [--become-method BECOME_METHOD]
            [--become-user BECOME_USER]
            [-K | --become-password-file BECOME_PASSWORD_FILE]
            [-i INVENTORY] [--list-hosts] [-l SUBSET] [-P POLL_INTERVAL]
            [-B SECONDS] [-o] [-t TREE] [--private-key PRIVATE_KEY_FILE]
            [-u REMOTE_USER] [-c CONNECTION] [-T TIMEOUT]
            [--ssh-common-args SSH_COMMON_ARGS]
            [--sftp-extra-args SFTP_EXTRA_ARGS]
            [--scp-extra-args SCP_EXTRA_ARGS]
            [--ssh-extra-args SSH_EXTRA_ARGS]
            [-k | --connection-password-file CONNECTION_PASSWORD_FILE] [-C]
            [-D] [-e EXTRA_VARS] [--vault-id VAULT_IDS]
            [-J | --vault-password-file VAULT_PASSWORD_FILES] [-f FORKS]
            [-M MODULE_PATH] [--playbook-dir BASEDIR]
            [--task-timeout TASK_TIMEOUT] [-a MODULE_ARGS] [-m MODULE_NAME]
            pattern
```

**描述**

是一个简单的工具/框架/API，用于执行 “远端操作”。此命令允许咱们，针对一组主机定义并运行单个任务的 playbook。

**常见选项**

- `--become-method <BECOME_METHOD>`

权限提升方式（`default=sudo`），使用 `ansible-doc -t become -l` 列出有效选项。

- `--become-password-file <BECOME_PASSWORD_FILE>, --become-pass-file <BECOME_PASSWORD_FILE>`

`become` 的口令文件。

- `--become-user <BECOME_USER>`

以该用户身份运行操作（`default=root`）。

- `--connection-password-file <CONNECTION_PASSWORD_FILE>, --conn-pass-file <CONNECTION_PASSWORD_FILE>`

连接的口令文件。

- `--list-hosts`

输出匹配主机的列表；不执行任何其他操作。

- `--playbook-dir <BASEDIR>`

由于该工具不使用 playbook，因此可将其用作替代的 playbook 目录。这将为许多功能设置相对路径，包括 `roles/`、`group_vars/` 等。

- `--private-key <PRIVATE_KEY_FILE>, --key-file <PRIVATE_KEY_FILE>`

使用此文件来认证连接。

- `--scp-extra-args <SCP_EXTRA_ARGS>`

指定仅传递给 `scp` 的额外参数（如 `-l`）。

- `--sftp-extra-args <SFTP_EXTRA_ARGS>`

指定仅传递给 `sftp` 的额外参数（如 `-f`、`-l`）。

- `--ssh-common-args <SSH_COMMON_ARGS>`

指定传递给 `sftp`/`scp`/`ssh` 的公共参数（如 `ProxyCommand`）。

- `--ssh-extra-args <SSH_EXTRA_ARGS>`

指定仅传递给 `ssh` 的额外参数（如 `-R`）。

- `--task-timeout <TASK_TIMEOUT>`

设置任务超时限制（秒），必须为正整数。

- `--vault-id`

要使用的保险库标识。该参数可指定多次。

- `--vault-password-file, --vault-pass-file`

保鲜库口令文件。

- `--version`

显示程序的版本号、配置文件位置、所配置的模组搜索路径、模组位置、可执行文件位置并退出。

- `-B <SECONDS>`

异步运行，`X` 秒后失败（`default=N/A`）。

- `-C, --check`

不做任何改变，而是尝试预测可能发生的一些变化。

- `-D, --diff`

更改（小）文件和模板时，显示这些文件的差异；与 `--check` 一起使用效果极佳。

- `-J, --ask-vault-password, --ask-vault-pass`

询问保险库口令。

- `-K, --ask-become-pass`

询问权限提升口令。

- `-M, --module-path`

添加以冒号分隔的路径，作为模组库（`default={{ ANSIBLE_HOME ~ "/plugins/modules:/usr/share/ansible/plugins/modules" }}`）。此参数可指定多次。

- `-P <POLL_INTERVAL>, --poll <POLL_INTERVAL>`

如果使用 `-B` 选项，则设置轮询间隔（`default=15`）。

- `-T <TIMEOUT>, --timeout <TIMEOUT>`

覆盖连接超时，以秒为单位（默认值取决于连接方式）。

- `-a <MODULE_ARGS>, --args <MODULE_ARGS>`

以空格分隔的 `k=v` 格式： `-a 'opt1=val1 opt2=val2'`，或 JSON 字符串： `-a '{"opt1"： "val1", "opt2"： "val2"}'` 形式的该操作的选项。

- `-b, --become`

以 `become` 运行操作（并不意味着密码提示符）。

- `-c <CONNECTION>, --connection <CONNECTION>`

要使用的连接类型（`default=ssh`）。

- `-e, --extra-vars`

以 `key=value` 方式， 或文件名前添加了 `@` 的 YAML/JSON 方式，设置一些额外变量。此参数可指定多次。

- `-f <FORKS>, --forks <FORKS>`

指定要使用的并行进程数（`default=5`）。

- `-h, --help`

打印此帮助消息并退出。

- `-i, --inventory`

指定仓库主机路径，或逗号分隔的主机列表。`-inventory-file` 选项已被弃用。该参数可指定多次。

- `-k, --ask-pass`

询问连接口令。

- `-l <SUBSET>, --limit <SUBSET>`

将选定主机进一步限制为额外模式。

- `-m <MODULE_NAME>, --module-name <MODULE_NAME>`

要执行的操作名称（`default=command`）。

- `-o, --one-line`

压缩输出。

- `-t <TREE>, --tree <TREE>`

记录日志输出到此目录。

- `-u <REMOTE_USER>, --user <REMOTE_USER>`

以该用户身份连接（`default=None`）。

- `-v, --verbose`

会导致 Ansible 打印更多调试信息。添加多个 `-v` 会增加调试信息的冗余度，内置插件目前最多会评估到 `-vvvvv`。 开始时的合理级别是 `-vvv`，连接的调试则可能需要 `-vvvv`。可以多次指定此参数。


**环境**

可以指定以下环境变量。

- `ANSIBLE_INVENTORY` - 覆盖默认的 `ansible` 仓库文件；
- `ANSIBLE_LIBRARY` - 覆盖默认的 `ansible` 模组库路径；
- `ANSIBLE_CONFIG` - 覆盖默认的 `ansible` 配置文件。

`ansible.cfg` 中的大多数选项，都有更多可用选项。


**文件**

- `/etc/ansible/hosts` - 默认的仓库文件；
- `/etc/ansible/ansible.cfg` - 若存在，就会用到的配置文件；
- `~/.ansible.cfg` - 用户配置文件，会覆盖存在的默认配置。

### `ansible-config`

查看 `ansible` 的配置。

**简介**

```console
usage: ansible-config [-h] [--version] [-v] {list,dump,view,init} ...
```

**描述**

配置命令行类。


**命令选项**

- `--version`

显示程序的版本号、配置文件位置、已配置模块搜索路径、模块位置、可执行文件位置并退出。

- `-h, --help`

显示该帮助消息并退出。

- `-v, --verbose`

{{#include cli.md:423}}


### `ansible-console`
### `ansible-doc`
### `ansible-galaxy`
### `ansible-inventory`
### `ansible-playbook`
### `ansible-pull`
### `ansible-vault`
