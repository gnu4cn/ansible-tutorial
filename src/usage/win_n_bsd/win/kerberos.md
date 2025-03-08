# Kerberos 认证

Kerberos 身份验证是 Windows 环境中用于身份验证的一种现代方法。他允许客户端和服务器相互验证对方身份，并支持 AES 等现代加密方法。


## 安装 Kerberos


Kerberos 是通过作为系统软件包一部分的一个 GSSAPI 库提供的。一些发行版会默认安装 Kerberos 的那些软件包，而其他发行版则可能需要手动安装。

要在基于 RHEL/Fedora 的系统上安装 Kerberos 的那些库：


```console
sudo dnf install -y krb5-devel krb5-libs krb5-workstation python3-devel
```


在基于 Debian/Ubuntu 的系统上：


```console
sudo apt-get install krb5-user libkrb5-dev python3-dev
```


在基于 ArchLinux 的系统上：


```console
sudo pacman -S krb5
```

在基于 FreeBSD 的系统上：


```console
sudo pkg install heimdal
```


> **注意**：如果与 `ssh` 连接插件一起使用 Kerberos，则可以忽略 `python3-devel`/`python3-dev` 软件包。他们只有在使用基于 WinRM 的连接和 Kerberos 验证时才需要。

安装好后，即可使用 `kinit`、`klist` 和 `krb5-config` 包即可用。咱们可使用下面的命令测试他们：


```console
$ krb5-config --version                                                                                                ✔  4s 
Kerberos 5 release 1.21.3
```


`psrp` 和 `winrm` 两个连接插件需要额外的 Python 库，以使用 Kerberos 验证。若在 `ssh` 连接下使用 Kerberos，则可以跳过以下步骤。


若咱们选择了 `pipx` 安装 Ansible 的那些指令，则可以通过运行以下命令来安装这些需求：


```console
pipx inject "pypsrp[kerberos]<=1.0.0"  # for psrp
pipx inject "pywinrm[kerberos]>=0.4.0"  # for winrm
```

或者，若咱们选项了 `pip` 安装这些指令：


```console
pip3 install "pypsrp[kerberos]<=1.0.0"  # for psrp
pip3 install "pywinrm[kerberos]>=0.4.0"  # for winrm
```

> 译注：在使用 `pyenv` 时，运行以下命令。

```console
python -m pip install "pypsrp[kerberos]"
python -m pip install "pywinrm[kerberos]"
```

## 配置主机 Kerberos

