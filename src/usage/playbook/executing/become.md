# 掌握权限提升：`become`

Ansible 使用了现有的权限提升系统，来以 root 权限或另一用户的权限执行任务。因为该特性允许咱们 “成为” 不同于登录到机器用户（远程用户）的另一用户，所以我们称之为 `become`。`become` 这个关键字，使用了现有的权限提升工具，如 `sudo`、`su`、`pfexec`、`doas`、`pbrun`、`dzdo`、`ksu`、`runas`、`machinectl` 等。


## 使用 `become`

咱们可通过 `play` 或 `task` 指令、连接变量或命令行等，控制 `become` 的使用。若咱们以多种方式，设置了权限提升属性，请查看 [一般优先规则](https://docs.ansible.com/ansible/latest/reference_appendices/general_precedence.html#general-precedence-rules)，以了解何种设置将被使用。

Ansible 中包含的所有插件完整列表，可在 [插件列表](https://docs.ansible.com/ansible/latest/plugins/become.html#become-plugin-list) 中找到。


### `become` 指令

咱们可以在 play 或任务级别，设置控制 `become` 的指令。可以通过设置连接变量，咱们可覆盖这些指令，不同主机的连接变量往往不同。这些变量和指令是独立的。例如，设置 `become_user` 并不会设置 `become`。


- `become`
设置为 `true` 以激活权限提升；

- `become_user`
设置为有着所需权限的用户 - 咱们要 *成为* 的用户，而 **不是** 咱们登录的用户。这 **不** 意味着在主机级别允许设置的 `become：true`，Does NOT imply `become: true`, to allow it to be set at the host level。默认值为 `root`；

- `become_method`
(于 play 或任务级别）覆盖 `ansible.cfg` 中设置的默认方式，设置为使用某种 [`become` 插件](https://docs.ansible.com/ansible/latest/plugins/become.html#become-plugins)；

- `become_flags`
(于 play 或任务级别）允许对任务或角色，使用特定开关。一种常见的用法是，当 shell 被设置为 `nologin` 时，将用户更改为 `nobody`。是在 Ansible 2.2 中添加的。


例如，以非 root 用户身份连接时，要管理某项系统服务（需要 `root` 权限），就可使用 `become_user` 的默认值（`root`）：


```yaml
    - name: Ensure the nginx service is running
      service:
        name: nginx
        state: started
      become: true
```

以 `apache` 用户身份运行一条命令：


```yaml
    - name: Run a command as the apache user
      command: somecommand
      become: true
      become_user: apache
```

当 shell 为 `nologin` 时，以 `nobody` 用户身份执行某些操作：

```yaml
    - name: Run a command as nobody
      command: somecommand
      become: true
      become_method: su
      become_user: nobody
      become_flags: '-s /bin/sh'
```

要为 `sudo` 指定密码，就要使用 `--ask-become-pass` （简写为 `-K`）运行 `ansible-playbook`。若咱们要运行某个使用了 `become` 的 playbook，而该 playbook 似乎挂起了，则很可能是卡在了权限提升提示符上。就要用 `CTRL-c` 停止他，然后用 `-K` 和适当密码执行该 playbook。


### `become` 的连接变量

咱们可为各个托管节点或组，定义不同的 `become` 选项。咱们可在仓库中定义这些变量，或者将他们作为普通变量使用。


- `ansible_become`
会覆盖 `become` 指令，并决定是否使用权限提升；

- `ansible_become_method`
应使用何种权限提升方法；

- `ansible_become_user`
设置咱们通过权限提升所成为的用户；并未暗示 `ansible_become: true`；

- `ansible_become_password`
设置权限提升的密码。有关如何避免使用明文秘密的详细信息，请参阅 [使用加密变量和文件](../../vault/enc_vars_and_files.md)；

- `ansible_common_remote_group`
决定出在 `setfacl` 和 `chown` 都失败时，Ansible 是否应尝试将临时文件 `chgrp` 到某个组。更多信息，请参阅 [成为非特权用户的风险](#成为非特权用户的风险)。这是在 2.10 版中添加的。


例如，如果咱们打算在名为 `webserver` 的服务器上，以 `root` 用户身份运行所有任务，但只能以 `manager` 用户身份连接，那么咱们可使用下面这样的一个仓库条目：


```ini
webserver ansible_user=manager ansible_become=true
```

> **注意**：上面定义的变量，对所有 `become` 插件都是通用的，但也可以设置一些特定于插件的变量。请参阅各个插件的文档，了解该插件具备的所有选项列表，以及如何定义这些选项。Ansible 中 `become` 插件的完整列表，请参见 [`become` 插件](https://docs.ansible.com/ansible/latest/plugins/become.html#become-plugins)。


### `become` 的命令行选项

- `--ask-become-pass`，`-K`
询问权限提升密码；这并不意味着将运用 `become`。请注意，该密码将用于所有主机；

- `--become`，`-b`
使用 `become` 运行操作（不带密码暗示）；

- `--become-method=BECOME_METHOD`
要使用的权限提升方法（`default=sudo`），有效选项： `[ sudo | su | pbrun | pfexec | doas | dzdo | ksu | runas | machinectl ]`；

- `--become-user=BECOME_USER`
以该用户身份运行操作（`default=root`），并未暗示 `--become`/`-b`。


## `become` 的风险与局限

尽管特权提升大多是直观的，但其工作原理有些限制。用户应意识到这些，以避免出现意外。


### 成为非特权用户的风险

Ansible 的模组在远端机器上被执行时，是首先将一些参数替换到模组文件中，然后将文件复制到远端机器上，最后在远端机器上执行的。

如果模组文件在不使用 `become` 下执行，或者 `become_user` 为 root 用户，或者以 root 用户身份连接的远端机器，则一切相安无事。在这些情况下，Ansible 会创建出权限为仅允许该用户与 root，或仅允许由所切换到的无特权用户读取权限的模组文件。


但是，当连接用户和 `become_user` 都是非特权用户时，模组文件会以 Ansible 连接用户身份（`remote_user`）写入，而文件却需要由 Ansible 设置为 `become` 的用户读取。Ansible 解决这个问题的细节因平台而异。不过，在 POSIX 系统上，Ansible 以如下方式解决这个问题：

首先，若安装了 `setfacl` 并在远端的 `PATH` 中可用，且远端主机上的临时目录挂载，且支持 POSIX.1e 的文件系统 ACL<sup>[1](#f-1)</sup>，那么 Ansible 将使用 POSIX ACL，与第二名非特权用户共享模组文件。

> **参考**：
>
> <a name="f-1">1</a>
>
> - [The Meaning of Posix.1e](http://wt.tuxomania.net/topics/1999_06_Posix_1e/)
> - [Why was POSIX.1e withdrawn?](https://unix.stackexchange.com/questions/489820/why-was-posix-1e-withdrawn)


接下来，若 POSIX ACL **不** 可用或 `setfacl` 无法运行，Ansible 将尝试使用 `chown` 更改模组文件的所有权（对那些支持以非特权用户身份这样做的系统）。

作为 Ansible 2.11 中的新特性，此刻 Ansible 将尝试使用 `chmod +a`，这种 MacOS 特有的文件 ACL 设置方式。

而作为 Ansible 2.10 的新特性，如果上述操作都失败了，Ansible 就将检查配置设置 `ansible_common_remote_group` 的值。许多系统都允许某名给定用户，将文件的组所有权更改为该用户所在的组。因此，若第二名非特权用户（即 `become_user`）与 Ansible 连接的用户（即 `remote_user`）有着共同的 UNIX 组，且 `ansible_common_remote_group` 被定义为了该组，那么 Ansible 就可以尝试使用 `chgrp`，将模组文件的组所有权更改为该组，从而使该模组文件成为 `become_user` 可以读取的文件。


到这里，如果定义了 `ansible_common_remote_group`，并且尝试了 `chgrp` 并返回成功，那么 Ansible 就会认为（但重要的是，并不检查）新的组所有权已经足够，而不会进一步回退了。也就是说，Ansible **不会检查** `become_user` 是否确实与 `remote_user` 共享了某个组；只要该命令（`chgrp`）成功退出，Ansible 就会认为结果是成功的，而不会继续检查下面的 `world_readable_temp`。


而如果 `ansible_common_remote_group` 未被设置，且上面的 `chown` 失败了，或者设置了 `ansible_common_remote_group`，但 `chgrp`（或下面的组权限 `chmod`）返回了某个非成功的退出代码，Ansible 将最后检查这个 [`world_readable_temp` 选项](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/sh_shell.html#parameter-world_readable_temp)。如果设置了该选项，Ansible 会将模组文件放到某个全局可读的临时目录中，in a world-readable temporary directory，并赋予其全局可读的权限，以允许 `become_user`（以及系统中的其他用户）读取文件内容。**如果传递给模组的任何参数带有敏感性质，而咱们又不信任远端机器，那么这就是个潜在的安全风险**。

一旦该模组执行完毕，Ansible 就会删除临时文件。

有几种可以完全避免上述逻辑流程的方法：

- 使用 *管道化，pipelining*。启用流水线后，Ansible 就不会将模组保存到客户端的临时文件中。相反，他会将模组管道传递给远端 Python 解释器的 `stdin`。管道化不适用于那些涉及文件传输的 Python 模组（例如：`copy`、`fetch`、`template` 等），也不适用于那些非 Python 的模组；
- 避免成为非特权用户。在咱们 `become` root，或不使用 `become` 时，临时文件会受 UNIX 的文件权限保护。在 Ansible 2.1 及以上版本中，如果咱们以 root 用户身份连接到托管机器，然后使用 `become` 访问某个非特权账户，UNIX 文件权限同样是安全的。


> **警告**：尽管 Solaris 的 ZFS 文件系统具备文件系统 ACL，但这些 ACL 并非 POSIX.1e 的文件系统 ACL（而是 NFSv4 的 ACL<sup>[2](#f-2)</sup>）。Ansible 无法使用这些 ACL，管理临时文件权限，因此如果远端机器使用了 ZFS，咱们就可能不得不使用 [`world_readable_temp` 选项](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/sh_shell.html#parameter-world_readable_temp)。

> **参考**：
>
> <a name="f-2">2</a>
>
> - [POSIX ACL和NFSv4 ACL的概念及其相关注意事项](https://help.aliyun.com/zh/nas/user-guide/overview)
>
> - [ACLs within the NFSv4 Protocols](https://www.ietf.org/archive/id/draft-dnoveck-nfsv4-acls-00.html)


*版本 2.1 中已变更*。

Ansible 令到难于在不知情的情况下，不安全地使用 `become`。从 Ansible 2.1 开始，如果无法安全地以 `become` 执行，Ansible 默认会发出一条错误消息。如果咱们不能使用管道化或 POSIX ACL，必须以非特权用户身份连接，必须使用 `become` 以另一非特权用户身份执行，并且明确了咱们的托管节点足够安全，以至咱们打算在那里运行的模组是全局可读的，那么咱们可以打开 [`world_readable_temp` 选项](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/sh_shell.html#parameter-world_readable_temp)，而这将会把错误变成一条警告，并允许任务像 2.1 版本之前那样运行。


*版本 2.1 中已变更*。

Ansible 2.10 引入了上述的 `ansible_common_remote_group` 回退。如上所述，其被启用后，当 `remote_user` 和 `become_user` 均为非特权用户时，就会用到他。有关该回退何时发生的详情，请参阅上文。


> **警告**：如上所述，若同时启用了 `ansible_common_remote_group` 和 `world_readable_temp`，那么全局可读回退就不大可能发生，但 Ansible 可能仍然无法访问模组文件。这是因为在组所有权变更成功后，Ansible 就不会进一步回退了，也不会做任何检查来确保 `become_user` 确实是那个 “公共组” 的成员。做出这个决定的原因是，进行这样的检查需要再次往返连接远端机器，耗费大量时间。不过，在这种情况下，Ansible 会发出一条警告。


### 并非受所有连接插件支持


这些特权提升方式，还必须受所使用的连接插件支持。若不支持 `become`，大多数连接插件都会发出警告。而有些则会忽略，因为他们总是以 root 身份运行（`jail`、`chroot` 等）。


### 一台主机上只会启用一种方法

`become` 方法不能串联。咱们不能使用 `sudo /bin/su -` 来成为某名用户，咱们需要具备在 `sudo` 中以该用户身份运行命令的权限，或能够直接 `su` 到该用户（`pbrun`、`pfexec` 或其他受支持的方法也是如此）。

### 权限提升必须具有普遍性

咱们不能将权限提升，限制到某些命令。Ansible 并不总是使用某条特定命令执行某些操作，而是会从某个临时文件名运行模组（代码），而临时文件名每次都会改变。若咱们将 `'/sbin/service'` 或 `'/bin/chmod'` 作为允许的命令，就将导致 Ansible 失败，因为这些路径与 Ansible 为运行模组而创建的临时文件不匹配。若咱们有着某些限制 `sudo`/`pbrun`/`doas` 环境，只能运行特定的命令路径的安全规则，就要以不受此限制的特殊账户，使用 Ansible，或使用 AWX 或 [Red Hat AAP](https://docs.ansible.com/ansible/latest/reference_appendices/tower.html#ansible-platform) 管理对 SSH 凭据的间接访问。


### 可能访问不到由 `pamd_systemd` 产生的环境变量

对于大多数将 `systemd` 用作启动程序的 Linux 发行版来说，`become` 所使用的默认方法，不会打开 `systemd` 意义上的新 “会话”。由于 `pam_systemd` 模组不会完整地初始化出一个新会话，因此与通过 ssh 打开的普通会话相比，咱们可能会遇到一些意外情况：由 `pam_systemd` 设置的一些环境变量，尤其是 `XDG_RUNTIME_DIR`，就不会为该新用户产生出来，而是会继承到或仅仅是空白的。

这可能会在尝试调用那些依赖 `XDG_RUNTIME_DIR` 访问总线的 `systemd` 命令时，造成麻烦：


```console
$ echo $XDG_RUNTIME_DIR

$ systemctl --user status
Failed to connect to bus: Permission denied
```

要强制 `become` 打开一个新的会历经 `pam_systemd` 的 `systemd` 会话，咱们可使用 `become_method：machinectl`。

更多信息，请参见 [这个 `systemd` 问题](https://github.com/systemd/systemd/issues/825#issuecomment-127917622)。


### 解决临时文件错误消息

- "Failed to set permissions on the temporary files Ansible needs to create when becoming an unprivileged user"
- 安装提供 `setfacl` 命令的软件包，可以解决这个错误。(这通常是 `acl` 软件包，但请查阅操作系统文档。）


## `become` 与网络自动化

从 2.6 版开始，Ansible 支持在所有受 Ansible 维护的平台上，使用 `become` 进行权限提升（进入 `enable` 模式或特权的 EXEC 模式）。使用 `become` 取代了 [`provider` 字典中的 `authorize` 和 `auth_pass` 选项](#authorize-与-auth_pass)。

在网络设备上，咱们必须将连接类型，设置为 `connection: ansible.netcommon.network_cli` 或 `connection: ansible.netcommon.httpapi`，才能使用 `become` 进行权限提升。详情请查看 [平台选项](https://docs.ansible.com/ansible/latest/network/user_guide/platform_index.html#platform-options) 文档。

咱们可以只在需要提升权限的特定任务、整个 play 或全部 play 中，使用提升的权限。添加 `become: true` 及 `become_method: enable`，就可以指示 Ansible 在执行设置了这些参数的任务、play 或 playbook 之前，进入 `enable` 模式。

若咱们看到下面这个错误信息，则表示产生出此错误信息的任务，需要 `enable` 模式才能成功：

```console
Invalid input (privileged mode required)
```

要为某个特定任务设置 `enable` 模式，请在任务级别添加 `become`：

```yaml
    - name: Gather facts (eos)
      arista.eos.eos_facts:
        gather_subset:
          - "!hardware"
      become: true
      become_method: enable
```

要为某单个 play 中的所有任务，设置 `enable` 模式，请在 play 级别添加 `become`：


```yaml
- hosts: eos-switches
  become: true
  become_method: enable

  tasks:
    - name: Gather facts (eos)
      arista.eos.eos_facts:
        gather_subset:
          - "!hardware"
```


### 为所有任务设置 `enable` 模式


通常，咱们会希望所有 play 中的所有任务，都使用特权模式运行，通过使用 `group_vars` 可最好实现这一点：


**`group_vars/eos.yml`**

```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: arista.eos.eos
ansible_user: myuser
ansible_become: true
ansible_become_method: enable
```

**`enable` 模式的密码**


若咱们需要密码进入 `enable` 模式，则可以以下两种方式之一指定出来：

- 提供 `--ask-become-pass` 命令行选项；
- 设置 `ansible_become_password` 连接变量。



> **警告**：需要提醒的是，密码绝不能以纯文本形式存储。有关使用 Ansible Vault 加密密码及其他机密的信息，请参阅 [Ansible Vault](../../vault.md)。


### `authorize` 与 `auth_pass`

对于旧有的网络 playbook，Ansible 仍然支持 `connection: local` 下的 `enable` 模式。要进入 `connection: local` 下的 `enable` 模式，请使用模组选项 `authorize` 和 `auth_pass`：


```yaml
- hosts: eos-switches
  ansible_connection: local
  tasks:
    - name: Gather facts (eos)
      eos_facts:
        gather_subset:
          - "!hardware"
      provider:
        authorize: true
        auth_pass: " {{ secret_auth_pass }}"
```

我们（作者）建议将咱们的 playbook，更新为始终使用 `become` 获取网络设备的 `enable` 模式。`authorize` 与 `auth_pass` 字典这种用法将在今后弃用。有关详细信息，请查阅 [平台选项](https://docs.ansible.com/ansible/latest/network/user_guide/platform_index.html#platform-options) 文档。


## `become` 与 Windows 系统

自 Ansible 2.3 起，便可通过 `runas` 方式，在 Windows 主机上使用 `become` 了。Windows 上的 `become` 与非 Windows 主机上的 `become`，使用相同的仓库设置和调用参数，因此除 `become_user` 外，其他设置和变量名，都与本文档中定义的相同。这是因为在 Windows 上，使用 `become` 时无需有意义的 `become_user` 默认值。详情请参阅 [`ansible.builtin.runas` `become` 插件](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/runas_become.html#ansible-collections-ansible-builtin-runas-become)。

虽然 `become` 可以用来假定另一用户的身份，在 Windows 主机上他还有别的用途。其中一个重要用途，是绕过在 WinRM 上运行时的一些限制，如受限的网络授权，或访问某些如 WUA API 这样的受禁系统调用。咱们可将 `become` 与 `ansible_user` 相同的用户一起使用，来绕过这些限制，而运行一些通常在 WinRM 会话中无法访问的命令。

> **注意**：在 Windows 系统中，咱们无法使用低权限账户连接并使用 `become` 来提升权限。只有当连接账户已经是目标主机的管理员时，才能使用 `become`。


### 管理员权限

**Administrative rights**


Windows 中的许多任务，都需要管理员权限才能完成。使用 `runas` 这个 `become` 方法时，Ansible 会尝试使用 `become` 用户的全部权限运行模组。若 Anisble 提升用户令牌失败，他将在执行过程中继续使用有限令牌。

用户必须具有 `SeDebugPrivilege`（调试权限），才能以提升权限运行某个 `become` 进程。该权限默认是分配给管理员的。若没有调试权限，则 `become` 进程将以一组有限权限和组运行。

要确定出 Ansible 所能够获取到的令牌类型，请运行以下任务：

```yaml
    - name: Check my username
      ansible.windows.win_whoami:
      become: true
```

> **译注**：因为任务是针对 Windows 主机，因此需要在仓库中将该 Windows 设置为如下这样。

```yaml
win_servers:
  hosts:
    win10-133:
      ansible_host: 192.168.122.133
      ansible_connection: ssh
      ansible_shell_type: powershell
      ansible_user: 'Hector PENG'
      ansible_ssh_pass: 'mypass'
```

> 并在 play 中作如下设置。

```yaml
- name: Ansible on Windows demo
  hosts: win10-133
  become_method: runas
  become_user: 'Hector PENG'
  gather_facts: no

  tasks:
    - name: Check my username
      ansible.windows.win_whoami:
      become: true
```

> 否则会报出下面这些错误：
>
> - `The powershell shell family is incompatible with the sudo become plugin`
>
> - `No setting was provided for required configuration plugin_type: become plugin: runas setting: become_user `


输出将看起来类似于下面这样：

```json
{{#include whoami.json}}
```

在 `label` 键下，`account_name` 条目决定了用户是否具有管理员权限。以下是可能返回的标签及其代表的内容：

- `Medium`：Ansible 未能获得提升令牌，只能在有限令牌下运行。在模组执行期间，只有分配给用户的权限子集可用，且该用户没有管理权限；
- `High`：在模组执行过程中，使用了提升的令牌，且分配给该用户的全部权限都可用；
- `System`：使用了 `NT AUTHORITY\System` 账户，且有着最高级别的权限。

输出还将显示出已授予给该用户的权限列表。当某项权限的值为 `disabled` 时，表示该项权限已分配给登录令牌，但尚未启用。在大多数情况下，这些权限在需要时都会自动启用。


若咱们是在早于 2.5 版本的 Ansible 上运行，或正常的 `runas` 升级过程失败，则可通过以下方式，获取提升的令牌：

- 将 `become_user` 设置为对操作系统有着完全控制的 `System`；
- 在 WinRM 上授予 Ansible 连接用户 `SeTcbPrivilege` 权限。`SeTcbPrivilege` 是种可授予对操作系统的完全控制的高级别权限。默认情况下，没有用户会被赋予此项权限，因此在咱们授予用户或用户组此权限时，应小心谨慎。有关此权限的更多信息，请参阅 [Act as part of the operating system](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/dn221957(v=ws.11))。咱们可使用以下任务，在 Windows 主机上设置此权限：

```yaml
    - name: grant the ansible user the SeTcbPrivilege right
      ansible.windows.win_user_right:
        name: SeTcbPrivilege
        users: '{{ansible_user}}'
        action: add
```

- 再次尝试成为该用户前，关闭主机上的 UAC 并重启。UAC 是种设计用于以 `least privilege` （最小权限）原则，运行账户的安全协议。运行以下任务即可关闭 UAC：

```yaml
    - name: turn UAC off
      win_regedit:
        path: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system
        name: EnableLUA
        data: 0
        type: dword
        state: present
      register: uac_result

    - name: reboot after disabling UAC
      win_reboot:
      when: uac_result is changed
```

> **注意**：授予 `SeTcbPrivilege` 权限或关闭 UAC，可能会导致 Windows 安全漏洞，因此在采取这些步骤时应小心谨慎。


### 本地服务账户

**Local service accounts**

在 Ansible 2.5 版之前，`become` 只能在 Windows 系统以本地或域用户账户运作。在那些旧版本中，如 `System` 或 `NetworkService`这样的本地服务账户，不能用作 `become_user`。自 Ansible 2.5 版本后，这一限制已被取消。可以在 `become_user` 下设置的三个服务账户是:

- `System`
- `NetworkService`
- `LocalService`


由于本地服务账户没有密码，因此就不需要 `ansible_become_password` 参数，若指定了该参数，也会被忽略。


### 无需设置密码的 `become`

自 Ansible 2.8 起，无需某个 Windows 本地或域帐户，即可使用 `become` 成为该账户。要使用此方法，必须满足以下要求：

- 连接用户已分配了 `SeDebugPrivilege` 权限；
- 连接用户属于 `BUILTIN\Administrators` 组；
- `become_user` 有着 `SeBatchLogonRight` 或 `SeNetworkLogonRight` 用户权限。


使用无需密码的 `become`，是通过以下两种不同方法之一实现的：

- 若该账户已登录，则复制现有的登录会话令牌；
- 使用 S4U<sup>[3](#f-3)</sup> 生成一个仅在远端主机上有效的登录令牌。

> **参考**：
>
> <a name="f-3">3</a>
>
> - [[MS-SFU]: Kerberos Protocol Extensions: Service for User and Constrained Delegation Protocol](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-sfu/3bff5864-8135-400e-bdd9-33b552051d94)

在第一种情况下，`become` 进程是从该用户账户的另一登录中产生的。这可能是现有的 RDP 登录或控制台登录，但不能保证每次都这样。这与某个计划任务的 `Run only when user is logged on` 选项类似。

在 `become` 账户的另一登录不存在时，则会使用 S4U 创建一个新的账户登录，并通过该次登陆运行模组。这与某个计划任务 `Do not store password` 选项下的 `Run whether user is logged on or not` 类似。在这种情况下，`become` 进程将无法像某个普通 WinRM 进程那样，访问任何网络资源。

为区分出使用无需密码的 `become`，与成为没有密码的账户，就要确保将 `ansible_become_password` 设为 `undefined`，或设置` ansible_become_password: `。

> **注意**：由于无法保证 Ansible 运行时，用户的现有令牌存在，所以 `become` 进程很可能只能访问本地资源。如果任务需要访问网络资源，请使用带密码的 `become`。


### 不带密码的账户

> **警告**：作为一般的安全最佳实践，咱们应避免放行没有密码的账户。



