# Windows SSH


在较新的 Windows 版本中，咱们可使用 SSH 连接到 Windows 主机。这是 [WinRM](winrm.md) 的替代连接选项。


> **注意**：虽然从版本 2.8 开始，Ansible 就可以对 Windows 节点使用 SSH 连接插件，但直到 2.18 版本才加入正式支持。


## SSH 建立


自 Windows Server 2019 以来，微软在 Windows 中提供了 Windows 的 OpenSSH 实现，作为 Windows 的一项功能。也可以通过 [`Win32-OpenSSH`](https://github.com/PowerShell/Win32-OpenSSH) 下的上游软件包安装。Ansible 官方只支持随 Windows 发布的 OpenSSH 实现，而非上游软件包。OpenSSH 版本必须至少为 `7.9.0.0`。这实际上意味着官方支持自 Windows Server 2022 开始，因为 Server 2019 随附的版本是 `7.7.2.1`。使用较旧的 Windows 版本或上游软件包可能可行，但不受支持。


要在 Windows Server 2022 及更高版本上安装 OpenSSH 特性，请使用以下 PowerShell 命令：


```powershell
{{#include ./openssh_installation_srv_2022.ps1}}
```


### 默认 shell 配置

默认情况下，Windows 上的 OpenSSH 使用 `cmd.exe` 作为默认 shell。尽管 Ansible 可以使用该默认 shell，但建议将其更改为 `powershell.exe`，因为他经过了更好的测试，而且速度应该比使用 `cmd.exe` 作为默认 shell 更快。要更改默认 shell，可使用以下 PowerShell 脚本：


```powershell
{{#include ./change_openssh_shell.ps1}}
```


新的默认 shell 设置，将应用到下一次 SSH 连接，无需重启 `sshd` 服务。咱们也可使用 Ansible 来配置这个默认 shell：


```yaml
    - name: set the default shell to PowerShell
      ansible.windows.win_regedit:
        path: HKLM:\SOFTWARE\OpenSSH
        name: DefaultShell
        data: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
        type: string
        state: present

    - name: reset SSH connection after shell change
      ansible.builtin.meta: reset_connection

    # - name: set the default shell to cmd
    #   ansible.windows.win_regedit:
    #     path: HKLM:\SOFTWARE\OpenSSH
    #     name: DefaultShell
    #     state: absent
    #
    # - name: reset SSH connection after shell change
    #   ansible.builtin.meta: reset_connection

```

> **译注**：登陆 Windows 主机后，执行命令 `(dir 2>&1 *`|echo CMD);&<# rem #>echo PowerShell` 查看当前是何种 shell。
>
> 参考：[How do I determine if I'm in powershell or cmd?](https://stackoverflow.com/a/34480405/12288760)

其中的 `meta：reset_connection` 任务，对于确保后续任务将使用新默认 shell 非常重要。


## Ansible 的配置


要配置 Ansible 对 Windows 主机使用 SSH，咱们必须设置以下两个连接变量：


- 将 `ansible_connection` 设置为 `ssh`；
- 将 `ansible_shell_type` 设置为 `powershell` 或 `cmd`。


`ansible_shell_type` 这个变量应反映 Windows 主机上所配置的 `DefaultShell`。也可为 Windows 主机设置 [`ssh`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html#ssh-connection) 小节下记录的其他 SSH 选项。



## SSH 认证

Windows 下 `Win32-OpenSSH` 的身份验证，类似于 Unix/Linux 主机上的 SSH 身份验证。虽然可以有多种身份验证方法，但在 Windows 上通常使用以下三种：


| 选项 | 本地账户 | AD 账户 | 凭据 |
| :-- | :-- | :-- | :-- |
| 密钥认证 | 是 | 是 | 否 |
| GSSAPI 认证 | 否 | 是 | 是 |
| 密码认证 | 是 | 是 | 是 |

在大多数情况下，都建议使用密钥或 GSSAPI 身份验证，而不是密码的身份验证。

> **译注**，GSSAPI, Generic Security Services Application Programming Interface，通用安全服务应用编程接口。
>
> 参考：
>
> - [Kerberos (GSSAPI) Authentication](https://www.microfocus.com/documentation/rsit-server-client-unix/8-4-0/unix-guide/gssapi_auth_ov.html)
>
> - [Difference between Kerberos and RADIUS](https://www.geeksforgeeks.org/difference-between-kerberos-and-radius/)


### 密钥认证

Windows 上的 SSH 密钥验证，以与 POSIX 节点上的 SSH 密钥验证相同方式运作。咱们可使用 `ssh-keygen` 命令生成一个密钥对，并将公钥添加到用户配置文件目录下的 `authorized_keys` 文件中。私钥应妥善保管，不得共享。

一个差别在于，管理员用户的 `authorized_keys` 文件，并不位于用户配置文件目录下的 `.ssh` 文件夹中，而是位于 `C:\ProgramData\ssh\administrators_authorized_keys` 文件中。可以通过删除这个 `authorized_keys` 文件，或注释掉 `C:\ProgramData\ssh\sshd_config` 中的一些行，并重启 `sshd` 服务，将管理员用户的 `authorized_keys` 文件位置，改回用户配置文件目录。


```config
Match Group administrators
    AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

对本地账户与域账户，SSH 密钥认证均可工作，但会遭受双跳问题的困扰，suffer from double-hop issue。这意味着在 Ansible 中使用 SSH 密钥身份验证时，远端会话将没有访问用户凭据的权限，而在尝试访问某项网络资源时失败。要解决这个问题，咱们可在任务中，以需要访问该远端资源的用户凭据使用 [`become`](../../playbook/executing/become.md)。


### GSSAPI 认证

GSSAPI 的身份验证将使用 Kerberos，对用户与 Windows 主机进行身份验证。要在 Ansible 中使用 GSSAPI 身份验证，必须通过编辑 `C:\ProgramData\ssh\sshd_config` 这个文件，将 Windows 服务器配置为允许 GSSAPI 身份验证。添加以下行或编辑现有行：


```config
GSSAPIAuthentication yes
```

编辑完后，使用 `Restart-Service -Name sshd` 重启 `sshd` 服务。


在 Ansible 控制节点上，咱们需要安装上 Kerberos，并配置一个 Windows 主机为其成员的域。怎样建立和配置此设置，不在此文档讨论范围之内。配置好 Kerberos 的 `realm` 后，咱们就可以使用 `kinit` 命令，为正在连接的用户取得票据，并使用 `klist` 命令验证有哪些票据可用：

> **译注**：
>
> 任何咱们看到听到的 Windows 主机 “加入域”，都指的是加入 AD 域。参考：[How to ensure machine is "Kerberos Domain" joined?](https://serverfault.com/a/384722/994825)。


```console
> kinit username@REALM.COM
Password for username@REALM.COM

> klist
Ticket cache: KCM:1000
Default principal: username@REALM.COM

Valid starting     Expires            Service principal
29/08/24 13:54:51  29/08/24 23:54:51  krbtgt/REALM.COM@REALM.COM
        renew until 05/09/24 13:54:48
```

> **译注**：
>
> 1. 在启动 `krb5-kadmind` 服务时，会因为 `/var/lib/krb5kdc/kadm5.acl` 找不到而启动失败。解决方法是建立个空的该文件;
>
> 2. 往 Kerberos 服务器添加账户称为 "添加 principals"，要以管理员启动 Kerberos 管理工具：`sudo kadmin.local`，使用本地认证。
>
> 参考：
>
> - [[blfs-dev] Missing kadm5.acl file for MIT-Kerberos?](https://www.mail-archive.com/blfs-dev@lists.linuxfromscratch.org/msg09900.html)
>
> - [Add principals](https://wiki.archlinux.org/title/Kerberos#Add_principals)
>
> - [Installing Kerberos on Almalinux 8](https://setupexample.com/kerberos-setup-on-almalinux-8)

有了有效的票据后，咱们就可以使用 `ansible_user` 主机变量，指定出 UPN 用户名<sup>1</sup>，这样 Ansible 在使用 SSH 时，将自动使用该用户的 Kerberos 票据。


> **译注**：
>
> 1. UPN, user principal name，用户账户名（有时称为用户登录名）和域名，用于标识用户账户所在的域。这是登录 Windows 域的标准用法。格式为： `someone@example.com`（与电子邮件地址相同）。
>
> 参考：
>
> - [Kerberos: difference between UPN and SPN](https://stackoverflow.com/a/18243107/12288760)

通过 GSSAPI 身份验证启用无约束委派，enable unconstrained delegation through GSSAPI authentication，让 Windows 节点访问网络资源，也是可行的。要使 GSSAPI 委托工作，由 `kinit` 获取的票据必须是可转发的，同时必须以 `-o GSSAPIDelegateCredentials=yes` 选项调用 `ssh`。要获取可转发票据，要么在 `kinit` 中使用 `-f` 标志，要么在 `/etc/krb5.conf` 文件的 `[libdefaults]` 小节下添加 `forwardable = true`。


```console
> kinit -f username@REALM.COM
Password for username@REALM.COM

# -f will show the ticket flags, we want to see F
> klist -f
Ticket cache: KCM:1000
Default principal: username@REALM.COM

Valid starting     Expires            Service principal
29/08/24 13:54:51  29/08/24 23:54:51  krbtgt/REALM.COM@REALM.COM
        renew until 05/09/24 13:54:48, Flags: FRIA
```

`GSSAPIDelegateCredentials=yes` 这个选项，既可在 `~/.ssh/config` 文件中设置，也可作为主机变量在仓库中设置：


```ini
ansible_ssh_common_args: -o GSSAPIDelegateCredentials=yes
```


与 `psrp` 或 `winrm` 连接插件不同，SSH 连接插件在提供了显式用户名和密码时，无法获取 Kerberos TGT 票据<sup>2</sup>。这意味着用户必须在运行 playbook 前，获得有效的 Kerberos 票据。

> **译注**：
>
> 2. TGT, Ticket Granting Tickets，票据授权票据
>
> 参考:
>
> - [Wikipedia: Kerberos](https://zh.wikipedia.org/wiki/Kerberos#%E5%8D%8F%E8%AE%AE%E5%86%85%E5%AE%B9)

有关如何配置、使用 Kerberos 身份验证与故障排除的更多信息，请参阅 [Kerberos 身份验证](kerberos.md)。


### 密码认证

密码验证是最不安全的验证方法，而不建议使用。不过，Windows SSH 使用密码验证是可行的。要在 Ansible 中使用密码身份验证，就要在仓库文件或 playbook 中，设置 `ansible_password` 变量。使用密码验证需要在 Ansible 控制节点上安装 `sshpass` 软件包。

密码身份验证的工作原理与 WinRM CredSSP 身份验证类似，即向 Windows 主机提供用户名和密码，然后他将执行无约束授权，以访问网络资源。


（End）


