# 网络调试与故障排除指南

本小节讨论了在 Ansible 中调试网络模组并排除故障。


## 怎样故障排除


Ansible 网络自动化报错，通常分为以下类别之一：


+ **认证问题**
    - 未正确指定凭据；
    - 远端设备（网络交换机/路由器）未回退到其他其他身份验证方法；
    - SSH 密钥问题。
+ **超时问题**
    - 尝试拉取大量数据时，可能会出现；
    - 可能实际上掩盖了身份验证问题。
+ **Playbook 问题**
    - 使用 `delegate_to` 代替 `ProxyCommand`。更多信息，请参阅 [网络代理指南](#delegate_to-与-ProxyCommand)。


> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> `unable to open shell`
>
> `unable to open shell` 消息意味着 `ansible-connection` 守护进程无法成功与远端网络设备通信。这通常意味着存在身份验证问题。更多信息，请参阅本文档的 [“身份验证和连接问题”](#认证与连接问题) 小节。


### 启用网络日志及如何读取日志文件


**平台**：全部


Ansible 包含了帮助诊断及排除有关 Ansible 网络模组问题的日志功能。

由于日志记录非常冗长，因此默认情况下该功能被禁用了。咱们可在运行 `ansible-playbook` 的 Ansible 控制节点上，使用 `ANSIBLE_LOG_PATH` 和 `ANSIBLE_DEBUG` 选项，启用日志记录功能。


运行 `ansible-playbook` 前，运行以下命令启用日志记录：


```console
# Specify the location for the log file
export ANSIBLE_LOG_PATH=~/ansible.log
# Enable Debug
export ANSIBLE_DEBUG=True

# Run with 4*v for connection level verbosity
ansible-playbook -vvvv ...
```


Ansible 运行结束后，咱们可以检查 Ansible 控制节点上已创建出的日志文件：


```log
less $ANSIBLE_LOG_PATH

...
2025-03-18 16:38:10,581 p=102143 u=hector n=ansible INFO| <nxos-sw> attempting to start connection
2025-03-18 16:38:10,581 p=102143 u=hector n=ansible INFO| <nxos-sw> using connection plugin ansible.netcommon.network_cli

...
2025-03-18 16:38:10,985 p=102143 u=hector n=ansible INFO| <nxos-sw> local domain socket does not exist, starting it
2025-03-18 16:38:10,985 p=102143 u=hector n=ansible INFO| <nxos-sw> control socket path is /home/hector/.ansible/pc/f3231d6f43
2025-03-18 16:38:10,985 p=102143 u=hector n=ansible INFO| <nxos-sw> Loading collection ansible.builtin from
...

2025-03-18 16:38:10,987 p=102143 u=hector n=ansible INFO| network_os is set to cisco.nxos.nxos
2025-03-18 16:38:10,987 p=102143 u=hector n=ansible INFO| <nxos-sw> ssh type is set to auto
2025-03-18 16:38:10,987 p=102143 u=hector n=ansible INFO| <nxos-sw> autodetecting ssh_type
2025-03-18 16:38:10,987 p=102143 u=hector n=ansible INFO| <nxos-sw> ssh type is now set to libssh
...

2025-03-18 16:38:10,988 p=102143 u=hector n=ansible INFO| <nxos-sw> local domain socket path is /home/hector/.ansible/pc/f3231d6f43
2025-03-18 16:38:10,988 p=102203 u=hector n=ansible INFO| <nxos-sw> USING PYLIBSSH VERSION 1.2.2
2025-03-18 16:38:10,988 p=102203 u=hector n=ansible INFO| <nxos-sw> ESTABLISH LIBSSH CONNECTION FOR USER: admin on PORT 22 TO nxos-sw
...

2025-03-18 16:38:11,220 p=102203 u=hector n=ansible INFO| ssh connection is OK: <pylibsshext.session.Session object at 0x782d717944f0>
2025-03-18 16:38:14,929 p=102143 u=hector n=ansible INFO| <nxos-sw> [cli_parse] OS set to 'nxos' using 'ansible_network_os'.
```

在这个日志中我们注意到：


- `p=102143` 是 `ansible-connection` 进程的 PID（进程 ID）；
- `u=hector` 是 *运行* ansible 的用户，而不是咱们试图连接的远端用户；
- `ESTABLISH LIBSSH CONNECTION FOR USER: admin on PORT 22 TO nxos-sw` 用户与主机及端口；
- `control socket path is /home/hector/.ansible/pc/f3231d6f43` 创建出的持久连接套接字的在磁盘上的位置；
- `using connection plugin ansible.netcommon.network_cli` 告诉咱们正使用的持久连接；
- `ssh connection is OK: <pylibsshext.session.Session object at 0x782d717944f0>` 建立 SSH 连接成功。


> **注意**：
>
> 端口 `None` `creating new control socket for host veos01:None`
>
> 如果日志报告端口为 `None`，这意味着所使用的是默认端口。今后的 Ansible 版本将改进此信息，以便该端口始终被记录。


由于日志文件冗长，因此咱们可使用 `grep` 查找特定信息。例如，在咱们从行 `creating new control socket for host` 找到 `pid` 后，就可以检索其他连接日志条目了：


```console
grep "p=102203 $ANSIBLE_LOG_PATH"
```


### 启用网络设备交互日志记录


**平台**：全部

Ansible 会在日志文件中包含帮助诊断和排除有关 Ansible 网络模组问题的设备交互日志。这些消息会记录在由 Ansible 配置文件中 `log_path` 配置选项所指向的文件，或 `ANSIBLE_LOG_PATH` 所设置的文件中。


> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> 这些设备交互信息，由目标设备上执行的命令以及返回的响应所组成。由于这些日志数据可能包含包括纯文本的密码等敏感信息，因此默认情况下是禁用的。此外，为了防止数据意外泄漏，启用此设置的每个任务都将显示一条指出哪个主机启用了此设置，以及数据在哪里记录的告警信息。

```console
[WARNING]: Persistent connection logging is enabled for iosxe-sw. This will log ALL interactions to /home/hector/.log/ansible.log and WILL NOT redact sensitive configuration like passwords. USE WITH CAUTION!
```


请务必充分了解启用此选项的安全影响。设备交互日志记录既可通过配置文件中的设置，也可通过设置环境全局启用，或者可通过向任务传递一个特殊变量，而按任务启用。



运行 `ansible-playbook` 前，运行以下命令启用日志记录：

```console
# Specify the location for the log file
export ANSIBLE_LOG_PATH=~/ansible.log
```

启用特定任务的设备交互记录：

```yaml
{{#include ../../network_run/demo_interaction_logging.yml}}
```

要将此作为全局设置，就要在 `ansible.cfg` 文件中，添加以下内容：


```ini
[persistent_connection]
log_messages = True
```


或者启用环境变量 `ANSIBLE_PERSISTENT_LOG_MESSAGES`：


```console
# Enable device interaction logging
export ANSIBLE_PERSISTENT_LOG_MESSAGES=True
```

如果任务本身在连接初始化时失败，咱们就应全局启用这个选项。而若个别任务出现间歇性失败，则可针对该任务本身启用该选项，以找出根本原因。


Ansible 运行结束后，咱们就可以检查在 Ansible 控制节点上创建出的日志文件了。


> **注意**：请务必充分了解启用该选项的安全影响，因为他会在日志文件中记录敏感信息，从而造成安全漏洞。


### 隔离某个报错


**平台**：全部


与任何故障排除的努力一样，尽可能简化测试用例非常重要。


对于 Ansible 来说，这可以通过确保咱们只针对一个远端设备运行来实现：

- 使用 `ansible-playbook --limit iosxe-sw ...`；
- 使用临时的 `ansible` 命令。

所谓 *临时，ad hoc*，指的是使用 `/usr/bin/ansible`，而非使用编排语言，即 `/usr/bin/ansible-playbook`，运行 Ansible 执行一些快速命令。在这种情况下，我们可以通过尝试在远端设备上执行单个命令，确保连通性：


```console
ansible -i network_run/inventory.yml arista-sw -m arista.eos.eos_command -a 'commands=?'
```

在上面的示例中，我们：

- 连接到在仓库文件 `network_run/inventory.yml` 中指定出的 `arista-sw`；
- 使用了模组 `arista.eos.eos_command`；
- 运行了命令 `?`；


若咱们正确配置了 SSH 密钥，则就无需指定 `-k` 参数。


如果连接仍然失败，则咱们可将其与 `enable_network_logging` 参数结合。例如：

```console
# Specify the location for the log file
export ANSIBLE_LOG_PATH=~/ansible.log
# Enable Debug
export ANSIBLE_DEBUG=True
# Run with ``-vvvv`` for connection level verbosity
ansible -i network_run/inventory.yml arista-sw -m arista.eos.eos_command -a 'commands=?'
```

然后查看日志文件，并在本文档其余部分找到相关的错误消息。


## 套接字路径问题排除

**平台**：全部


`Socket path does not exist or cannot be found` 及 `Unable to connect to socket` 两种消息表明，用于与远端网络设备通信的套接字不可用或不存在。


比如：


```yaml
fatal: [spine02]: FAILED! => {
    "changed": false,
    "failed": true,
    "module_stderr": "Traceback (most recent call last):\n  File \"/tmp/ansible_TSqk5J/ansible_modlib.zip/ansible/module_utils/connection.py\", line 115, in _exec_jsonrpc\nansible.module_utils.connection.ConnectionError: Socket path XX does not exist or cannot be found. See Troubleshooting socket path issues in the Network Debug and Troubleshooting Guide\n",
    "module_stdout": "",
    "msg": "MODULE FAILURE",
    "rc": 1
}
```


或者：


```yaml
fatal: [spine02]: FAILED! => {
    "changed": false,
    "failed": true,
    "module_stderr": "Traceback (most recent call last):\n  File \"/tmp/ansible_TSqk5J/ansible_modlib.zip/ansible/module_utils/connection.py\", line 123, in _exec_jsonrpc\nansible.module_utils.connection.ConnectionError: Unable to connect to socket XX. See Troubleshooting socket path issues in Network Debug and Troubleshooting Guide\n",
    "module_stdout": "",
    "msg": "MODULE FAILURE",
    "rc": 1
}
```

解决建议：

1. 确认咱们对错误信息中描述的套接字路径，是否有写入权限；
2. 按照 [启用网络日志](#启用网络设备交互日志记录) 中详细描述的步骤操作。


如果日志文件中识别出的错误信息为：


```log
2017-04-04 12:19:05,670 p=18591 u=fred |  command timeout triggered, timeout value is 30 secs
```


或者：

```log
2017-04-04 12:19:05,670 p=18591 u=fred |  persistent connection idle timeout triggered, timeout value is 30 secs
```


请按照 [超时问题](#超时问题) 中详细描述的步骤操作。


## 类别 `"Unable to open shell"`


**平台**：全部


`unable to open shell` 消息意味着 `ansible-connection` 守护进程，无法成功与远端网络设备对话。这通常意味着存在身份验证问题。这是一条 “笼统，catch all” 消息，意味着咱们需要启用日志记录，才能找到根本问题。


比如：

```console
TASK [prepare_eos_tests : enable cli on remote device] **************************************************
fatal: [veos01]: FAILED! => {"changed": false, "failed": true, "msg": "unable to open shell"}
```

或者：

```console
TASK [ios_system : configure name_servers] *************************************************************
task path:
fatal: [ios-csr1000v]: FAILED! => {
    "changed": false,
    "failed": true,
    "msg": "unable to open shell",
}
```


解决建议：


按照 [启用网络日志](#启用网络设备交互日志记录) 中详细描述的步骤操作。


一旦咱们识别出日志文件中的错误消息，就可以在本文档其余部分，找到具体的解决办法。


### 报错: `"[Errno -2] Name or service not known"`


**平台**：全部


表示咱们正尝试连接的远端主机不可达。

比如：


```log
2017-04-04 11:39:48,147 p=15299 u=fred |  control socket path is /home/fred/.ansible/pc/ca5960d27a
2017-04-04 11:39:48,147 p=15299 u=fred |  current working directory is /home/fred/git/ansible-inc/stable-2.3/test/integration
2017-04-04 11:39:48,147 p=15299 u=fred |  using connection plugin network_cli
2017-04-04 11:39:48,340 p=15299 u=fred |  connecting to host veos01 returned an error
2017-04-04 11:39:48,340 p=15299 u=fred |  [Errno -2] Name or service not known
```


解决建议：

- 若咱们使用的是 `provider:` 选项，请确保正确设置了其子选项 `host:`；
- 若咱们没有使用 `provider:`，也没有使用一些顶级参数，那么就要确保仓库文件正确无误。


### 报错：`"Authentication failed"`


**平台**：全部

在传递给 `ansible-connection`（经由 `ansible` 或 `ansible-playbook`）的凭据（用户名、密码或 ssh 密钥），无法用于连接到远端设备时，就会出现此报错。


比如：


```log
<ios01> ESTABLISH CONNECTION FOR USER: cisco on PORT 22 TO ios01
<ios01> Authentication failed.
```

解决建议：

如果咱们是通过 `password:`（或直接通过 `provider:`），或环境变量 `ANSIBLE_NET_PASSWORD` 指定出的凭据，则可能是 `paramiko`（Ansible 使用的 Python SSH 库）正在使用 ssh 密钥，因此咱们指定出的凭证被忽略了。要确定情况是否这种，就要禁用 “查找密钥”。方法如下：

```console
export ANSIBLE_PARAMIKO_LOOK_FOR_KEYS=False
```

要使这一设置成为永久修改，就要在 `ansible.cfg` 文件中添加以下内容：


```ini
[paramiko_connection]
look_for_keys = False
```

### 报错：`"connecting to host <hostname> returned an error"` 或 `"Bad address"`


在远端主机的 SSH 指纹尚未添加到 Paramiko（Python 的 SSH 库）的 `known_hosts` 文件中时，就可能出现这种情况。

在使用 Paramiko 下的持久连接时，连接会在某个后台进程中运行。若主机尚无有效的 SSH 密钥，默认 Ansible 会提示添加主机密钥。这会导致在后台进程中运行的连接失败。


比如：


```log
2017-04-04 12:06:03,486 p=17981 u=fred |  using connection plugin network_cli
2017-04-04 12:06:04,680 p=17981 u=fred |  connecting to host veos01 returned an error
2017-04-04 12:06:04,682 p=17981 u=fred |  (14, 'Bad address')
2017-04-04 12:06:33,519 p=17981 u=fred |  number of connection attempts exceeded, unable to connect to control socket
2017-04-04 12:06:33,520 p=17981 u=fred |  persistent_connect_interval=1, persistent_connect_retries=30
```

解决建议：

使用 `ssh-keyscan` 命令预先产生出 `known_hosts`。咱们需要确保密钥正确无误。


```console
ssh-keyscan arista-sw
```

或者

咱们可以告诉 Ansible 自动接受密钥。

使用环境变量方式：


```console
export ANSIBLE_PARAMIKO_HOST_KEY_AUTO_ADD=True
ansible-playbook ...
```

`ansible.cfg` 方式：


```ini
[paramiko_connection]
host_key_auto_add = True
```

### 报错：`"No authentication methods available"`

比如:

```log
2017-04-04 12:19:05,670 p=18591 u=fred |  creating new control socket for host veos01:None as user admin
2017-04-04 12:19:05,670 p=18591 u=fred |  control socket path is /home/fred/.ansible/pc/ca5960d27a
2017-04-04 12:19:05,670 p=18591 u=fred |  current working directory is /home/fred/git/ansible-inc/ansible-workspace-2/test/integration
2017-04-04 12:19:05,670 p=18591 u=fred |  using connection plugin network_cli
2017-04-04 12:19:06,606 p=18591 u=fred |  connecting to host veos01 returned an error
2017-04-04 12:19:06,606 p=18591 u=fred |  No authentication methods available
2017-04-04 12:19:35,708 p=18591 u=fred |  connect retry timeout expired, unable to connect to control socket
2017-04-04 12:19:35,709 p=18591 u=fred |  persistent_connect_retry_timeout is 15 secs
```

解决建议：

未提供密码或 SSH 密钥。


### 清除持久连接


**平台**：全部

在 Ansible 2.3 中，所有网络设备的持久连接套接字，都存储在 `~/.ansible/pc` 中。运行某个 Ansible playbook 时，如果指定了详细输出，就会显示出这个持久连接套接字。

```log
<nxos-sw> local domain socket path is /home/hector/.ansible/pc/f3231d6f43
```

要在超时（默认超时时间为 30 秒的不活动时间）前清除某个持久连接，只需删除该套接字文件即可。


## 超时问题

### 持久连接空闲超时

默认情况下，`ANSIBLE_PERSISTENT_CONNECT_TIMEOUT` 被设置为 30（秒）。如果该值过低，咱们就可能会看到下面的报错：


```log
2025-03-18 16:38:44,243 p=102203 u=hector n=ansible INFO| persistent connection idle timeout triggered, timeout value is 30 secs.
```

解决建议：

增加持久连接空闲超时值：

```console
export ANSIBLE_PERSISTENT_CONNECT_TIMEOUT=60
```

要使这一设置成为永久修改，就要在 `ansible.cfg` 文件中添加以下内容：


```ini
[persistent_connection]
connect_timeout = 60
```


### 命令超时

默认情况下，`ANSIBLE_PERSISTENT_COMMAND_TIMEOUT` 被设置为 30（秒）。先前版本的 Ansible 默认将该值设置为 10 秒。如果该值过低，咱们可能会看到以下报错：

```log
2025-03-19 16:38:44,243 p=102203 u=hector n=ansible INFO| command timeout triggered, timeout value is 30 secs.
```

解决建议：


- 选项 1 （全局的命令超时设置）：在配置文件中，或通过设置环境变量增加命令超时值；

```console
export ANSIBLE_PERSISTENT_COMMAND_TIMEOUT=60
```

要使这一设置成为永久修改，就要在 `ansible.cfg` 文件中添加以下内容：

```ini
[persistent_connection]
command_timeout = 60
```

- 选项 2 （按任务设置命令超时）：按任务增加命令超时。所有网络模组都支持可按任务设置的超时值。超时值控制着在该命令未返回值时，任务失败所需的秒数。


对于本地连接类型，解决建议：

某些模组支持 `timeout` 选项，该选项不同于任务的 `timeout` 关键字。


```yaml
- name: save running-config
  cisco.ios.ios_command:
    commands: copy running-config startup-config
    provider: "{{ cli }}"
    timeout: 30
```

解决建议：


如果模组不直接支持 `timeout` 选项，那么大多数网络连接插件都可通过 `ansible_command_timeout` 这个任务级别变量，启用类似功能。


```yaml
- name: save running-config
  cisco.ios.ios_command:
    commands: copy running-config startup-config
  vars:
    ansible_command_timeout: 60
```

有些操作会耗时超过默认的 30 秒才能完成。将 IOS 设备上的当前运行配置，保存为启动配置就是个很好的例子。在这种情况下，将超时值从默认的 30 秒改为 60 秒，将防止任务在命令成功完成前失败。



### 持久连接重试超时


默认情况下，`ANSIBLE_PERSISTENT_CONNECT_RETRY_TIMEOUT` 被设置为 15（秒）。如果该值过低，咱们可能会看到以下报错：


```log
2017-04-04 12:19:35,708 p=18591 u=fred |  connect retry timeout expired, unable to connect to control socket
2017-04-04 12:19:35,709 p=18591 u=fred |  persistent_connect_retry_timeout is 15 secs
```

解决建议：


增加持久连接重试超时值。注意：该值应大于 SSH 的超时值（配置文件中 `defaults` 小节下的超时值），并应小于持久连接连接空闲超时值（`connect_timeout`）。


```console
export ANSIBLE_PERSISTENT_CONNECT_RETRY_TIMEOUT=30
```

要使这一设置成为永久修改，就要在 `ansible.cfg` 文件中添加以下内容：

```ini
[persistent_connection]
connect_retry_timeout = 30
```


### 由于 `network_cli` 连接类型下特定平台登录菜单而导致的超时问题


在 Ansible 2.9 及以后的版本中，增加了一些处理平台特定的登录菜单的 `network_cli` 连接插件配置选项。这些选项可设置为组别/主机，或任务变量。


示例：使用主机变量处理单个登录菜单提示。


```console
$ cat host_vars/<hostname>.yaml
---
ansible_terminal_initial_prompt:
  - "Connect to a host"
ansible_terminal_initial_answer:
  - "3"
```

示例：使用主机变量处理远程主机多重登录菜单提示。


```console
$ cat host_vars/<inventory-hostname>.yaml
---
ansible_terminal_initial_prompt:
  - "Press any key to enter main menu"
  - "Connect to a host"
ansible_terminal_initial_answer:
  - "\\r"
  - "3"
ansible_terminal_initial_prompt_checkall: True
```

要处理多重登录菜单提示：


- `ansible_terminal_initial_prompt` 和 `ansible_terminal_initial_answer` 两个变量的值，都应是个列表；
- 提示顺序应与答复顺序一致；
- `ansible_terminal_initial_prompt_checkall` 变量的值应置为 `True`。


> **注意**：如果在连接初始化时刻，未收到远端主机按顺序发出的所有提示，这将导致超时。


## Playbook 问题

这一小节详细介绍了 Playbook 本身引起的问题。

### 报错：`"Unable to enter configuration mode"`

**平台**：Arista EOS 与思科 IOS

当咱们尝试在用户模式 shell 中，运行需要特权模式的某个任务时，就会出现这个问题。


比如：

```console
TASK [ios_system : configure name_servers] *****************************************************************************
task path:
fatal: [ios-csr1000v]: FAILED! => {
    "changed": false,
    "failed": true,
   "msg": "unable to enter configuration mode",
}
```

解决建议：

使用 `connection: ansible.netcommon.network_cli` 以及 `become: true`。

## 代理问题

### `delegate_to` 与 `ProxyCommand`

为了使用堡垒机或中间跳转主机，a bastion or intermediate jump，经由 `cli` 的传输连接到网络设备，Ansible 的网络模组支持使用 `ProxyCommand`。


要使用 `ProxyCommand`，就要在 Ansible 仓库文件中，配置代理设置，以指定出代理主机。


```ini
[nxos]
nxos01
nxos02

[nxos:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

在上面的配置下，只需按正常方式构建并运行 playbook，而无需进行其他更改。现在，网络模组将首先连接到 `ansible_ssh_common_args` 中指定的主机，即上例中的 `bastion01`，从而连接到网络设备。


咱们还可以使用环境变量，为所有主机设置代理目标。


```console
export ANSIBLE_SSH_ARGS='-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```


### 在 `netconf` 连接下使用堡垒/跳转主机


**启用跳转主机设置**

在 `netconf` 连接下，可通过以下方式启用堡垒/跳转主机：

- 将 Ansible 变量 `ansible_netconf_ssh_config` 设置为 `True` 或自定义 ssh 配置文件路径；
- 将环境变量 `ANSIBLE_NETCONF_SSH_CONFIG` 设置为 `True` 或自定义 ssh 配置文件路径；
- 在 `netconf_connection` 小节下（`ansible.cfg` 文件中），设置 `ssh_config = 1` 或 `ssh_config = <ssh-file-path>`。


如果该配置变量被设置为 `1`，则 `proxycommand` 与其他 ssh 变量将从默认的 ssh 配置文件（`~/.ssh/config`）中读取。

如果该配置变量被设置为某个文件路径，则会从给定的自定义 ssh 文件路径，读取 `proxycommand` 和其他 ssh 变量。


**示例 ssh 配置文件（`~/.ssh/config`）**


```config
Host jumphost
  HostName jumphost.domain.name.com
  User jumphost-user
  IdentityFile "/path/to/ssh-key.pem"
  Port 22

# Note: Due to the way that Paramiko reads the SSH Config file,
# you need to specify the NETCONF port that the host uses.
# In other words, it does not automatically use ansible_port
# As a result you need either:

Host junos01
  HostName junos01
  ProxyCommand ssh -W %h:22 jumphost

# OR

Host junos01
  HostName junos01
  ProxyCommand ssh -W %h:830 jumphost

# Depending on the netconf port used.
```

示例 Ansible 仓库文件：

```ini
[junos]
junos01

[junos:vars]
ansible_connection=ansible.netcommon.netconf
ansible_network_os=junipernetworks.junos.junos
ansible_user=myuser
ansible_password=!vault...
```


> **注意**：
>
> 通过变量将 `ProxyCommand` 和密码一起
>
> 根据设计，SSH 不支持通过环境变量提供密码。这样做是为了防止秘密泄漏，例如在 `ps` 的输出中。
>
> 我们建议尽可能使用 SSH 密钥，且在需要时使用 `ssh-agent`，而不是密码。


## 杂项问题


### 使用 `ansible.netcommon.network_cli` 连接类型时的间歇性失败


如果在响应中接收到的命令提示符，与 `ansible.netcommon.network_cli` 连接插件中命令提示符不匹配，则任务就可能会以截断的响应，或 `operation requires privilege escalation` 错误信息而间歇性失败。从 `2.7.1` 版开始，新增了缓冲区读取计时器，以确保提示符正确匹配，以及在输出中发送完整的响应。计时器默认值为 0.2 秒，可根据每个任务进行调整，也可以秒为单位全局设置。


每个任务的计时器设置示例：


```yaml
- name: gather ios facts
  cisco.ios.ios_facts:
    gather_subset: all
  register: result
  vars:
    ansible_buffer_read_timeout: 2
```


要使这一设置称为全局设置，就要将以下内容添加到咱们的 `ansible.cfg` 文件：


```ini
[persistent_connection]
buffer_read_timeout = 2
```


可通过将该值设为零，来禁用在远端主机上执行的每条命令的这一定时器延迟。


### 使用 `ansible.netcommon.network_cli` 连接类型时由于命令响应中不匹配的错误正则表达时导致的任务失败


在 Ansible 2.9 及更高版本中，添加了处理 `stdout` 和 `stderr` 正则表达式，以识别出命令执行响应是正常还是错误响应的一些 `ansible.netcommon.network_cli` 连接插件配置选项。这些选项可设置为分组/主机变量，或任务变量。


示例： 对于不匹配的错误响应。


```yaml
- name: fetch logs from remote host
  cisco.ios.ios_command:
    commands:
      - show logging
```


Playbook 运行的输出：


```console
TASK [first fetch logs] ********************************************************
fatal: [ios01]: FAILED! => {
    "changed": false,
    "msg": "RF Name:\r\n\r\n <--nsip-->
           \"IPSEC-3-REPLAY_ERROR: Test log\"\r\n*Aug  1 08:36:18.483: %SYS-7-USERLOG_DEBUG:
            Message from tty578(user id: ansible): test\r\nan-ios-02#"}
```


解决建议：

修改个别任务的错误表达式。


```yaml
- name: fetch logs from remote host
  cisco.ios.ios_command:
    commands:
      - show logging
  vars:
    ansible_terminal_stderr_re:
      - pattern: 'connection timed out'
        flags: 're.I'
```


终端插件的正则表达式选项 `ansible_terminal_stderr_re` 和 `ansible_terminal_stdout_re` 均有 `pattern` 和 `flags` 两个关键字。`flags` 关键字的值，应是个 `re.compile` 这个 python 方法接受的值。


### 使用 `ansible.netcommon.network_cli` 连接类型时因网络或远端目标主机速度较慢而造成的间歇性失败


在 Ansible 2.9 及以后的版本中，增加了控制连接远端主机尝试次数的一些 `ansible.netcommon.network_cli` 连接插件配置选项。默认尝试次数为三次。每次连接重试后，重试之间的延迟会以秒为单位以 2 的幂次递增，直到最大尝试次数耗尽，或 `persistent_command_timeout` 或 `persistent_connect_timeout` 定时器触发。


要使这一设置称为全局设置，就要将以下内容添加到咱们的 `ansible.cfg` 文件：


```ini
[persistent_connection]
network_cli_retries = 5
```


（End）


