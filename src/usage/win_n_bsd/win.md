# 使用 Ansible 管理 Windows 主机


管理 Windows 主机不同于管理 POSIX 主机。如果咱们曾管理过运行 Windows 的节点，请查看这些主题。


## 导入 Windows

**Bootstrapping Windows**


Windows 节点必须运行 Windows Server 2016 或 Windows 10 或更新版本。因为这些版本的 Windows 默认带有 PowerShell 5.1，而没有引导 Windows 节点的额外要求。


每个 Windows 版本的支持，都与各个操作系统的扩展支持生命周期挂钩，通常为自发布之日起 10 年。Ansible 已针对 Windows 的这些服务器变种进行过测试，但仍应兼容 Windows 10 和 11 等桌面版本。


## 连接到 Windows 节点


Ansible 默认使用 OpenSSH 连接 POSIX 的托管节点。Windows 节点也可使用 SSH，但历来他们使用 [WinRM](https://learn.microsoft.com/en-us/windows/win32/winrm/about-windows-remote-management) 作为连接的传输。可用于 Windows 节点的受支持连接插件有：

- 经由 WinRM 的 PowerShell 远程操作 - [`psrp`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/psrp_connection.html#psrp-connection)
- SSH - [`ssh`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html#ssh-connection)
- Windows 远程管理 - [`winrm`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/winrm_connection.html#winrm-connection)


## 关于 PSRP 与 WinRM

Ansible 历来都使用 Windows 远程管理（ `WinRM` ）作为管理 Windows 节点的连接协议。`psrp` 和 `winrm` 两个连接插件，都通过 WinRM 运行，并可用作 Windows 节点的连接插件。`psrp` 连接插件是种较新的连接插件，与 `winrm` 连接插件相比有以下优点：


- 可稍微快一些；
- 在 Windows 节点处于负载状态时，不易受超时问题影响；
- 对代理服务器有更好的支持。

有关如何配置 WinRM 及如何在 Ansible 中使用 `psrp` 和 `winrm` 连接插件的更多信息，请参阅 [Windows 远程管理](./win/winrm.md)。

> **译注**：
>
> - WinRM 的 HTTP 建立在 `5985` 端口，HTTPS 建立在 `5986` 端口，使用主机变量 `ansible_port: 5985` 指定 Ansible 连接 WinRM 的 HTTP 端口；
>
> - 使用 `ansible_winrm_server_cert_validation: ignore` 的主机变量，忽略因 WinRM HTTPS 使用了自签名证书导致的 `certificate verify failed: self-signed certificate` 报错；
>
> - 使用 `ansible_winrm_transport: ntlm` 以使用本地用户账户和密码进行身份验证。


## SSH

SSH 是用于 POSIX 节点的传统连接插件，但也可用于管理 Windows 节点，取代传统的 `psrp` 或 `winrm` 连接插件。

> **注意**：尽管自 Ansible 2.8 版本起，Ansible 就支持于 Windows 节点上使用 SSH 连接插件，但直到 2.18 版才加入正式支持。


与基于 WinRM 的传输方式相比，使用 SSH 的传输有以下这些好处：

- 在一些非域的环境中，SSH 更容易配置；
- SSH 支持基于密钥的身份验证，相较证书认证更易于管理；
- SSH 的文件传输比 WinRM 的更快。


有关如何为 Windows 节点配置 SSH 的详细信息，请参阅 [Windows SSH](./win/ssh.md)。

> **译注**：首次在 Ansible 中使用 SSH 连接 Windows 主机（以 Server 2019 为例）时，会报出错误：`"Using a SSH password instead of a key is not possible because Host Key checking is enabled and sshpass does not support this.  Please add this host's fingerprint to your known_hosts file to manage this host."`。
>
> 此时需往 `~/.ansible.cfg` 中加入：

```ini
[defaults]
host_key_checking = false
```

> 便可在 Ansible 中透过 SSH 连接 Windows 主机。随后即使移除配置文件中的 `host_key_checking = false` 选项，仍然可以持续连接。

## 有哪些可用模组？


大多数 Ansible 核心模组，都是针对类 Unix 机器及其他通用服务的组合而编写的。由于这些模组都是用 Python 编写的，若使用了 Windows 上没有的 API，他们将不工作。

有些专门的 Windows 模组，是用 PowerShell 编写的，用于在 Windows 主机上运行。这些模组的列表，可在 [`Ansible.Windows`](https://docs.ansible.com/ansible/latest/collections/ansible/windows/index.html#plugins-in-ansible-windows)、[`Community.Windows`](https://docs.ansible.com/ansible/latest/collections/community/windows/index.html#plugins-in-community-windows)、[`Microsoft.Ad`](https://docs.ansible.com/ansible/latest/collections/microsoft/ad/index.html#plugins-in-microsoft-ad)、[`Chocolatey.Chocolatey`](https://docs.ansible.com/ansible/latest/collections/chocolatey/chocolatey/index.html#plugins-in-chocolatey-chocolatey) 及其他专辑中找到。


此外，以下 Ansible 核心模组/动作插件，也适用于 Windows：


- `add_host`
- `assert`
- `async_status`
- `debug`
- `fail`
- `fetch`
- `group_by`
- `include`
- `include_role`
- `include_vars`
- `meta`
- `pause`
- `raw`
- `script`
- `set_fact`
- `set_stats`
- `setup`
- `slurp`
- `template`（又是 `win_template`）
- `wait_for_connection`

## 使用 Windows 作为控制节点

由于平台 API 的限制，Ansible 无法作为控制节点在 Windows 上运行。不过，咱们可以使用 Windows Subsystem for Linux (`WSL`)，或在容器中运行 Ansible。


> **注意**：Ansible 不支持 `WSL`，而不应将 `WSL` 用于生产系统。


## Windows 的事实


Ansible 从 Windows 收集事实的方式，与其他 POSIX 主机类似，但也有一些差异。由于向后兼容，或根本不可用的原因，某些事实可能可是不同。

要查看 Ansible 从 Windows 主机收集的信息，请运行 `setup` 模组。


```console
ansible -m setup win10-133 -i playbook_executing/inventory.yml
```

## 常见的 Windows 问题

### 命令可在本地运行，但不能在 Ansible 下运行

Ansible 会经由一次网络登录执行命令，而这会改变 Windows 授权操作的方式。这可能导致在本地运行的那些命令，于 Ansible 下失败。这些失败的示例有：

- 进程无法将该名用户的凭据，委派给某项网络资源，从而导致 `'Access is Denied'` 或 `'Resource Unavailable'` 等错误；
- 需要交互式会话的应用，将无法运行；
- 在通过网络登录运行时，某些 Windows API 会受限；
- 某些任务需要访问 [`DPAPI` 的秘密存储](https://www.thehacker.recipes/ad/movement/credentials/dumping/dpapi-protected-secrets)，而 `DPAPI` 的秘密存储通常对网络登录不可用。

解决此问题的常见方法，是使用 [掌握权限升级：`become`](../playbook/executing/become.md) 来运行带有显式凭证的某个命令。在 Windows 上使用 `become`，会将网络登录更改为交互式登录，如果向成为的身份提供了显式的凭证，该命令就能访问网络资源，以及解锁 `DPAPI` 存储。

另一选项是在连接插件上，使用允许凭据委派的某种身份验证选项。对于 SSH，这可以显式的用户名和密码，或通过启用了委派的 [Kerberos/GSSAPI 登录](https://www.microfocus.com/documentation/rsit-server-windows/8-4-0/windows-server-guide/gssapi_auth_ov.html) 实现。而对于基于 WinRM 的连接，则可使用带有委派的 CredSSP 或 Kerberos。更多信息请参阅特定于连接的文档。


### 凭据被拒绝

连接 Windows 主机时凭证可能会被拒绝的原因有几种。一些常见原因有：

- 用户名或密码不正确；
- 该用户的账号被锁定、禁用，或不允许登陆到该服务器；
- 该用户账号不允许经由网络登陆；
- 该用户账号不是本地管理员组的成员；
- 该用户账号是个本地用户，且 `LocalAccountTokenFilterPolicy` 未设置。


要验证凭据是否正确，或该用户是否被允许登录主机，咱们可在该 Windows 主机上，运行以下 PowerShell 命令，查看上次失败的登录尝试。此命令将输出事件详细信息，包括表明该次登陆失败原因的 `Status` 与 `Sub Status` 错误代码。


```powershell
Get-WinEvent -FilterHashtable @{LogName = 'Security'; Id = 4625} |
    Select-Object -First 1 -ExpandProperty Message
```

虽然并非所有连接插件，都要求连接用户是本地管理员组的成员，但这通常是默认配置。如果用户不是本地 `Administrators` 组的成员，或者是名本地用户，但 `LocalAccountTokenFilterPolicy` 未设置，则身份验证将失败。


（End）