一旦这些依赖项安装好，Kerberos 就需要加以配置，以便他能与某个域进行通信。大多数 Kerberos 实现都可使用 DNS，或通过 `/etc/krb5.conf` 文件中的手动配置，找到某个域。有关在 `/etc/krb5.conf` 文件中可设置的内容，请参阅 [`krb5.conf`](https://web.mit.edu/kerberos/krb5-latest/doc/admin/conf_files/krb5_conf.html) 了解更多详情。使用 DNS 查找 KDC <sup>1</sup> 的一个简单 `krb5.conf` 文件如下：


```conf
[libdefaults]
    # Not required but helpful if the realm cannot be determined from
    # the hostname
    default_realm = MY.DOMAIN.COM

    # Enabled KDC lookups from DNS SRV records
    dns_lookup_kdc = true
```

> **译注**：KDC，key distribution center，密钥分发中心。

在上面的配置下，当请求服务器 `server.my.domain.com` 的某个 Kerberos 票据时，Kerberos 库将完成一次对 `_kerberos._udp.my.domain.com` 和 `_kerberos._tcp.my.domain.com` 的 SRV 查找，以找到 KDC。如果咱们希望手动设置 KDC 管理域，咱们可使用以下配置：


```conf
[libdefaults]
    default_realm = MY.DOMAIN.COM
    dns_lookup_kdc = false

[realms]
    MY.DOMAIN.COM = {
        kdc = domain-controller1.my.domain.com
        kdc = domain-controller2.my.domain.com
    }

[domain_realm]
    .my.domain.com = MY.DOMAIN.COM
    my.domain.com = MY.DOMAIN.COM
```


在此配置下，任何带有 DNS 后缀 `.my.domain.com` 及 `my.domain.com` 本身的票据请求，都将发送到 `domain-controller1.my.domain.com` 这个 KDC，并可回退到 `domain-controller2.my.domain.com`。


有关 Kerberos 库如何尝试查找 KDC 的更多信息，请参阅 [MIT Kerberos 文档](https://web.mit.edu/kerberos/krb5-latest/doc/admin/realm_config.html)。


> **注意**：本小节中的信息，假定咱们使用的是 MIT 的 Kerberos 实现，而这通常是大多数 Linux 发行版的默认设置。像是 FreeBSD 或 macOS 等平台，使用了名为 Heimdal 的别的 GSSAPI 实现，其作用方式与 MIT Kerberos 类似，但某些行为可能有所不同。


## 验证 Kerberos 配置


要验证 Kerberos 是否正常工作，咱们可使用 `kinit` 命令获取域中某名用户的票据。以下命令将请求域 `XFOSS.NET` 中用户 `hector.peng` 的一个票据：


```console
$ kinit hector.peng@XFOSS.NET
Password for hector.peng@XFOSS.NET:
```

若密码正确，命令将不返回任何输出。要验证是否已获得该票据，咱们可使用 `klist` 命令：

```console
$ klist
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: hector.peng@XFOSS.NET

Valid starting       Expires              Service principal
2025-03-07T19:01:10  2025-03-08T19:01:10  krbtgt/XFOSS.NET@XFOSS.NET
```

如果取得票据成功，那么这就验证了 Kerberos 的配置是正确的，同时该用户可从该 KDC 获取到一张票据授予票据 (Ticket Granting Ticket, `TGT`)。而如果 `kinit` 无法找到所请求域的 KDC，就要通过确保 DNS 可以通过使用 SRV 记录定位到 KDC，或在 `krb5.conf` 中 KDC 已被手动映射，验证咱们的 Kerberos 配置。


> **译注**：使用 `kadmin` （`sudo kadmin.local`）的子命令 `list_principals`，可列出 KDC 上已添加用户、主机及服务 principals。


```console
$ sudo kadmin.local
kadmin.local:  list_principals
K/M@XFOSS.NET
hector.peng@XFOSS.NET
host/almalinux-61.xfoss.net@XFOSS.NET
host/kdc.xfoss.net@XFOSS.NET
https/win10-133.xfoss.net@XFOSS.NET
https/win2k19-151.xfoss.net@XFOSS.NET
kadmin/admin@XFOSS.NET
kadmin/changepw@XFOSS.NET
krbtgt/XFOSS.NET@XFOSS.NET
root/admin@XFOSS.NET
```


在基于 MIT Kerberos 的系统上，咱们可使用 `kvno` 命令，验证是否能获取到某个特定服务的服务票据。例如，若咱们使用基于 WinRM 的连接，验证 `server.my.domain.com` 的身份，则可使用以下命令，验证咱们的 TGT 是否能获取到目标服务器的服务票据：


```console
$ kvno https/win10-133.xfoss.net
https/win10-133.xfoss.net@XFOSS.NET: kvno = 2
```

> **译注**：要首先添加服务 principal 到 KDC。

```console
sudo kadmin.local
addprinc -randkey https/win10-133.xfoss.net
ktadd https/win10-133.xfoss.net
```

> 参考：[How to configure Kerberos service principals](https://documentation.ubuntu.com/server/how-to/kerberos/configure-service-principals/index.html)


`klist` 命令也可用于验证票据是否已存储在 Kerberos 的缓存中：


```console
$ klist
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: hector.peng@XFOSS.NET

Valid starting       Expires              Service principal
2025-03-07T19:01:10  2025-03-08T19:01:10  krbtgt/XFOSS.NET@XFOSS.NET
        Flags: FI
2025-03-07T19:23:39  2025-03-08T19:01:10  https/win10-133.xfoss.net@XFOSS.NET
        Flags: FT
```

在面的示例中，我们有着存储在 `krbtgt` 服务 principal 下的 TGT，以及存储在其自己服务 principal 下的 `http/win10-133.xfoss.net` 票据。

`kdestroy` 命令可用于移除票据缓存。


## 票据管理

要在 Ansible 下使用 Kerberos 验证，用户的 Kerberos TGT 必须存在，这样 Ansible 才能请求目标服务器的服务票据。像 `ssh` 的一些连接插件就要求 TGT 存在，并能被 Ansible 的控制进程访问。而像是 `psrp` 和 `winrm` 等其他连接插件，则会在仓库中提供了用户的密码时，可自动获取用户的 TGT。


要手动获取某名用户的 TGT，请按照 [验证 Kerberos 配置](#验证-Kerberos-配置) 中所示的那样，使用该用户的用户名和域，运行 `kinit` 命令。当 Ansible 中的连接插件请求 Kerberos 验证时，将自动使用该 TGT。


若咱们使用的是 `psrp` 或 `winrm` 连接插件，且用户密码已在仓库中提供，则连接插件会自动为该名用户获取 TGT。这是通过使用用户的用户名和密码，运行 `kinit` 命令实现的。该 TGT 将存储在一个临时凭据缓存中，并用于任务执行。


## 委派

Kerberos 的委派，允许凭据历经多个跳转点。当咱们需要对某个服务器进行身份验证，然后让该服务器代表咱们对另一服务器进行身份验证时，这就很有用了。要启用凭据委派，咱们必须：


- 在使用 `kinit` 获取凭据时，请求一张可转发的 TGT；
- 请求连接插件允许到该服务器的委派；
- 该 AD 用户未被标记为敏感用户及不能授权，也不是 `Protected Users` 组的成员；
- 取决于 `krb5.conf` 配置，目标服务器可能需要通过其 AD 对象委派设置，允许无约束的委派。


要请求一张可转发的 TGT，可以在 `kinit` 命令中添加 `-f` 开关，或者在 `krb5.conf` 文件的 `[libdefaults]` 小节中，设置 `forwardable = true` 选项。若咱们使用的是 `psrp` 或 `winrm` 连接插件，从仓库中的用户密码检索 TGT，那么就将自动请求一个可转发的 TGT。

要让连接插件委派凭据，就需要在仓库中，设置以下主机变量：


```yaml
# psrp
ansible_psrp_negotiate_delegate: true

# winrm
ansible_winrm_kerberos_delegation: true

# ssh
ansible_ssh_common_args: -o GSSAPIDelegateCredentials=yes
```


> **注意**：在 `~/.ssh/config` 文件中设置 `GSSAPIDelegateCredentials yes`，以允许对所有 SSH 连接进行委派也是可行的。


要验证某名用户是否被允许委派其凭据，咱们可在同一域中的 Windows 主机上，运行以下 PowerShell 脚本：


```powershell
{{#include ./verify_delegation.ps1}}
```


新版本的 MIT Kerberos 已在 `krb5.conf` 文件的 `[libdefaults]` 小节，增加了一个配置选项 `enforce_ok_as_delegate`。若该选项被设置为 `true`，就只有在目标服务器账户允许无约束委派时，委派才会生效。要在 Windows 计算机主机上检查或设置无约束委派，咱们可使用以下 PowerShell 脚本：


```powershell
# Check if the server allows unconstrained delegation
(Get-ADComputer -Identity WINHOST -Properties TrustedForDelegation).TrustedForDelegation

# Enable unconstrained delegation
Set-ADComputer -Identity WINHOST -TrustedForDelegation $true
```


> **译注**：上述 PowerShell 脚本需要 RSAT 并启用 “AD 与 LDS 管理工具”。
>
> 参考：[The term 'get-ADComputer' is not recognized as the name of a cmdlet](https://stackoverflow.com/q/68081362/12288760)。


要验证凭据委派是否有效，咱们可在 Windows 节点上使用 `klist.exe` 命令，验证票据是否已被转发。输出结果应显示票据服务器为 `krbtgt/MY.DOMAIN.COM @ MY.CDOMAIN.COM`，且票据标志中已包含 `forwarded`。


```console
$ ansible WINHOST -m ansible.windows.win_command -a klist.exe

WINHOST | CHANGED | rc=0 >>

Current LogonId is 0:0x82b6977

Cached Tickets: (1)

#0>     Client: username @ MY.DOMAIN.COM
        Server: krbtgt/MY.DOMAIN.COM @ MY.DOMAIN.COM
        KerbTicket Encryption Type: AES-256-CTS-HMAC-SHA1-96
        Ticket Flags 0x60a10000 -> forwardable forwarded renewable pre_authent name_canonicalize
        Start Time: 8/30/2024 14:15:18 (local)
        End Time:   8/31/2024 0:12:49 (local)
        Renew Time: 9/6/2024 14:12:49 (local)
        Session Key Type: AES-256-CTS-HMAC-SHA1-96
        Cache Flags: 0x1 -> PRIMARY
        Kdc Called:
```


如果出现任何问题，`klist.exe` 的输出都将没有 `forwarded` 这个标志，同时服务器将是目标服务器 principal，而不是 `krbtgt`。

```console
$ ansible WINHOST -m ansible.windows.win_command -a klist.exe

WINHOST | CHANGED | rc=0 >>

Current LogonId is 0:0x82c312c

Cached Tickets: (1)

#0>     Client: username @ MY.DOMAIN.COM
        Server: http/winhost.my.domain.com @ MY.DOMAIN.COM
        KerbTicket Encryption Type: AES-256-CTS-HMAC-SHA1-96
        Ticket Flags 0x40a10000 -> forwardable renewable pre_authent name_canonicalize
        Start Time: 8/30/2024 14:16:24 (local)
        End Time:   8/31/2024 0:16:12 (local)
        Renew Time: 0
        Session Key Type: AES-256-CTS-HMAC-SHA1-96
        Cache Flags: 0x8 -> ASC
        Kdc Called:
```


## Kerberos 故障排除


Kerberos 依赖于正确配置的环境才能工作。可能导致 Kerberos 身份验证失败的一些常见问题包括：

- 给 Windows 主机设置的主机名，是个别名或 IP 地址；
- Ansible 控制节点上的时间，未与 AD 域控制器同步；
- KDC realm 在 `krb5.conf` 文件中未被正确设置，或无法通过 DNS 解析。


若使用的是 MIT Kerberos 实现，咱们可设置环境变量 `KRB5_TRACE=/dev/stdout`，以获取有关 Kerberos 库正在做什么的更详细信息。这样做对调试 Kerberos 库的问题，比如 KDC 查找行为、时间同步问题，及服务器名称查找失败等，非常有用。


## 附录（译注）

Windows AD 采用的是 Kerberos 认证。在创建 AD 域过程中，DC 服务器也是 KDC 服务器，同时会在 DNS 中建立 KDC 的 SRV 记录条目。将 Windows 主机加入 AD 域的过程，就会在 KDC 上为该主机添加主机 principal。而创建域用户的过程，就会在 KDC 上添加用户 principal。


> 参考：
>
> - [Set up a Windows 10 Client for a Linux KDC Realm](https://serverfault.com/a/825287/994825)

（End）


