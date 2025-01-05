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

**常用选项**

- `--become-method <BECOME_METHOD>`，权限提升方式（`default=sudo`），使用 `ansible-doc -t become -l` 列出有效选项；
- `--become-password-file <BECOME_PASSWORD_FILE>, --become-pass-file <BECOME_PASSWORD_FILE>`，`become` 的口令文件；
- `--become-user <BECOME_USER>`，以该用户身份运行操作（`default=root`）；
- `--connection-password-file <CONNECTION_PASSWORD_FILE>, --conn-pass-file <CONNECTION_PASSWORD_FILE>`，连接的口令文件；
- `--list-hosts`，输出匹配主机的列表；不执行任何其他操作；
- `--playbook-dir <BASEDIR>`，由于该工具不使用 playbook，因此可将其用作替代的 playbook 目录。这将为许多功能设置相对路径，包括 `roles/`、`group_vars/` 等；
- `--private-key <PRIVATE_KEY_FILE>, --key-file <PRIVATE_KEY_FILE>`，使用此文件来认证连接；
- `--scp-extra-args <SCP_EXTRA_ARGS>`，指定仅传递给 `scp` 的额外参数（如 `-l`）；
- `--sftp-extra-args <SFTP_EXTRA_ARGS>`，指定仅传递给 `sftp` 的额外参数（如 `-f`、`-l`）；
- `--ssh-common-args <SSH_COMMON_ARGS>`，指定传递给 `sftp`/`scp`/`ssh` 的公共参数（如 `ProxyCommand`）；
- `--ssh-extra-args <SSH_EXTRA_ARGS>`，指定仅传递给 `ssh` 的额外参数（如 `-R`）；
- `--task-timeout <TASK_TIMEOUT>`，设置任务超时限制（秒），必须为正整数；
- `--vault-id`，要使用的保险库标识。该参数可指定多次；
- `--vault-password-file, --vault-pass-file`，保险库口令文件；
- `--version`，显示程序的版本号、配置文件位置、所配置的模组搜索路径、模组位置、可执行文件位置并退出；
- `-B <SECONDS>`，异步运行，`X` 秒后失败（`default=N/A`）；
- `-C, --check`，不做任何改变，而是尝试预测可能发生的一些变化；
- `-D, --diff`，更改（小）文件和模板时，显示这些文件的差异；与 `--check` 一起使用效果极佳；
- `-J, --ask-vault-password, --ask-vault-pass`，询问保险库口令；
- `-K, --ask-become-pass`，询问权限提升口令；
- `-M, --module-path`，添加以冒号分隔的路径，作为模组库（`default={{ ANSIBLE_HOME ~ "/plugins/modules:/usr/share/ansible/plugins/modules" }}`）。此参数可指定多次；
- `-P <POLL_INTERVAL>, --poll <POLL_INTERVAL>`，如果使用 `-B` 选项，则设置轮询间隔（`default=15`）；
- `-T <TIMEOUT>, --timeout <TIMEOUT>`，覆盖连接超时，以秒为单位（默认值取决于连接方式）；
- `-a <MODULE_ARGS>, --args <MODULE_ARGS>`，以空格分隔的 `k=v` 格式： `-a 'opt1=val1 opt2=val2'`，或 JSON 字符串： `-a '{"opt1"： "val1", "opt2"： "val2"}'` 形式的该操作的选项；
- `-b, --become`，以 `become` 运行操作（并不意味着密码提示符）；
- `-c <CONNECTION>, --connection <CONNECTION>`，要使用的连接类型（`default=ssh`）；
- `-e, --extra-vars`，以 `key=value` 方式， 或文件名前添加了 `@` 的 YAML/JSON 方式，设置一些额外变量。此参数可指定多次；
- `-f <FORKS>, --forks <FORKS>`，指定要使用的并行进程数（`default=5`）；
- `-h, --help`，打印此帮助消息并退出；
- `-i, --inventory`，指定仓库主机路径，或逗号分隔的主机列表。`-inventory-file` 选项已被弃用。该参数可指定多次；
- `-k, --ask-pass`，询问连接口令；
- `-l <SUBSET>, --limit <SUBSET>`，将选定主机进一步限制为额外模式；
- `-m <MODULE_NAME>, --module-name <MODULE_NAME>`，要执行的操作名称（`default=command`）；
- `-o, --one-line`，压缩输出；
- `-t <TREE>, --tree <TREE>`，记录日志输出到此目录；
- `-u <REMOTE_USER>, --user <REMOTE_USER>`，以该用户身份连接（`default=None`）；
- `-v, --verbose`，会导致 Ansible 打印更多调试信息。添加多个 `-v` 会增加调试信息的冗余度，内置插件目前最多会评估到 `-vvvvv`。 开始时的合理级别是 `-vvv`，连接的调试则可能需要 `-vvvv`。可以多次指定此参数；

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


