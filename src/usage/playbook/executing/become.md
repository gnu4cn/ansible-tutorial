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