**常用选项**

{{#include cli.md:291}}
{{#include cli.md:305}}
{{#include cli.md:313}}


**操作**

+ `list`，列出并输出可用的配置；
    - `--format <FORMAT>, -f <FORMAT>`，列表的输出格式；
    - `-c <CONFIG_FILE>, --config <CONFIG_FILE>`，配置文件的路径，默认依优先顺序找到的首个文件；
    - `-t <TYPE>, --type <TYPE>`，筛选到某个指定的插件类型。
+ `dump`，显示当前设置，若有指定则合并 `ansible.cfg`；
    - `--format <FORMAT>, -f <FORMAT>`，转储的输出格式；
    - `--only-changed, --changed-only`，只显示与默认配置不同的配置；
    - `-c <CONFIG_FILE>, --config <CONFIG_FILE>`，配置文件的路径，默认依优先顺序找到的首个文件；
    - `-t <TYPE>, --type <TYPE>`，筛选到某个指定的插件类型。

+ `view`，显示当前配置文件；
    - `-c <CONFIG_FILE>, --config <CONFIG_FILE>`，配置文件的路径，默认依优先顺序找到的首个文件；
    - `-t <TYPE>, --type <TYPE>`，筛选到某个指定的插件类型。

+ `init`，创建初始配置。
    - `--disabled`，在所有条目前添加注释字符，以禁用他们；
    - `--format <FORMAT>, -f <FORMAT>`，转储的输出格式；
    - `-c <CONFIG_FILE>, --config <CONFIG_FILE>`，配置文件的路径，默认依优先顺序找到的首个文件；
    - `-t <TYPE>, --type <TYPE>`，筛选到某个指定的插件类型。

**环境**

以下环境变量可能会被指定出来。

{{#include cli.md:321:323}}


### `ansible-console`

REPL 控制台，用于执行 Ansible 任务。

> **译注**：REPL console，其中 REPL 指 read, evaluate, print, loop，读取-求值-打印-循环，故 REPL console 指的是交互式控制台。


**简介**

```console
usage: ansible-console [-h] [--version] [-v] [-b]
                    [--become-method BECOME_METHOD]
                    [--become-user BECOME_USER]
                    [-K | --become-password-file BECOME_PASSWORD_FILE]
                    [-i INVENTORY] [--list-hosts] [-l SUBSET]
                    [--private-key PRIVATE_KEY_FILE] [-u REMOTE_USER]
                    [-c CONNECTION] [-T TIMEOUT]
                    [--ssh-common-args SSH_COMMON_ARGS]
                    [--sftp-extra-args SFTP_EXTRA_ARGS]
                    [--scp-extra-args SCP_EXTRA_ARGS]
                    [--ssh-extra-args SSH_EXTRA_ARGS]
                    [-k | --connection-password-file CONNECTION_PASSWORD_FILE]
                    [-C] [-D] [--vault-id VAULT_IDS]
                    [-J | --vault-password-file VAULT_PASSWORD_FILES]
                    [-f FORKS] [-M MODULE_PATH] [--playbook-dir BASEDIR]
                    [-e EXTRA_VARS] [--task-timeout TASK_TIMEOUT] [--step]
                    [pattern]
```

**描述**

这是个 REPL，可通过一个漂亮的 shell（基于 dominis 的 `ansible-shell`），运行针对所选仓库的临时任务，该 shell 具有内置的制表符补全功能。

他支持多种命令，并可在运行时修改配置：


- `cd [pattern]`：改变主机/组别（咱们可以运用主机模式，比如 `app*.dc*:!app01*`）；
- `list`：列出当前路径下的可用主机；
- `list groups`：列出当前路径下所包含的组别；
- `become`：打开 `become` 命令行开关；
- `!`：强制从 `ansible` 模组进入 `shell` 模组（`!yum update -y`）；
- `verbosity [num]`：设置详细级别；
- `forks [num]`：设置进程分叉数目；
- `become_user [user]`：设置 `become_user`；
- `remote_user [user]`：设置 `remote_user`；
- `become_method [method]`：设置权限升级方式；
- `check [bool]`：打开检查模式；
- `diff [bool]`：打开 `diff` 模式；
- `timeout [integer]`：设置任务超时（秒，`0` 关闭超时）；
- `help [command/module]`：显示命令或模组的帮助信息；
- `exit`：退出 `ansible-console`。


**常用选项**

{{#include cli.md:277:287}}
- `--step`，一次运行一步：每项运行前要进行确认；
{{#include cli.md:288:291}}
{{#include cli.md:293:297}}
{{#include cli.md:299}}
{{#include cli.md:301:308}}
{{#include cli.md:312:313}}


**命令行参数**


- `host-pattern`，仓库中某组别的名字、一种类 shell 的在仓库中的全局主机选取，或以逗号分隔的二者任意组合。


{{#include cli.md:315:323}}


### `ansible-doc`

插件文档工具，plugin documentation tool。

**简介**

```console
usage: ansible-doc [-h] [--version] [-v] [-M MODULE_PATH]
                [--playbook-dir BASEDIR]
                [-t {become,cache,callback,cliconf,connection,httpapi,inventory,lookup,netconf,shell,vars,module,strategy,test,filter,role,keyword}]
                [-j] [-r ROLES_PATH]
                [-e ENTRY_POINT | -s | -F | -l | --metadata-dump]
                [--no-fail-on-errors]
                [plugin ...]
```


**描述**

显示安装在 Ansible 库中的模组信息。他会显示一个插件的简短列表，及这些插件的简短描述，提供这些插件 `DOCUMENTATION` 字符串的打印输出，还能创建可被粘贴到某个 playbook 的一个简短 “片段”。


**常用选项**


- `--metadata-dump`，**仅供内部使用** 转储所有条目的 JSON 元数据，而忽略其他选项；
- `no-fail-on-errors`，**仅供内部使用** 仅用于 `-metadata-dump`. 不因出错而运行失败。而是在 JSON 中报告错误信息；
{{#include cli.md:282}}
{{#include cli.md:291}}
- `-F, --list_files`，显示插件名称及各自的源文件，不带摘要（表示 `-list`）。提供的参数将用于筛选，可以是命名空间，或完整的集合名称；
{{#include cli.md:297}}
- `-e <ENTRY_POINT>, --entry-point <ENTRY_POINT>`，选取角色，`roles`，的入口点。
{{#include cli.md:305}}
- `-j, --json`，修改输出为 JSON 格式；
- `-l, --list`，列出可用的插件。提供的参数将用于筛选，可以是命名空间，或完整集合名称；
- `-r, --roles-path`，包含角色的目录路径。此参数可指定多次；
- `-s, --snippet`，显示这些插件类型：`inventory`、`lookup`、`module`，的 playbook 代码片段；
- `-t <TYPE>, --type <TYPE>`，选择插件类型（默认为 `module`）。可用的插件类型有：`('become', 'cache', 'callback', 'cliconf', 'connection', 'httpapi', 'inventory', 'lookup', 'netconf', 'shell', 'vars', 'module'、'strategy'、'test'、'filter'、'role'、'keyword')`；
{{#include cli.md:313}}


{{#include cli.md:315:317}}
{{#include cli.md:320:323}}


### `ansible-galaxy`

执行各种与角色和专辑相关的操作。


**简介**

```console
usage: ansible-galaxy [-h] [--version] [-v] TYPE ...
```

**描述**

用于管理 Ansible 角色和专辑的命令。

该 CLI 的工具全都被设计为不能同时运行。请使用外部调度器，并/或加锁，以确保不会出现操作冲突。


**常用选项**

{{#include cli.md:291}}
{{#include cli.md:305}}
{{#include cli.md:313}}


**操作**

+ `collection`，对 Ansible Galaxy 专辑执行操作。必须与下文列出的 `init`/`install` 等下一步操作结合使用。
    + `collection download`，以 tar 包形式下载专辑及其依赖项，以便离线安装；
        - `--clear-response-cache`，清除现有的服务器响应缓存；
        - `--no-cache`，不使用服务器响应缓存；
        - `--pre`，包括预发布版本。默认会忽略语义版本控制的预发布版本；
        - `--timeout <TIMEOUT>`，对 Galaxy 服务器进行操作的等待时间，默认为 60 秒；
        - `--token <API_KEY>, --api-key <API_KEY>`，Ansible Galaxy 的 API 密钥，可在 [https://galaxy.ansible.com/me/preferences](https://galaxy.ansible.com/me/preferences) 处找到；
        - `-c, --ignore-certs`，忽略 SSL 证书验证错误；
        - `-n, --no-deps`，不要下载列为依赖项的那些专辑；
        - `-p <DOWNLOAD_PATH>, --download-path <DOWNLOAD_PATH>`，要下载专辑的目录；
        - `-r, <REQUIREMENTS>, --requirements-file <REQUIREMENTS>`，包含要下载专辑列表的文件；
        - `-s <API_SERVER>, --server <API_SERVER>`，Galaxy API 服务器的 URL。
    + `collection init`
        - `--collection-skeleton, <COLLECTION_SKELETON>`，新专辑应基于的专辑骨架路径；
        - `--init-path <INIT_PATH>`，创建骨架专辑的路径。默认为当前工作目录；
{{#include cli.md:533:535}}
        {{#include cli.md:303}}
        - `-f, --force`，强制覆盖现有角色或专辑;
{{#include cli.md:539}}

    + `collection build`，构建某个 Ansible Galaxy 专辑制品，a Ansible Galaxy collection artifact，该制品可存储在类似 Ansible Galaxy 的某个中心资源库中。默认情况下，该命令从当前工作目录构建。咱们可以选择传入该专辑的输入路径（`galaxy.yml` 文件的所在位置）。
        - `--output-path <OUTPUT_PATH>`，该专辑要构建到的路径。默认为当前工作目录；
{{#include cli.md:533:535}}
{{#include cli.md:545}}
{{#include cli.md:539}}
    + `collection publish`，将某个专辑发布到 Ansible Galaxy。需要提供所发布专辑 tar 压缩包的路径；
        - `--imoprt-timeout <IMPORT_TIMEOUT>`，等待专辑导入过程完成的时间；
        - `--no-wait`，无需等待导入验证的结果；
{{#include cli.md:533:535}}
{{#include cli.md:539}}
    + `collection install`，安装一或多个角色（`ansible-galaxy role install`），或一或多个专辑（`ansible-galaxy collection install`）。咱们可以传入一个列表（角色或专辑的），也可以使用下面列出的文件选项（二者是互斥的）。如果咱们传入了个列表，则他可以是个名称（将通过 galaxy API 和 github 下载），也可以是个本地的 tar 归档文件。
{{#include cli.md:530}}
        - `--disable-gpg-verify`，从某个 Galaxy 服务器安装专辑时，禁用 GPG 签名验证；
        - `--force-with-deps`，强制覆盖现有专辑及其依赖关系；
        - `--ignore-signature-status-code`，--消息抑制--。该参数可以指定多次；
        - `--ignore-signature-status-codes`，以空格分隔的状态代码列表，用于在签名验证过程中忽略这些代码（例如，`NO_PUBKEY FAILURE` 等）。有关这些选项的说明，请参见 [General status codes](https://github.com/gpg/gnupg/blob/master/doc/DETAILS#general-status-codes)。注意：请在位置参数后指定这些参数，或使用 `-` 分隔他们。该参数可指定多次。
        - `keyring`，签名验证时使用的密钥环；
{{#include cli.md:531}}
        - `--offline`，在不联系任何分发服务器下，安装专辑制品（tar 包）。此选项不适用于远程 Git 仓库中的专辑，或指向远端压缩包的 URL；
{{#include cli.md:532}}
        - `--required-valid-signature-count <REQUIRED_VALID_SIGNATURE_COUNT>`，必须成功验证该专辑的签名数。该值应为正整数，或表示必须使用所有签名来验证该专辑的 `-1`。如果未找到该专辑的有效签名，则以前导的 `+` 表示验证失败（例如 `+all`）；
        - `--signature`，额外签名源，用于在从 Galaxy 服务器上安装专辑前，验证 `MANIFEST.json` 的真实性。与随后的专辑名称一起使用（与 `-requirements-file` 相互排斥）。该参数可指定多次；
{{#include cli.md:533:534}}
        - `-U, --upgrade`，升级已安装的专辑制品。除非提供 `-no-deps`，否则也会更新依赖项；
{{#include cli.md:535}}
{{#include cli.md:545}}
        - `-i, --ignore-errors`，忽略安装过程中的错误，并继续下一指定专辑。这不会忽略依赖冲突错误；
{{#include cli.md:545}}
        - `-p <COLLECTION_PATH>, --collection-path <COLLECTION_PATH>`，包含咱们专辑目录的路径；
{{#include cli.md:538:539}}
    + `collection list`，列出已安装的专辑或角色；
        - `--format <OUTPUT_FORMAT>`，显示专辑列表的格式；
{{#include cli.md:533:535}}
        - `-p, --collections_path`，除默认的 `COLLECTIONS_PATHS` 目录外，还要搜索的一或多个目录。多个路径之间用 `:` 分隔。此参数可指定多次；
{{#include cli.md:539}}
    + `collection verify`，比较服务器上发现的专辑，与所安装副本的校验和。这不会验证依赖关系；
{{#include cli.md:562:564}}
        - `--offline`，在不联系服务器获取规范清单哈希值下，在本地验证专辑的完整性；
{{#include cli.md:568:569}}
{{#include cli.md:533:535}}
{{#include cli.md:574}}
{{#include cli.md:581}}
{{#include cli.md:538:539}}

+ `role`，对某个 Ansible Galaxy 角色执行操作。必须与下文列出的 `delete`/`install`/`init` 等进一步操作相结合。
    + `role init`，创建符合 Galaxy 元数据格式的角色或专辑的骨架框架。需要一个角色或专辑名称。专辑名称的格式必须是 `<namespace>.<collection>`；
        - `--init-path <INIT_PATH>`，将在其中创建骨架角色的路径。默认为当前工作目录;
        - `--offline`，在创建角色时不查询 Galaxy API；
        - `--role-skeleton <ROLE_SKELETON>`，新角色所基于角色骨架的路径；
{{#include cli.md:533:534}}
        - `--type <ROLE_TYPE>`，使用某种替代角色类型初始化。有效类型包括 `container`、`apb` 及 `network`；
{{#include cli.md:535}}
        {{#include cli.md:303}}
{{#include cli.md:545}}
{{#include cli.md:539}}

    + `role remove`，移除作为参数传递的本地系统上的角色列表；
{{#include.md cli.md:533:535}}
        - `-p, --roles-path`，包含角色的目录路径。默认路径是通过 `DEFAULT_ROLES_PATH` 配置的第一个可写路径： `{{ ANSIBLE_HOME ~ "/roles:/usr/share/ansible/roles:/etc/ansible/roles" }}` 。该参数可指定多次；
{{#include cli.md:539}}
    + `role delete`，删除来自 Ansible Galaxy 的某个角色；
{{#include.md cli.md:533:535}}
{{#include cli.md:539}}
    + `role list`，列出已安装的专辑或角色；
{{#include.md cli.md:533:535}}
{{#include.md cli.md:606}}
{{#include cli.md:539}}
    + `role search`，检索 Ansible Galaxy 服务器上的角色；
        - `--author <AUTHOR>`，GitHub 用户名；
        - `--galaxy-tags <GALAXY_TAGS>`，要过滤的 galaxy 标签列表；
        - `--platform <PLATFORM>`，要过滤的 OS 平台列表；
{{#include.md cli.md:533:535}}
{{#include cli.md:539}}
    + `role import`，用于将某个角色，导入 Ansible Galaxy；
        - `--branch <REFERENCE>`，要导入的分支名称。默认为版本库的默认分支（通常是 `master`/`main`）；
        - `--no-wait`，无需等待导入结果；
        - `--role-name <ROLE_NAME>`，在不同于源码库名字时，该角色应有的名字；
        - `--status`，检查给定 `github_user/github_repo` 的最新导入请求状态；
{{#include.md cli.md:533:535}}
{{#include cli.md:539}}
    + `role setup`，为 Ansible Galaxy 角色设置自 GitHub 或 Travis 的集成；
        - `--list`，列出咱们的所有集成；
        - `--remove <REMOVE_ID>`，删除与所提供 ID 值相匹配的集成。请使用 `--list` 查看 ID 值；
{{#include.md cli.md:533:535}}
{{#include.md cli.md:606}}
{{#include cli.md:539}}
    + `role info`，打印出某个已安装角色的详细信息，以及 galaxy API 提供的信息；
{{#include.md cli.md:595}}
{{#include.md cli.md:533:535}}
{{#include.md cli.md:606}}
{{#include cli.md:539}}
    + `role install`，安装一或多个角色（`ansible-galaxy role install`），或一或多个专辑（`ansible-galaxy collection install`）。咱们可传入一个列表（角色或专辑的），也可以使用下面所列出的文件选项（二者互斥）。如果咱们传入了个列表，则其可以是一个名称（将通过 galaxy API 和 github 下载），也可以是一个本地 tar 压缩文件。
        - `--force-with-deps`，强制覆盖现有角色及其依赖关系；
{{#include.md cli.md:533:535}}
{{#include.md cli.md:545}}
        - `-g, --keep-scm-meta`，打包角色时，使用 tar 而不是 SCM 的归档选项；
        - `-i, --ignore-errors`，忽略安装过程中的错误，并继续下一指定角色；
        - `-n, --no-deps`，不要下载列为依赖项的那些角色；
{{#include.md cli.md:606}}
        - `-r <REQUIREMENTS>, --role-file <REQUIREMENTS>`，包含待安装角色列表的文件；
{{#include cli.md:539}}


**环境**

{{#include cli.md:317}}
{{#include cli.md:321:323}}

**文件**


{{#include cli.md:329:330}}



### `ansible-inventory`

显示 Ansible 清单信息，默认使用清单脚本的 JSON 格式。

**简介**

```console
usage: ansible-inventory [-h] [--version] [-v] [-i INVENTORY] [-l SUBSET]
                      [--vault-id VAULT_IDS]
                      [-J | --vault-password-file VAULT_PASSWORD_FILES]
                      [--playbook-dir BASEDIR] [-e EXTRA_VARS] [--list]
                      [--host HOST] [--graph] [-y] [--toml] [--vars]
                      [--export] [--output OUTPUT_FILE]
                      [group]
```

**描述**

用于以 Ansible 视角，显示或转储所配置的仓库。

**常用选项**

- `--export`，执行 `--list` 时，以专为导出而优化，而不是 Ansible 如何处理的精确表示方式呈现；
- `--graph`，创建仓库的图表，如果提供了模式，则必须是有效的组名。他将忽略 `--limit`；
- `--host <HOST>`，输出指定主机的信息，以仓库脚本形式工作。他将忽略 `--limit`；
- `--list`，输出全部主机信息，以仓库脚本形式工作；
- `--output <OUTPUT_FILE>`，执行 `--list` 时，会将仓库发送到某个文件而非屏幕；
{{#include cli.md:282}}
- `--toml`，使用 TOML 格式而非默认的 JSON 格式，在使用 `--graph` 时会被忽略；
- `--vars`，在图表显示中添加 `vars`，除非与 `--graph` 一起使用，否则会被忽略；
{{#include cli.md:289:291}}
{{#include cli.md:295}}
{{#include cli.md:303}}
{{#include cli.md:305:306}}
{{#include cli.md:308}}
{{#include cli.md:313}}
- `-y, --yaml`，使用 YAML 格式而非默认的 JSON 格式，在使用 `--graph` 时会被忽略；


**命令行参数**

- `group`，仓库中组别的名字，与使用 `--graph` 时相关。


**环境**


{{#include cli.md:317:319}}
{{#include cli.md:321:323}}



**文件**


{{#include cli.md:328:330}}



### `ansible-playbook`


**简介**

**描述**

**常用选项**

**环境**

**文件**



### `ansible-pull`


**简介**

**描述**

**常用选项**

**环境**

**文件**



### `ansible-vault`


**简介**

**描述**

**常用选项**

**环境**

**文件**



