# 运行执行环境

使用 `ansible-navigator`，咱们可在命令行上针对 `localhost` 或远端目标运行执行环境。

> **注意**：除 `ansible-navigator` 外，还有其他工具可以运行执行环境。


## 针对 `localhost` 运行

1. 创建一个 `test_localhost.yaml` playbook；


```yaml
{{#include ../../ansible_quickstart/test_localhost.yaml}}
```

2. 在 `postgresql_ee` 执行环境里，运行该 playbook。

```console
ansible-navigator run ansible_quickstart/test_localhost.yaml --execution-environment-image postgresql_ee --mode stdout --pull-policy missing --container-option='--user=0'
```

> **译注**：该命令的输出包含了 `localhost` 的硬件（主板/CPU（指令集、核心数等）/内存/BIOS/磁盘等）、操作系统与内核版本等全部信息。

咱们可能会注意到，收集到的事实是关于容器，而不是开发者机器的。这是因为这个 ansible playbook 是在容器内运行的。

## 针对远端目标运行

在开始前，请确保咱们具备以下条件：

- 远端目标至少有一个 IP 地址或可解析的主机名；

- 远端主机的有效凭证；

- 一个远端主机上有 `sudo` 权限的用户。


请在 `postgresql_ee` 执行环境中，针对远端主机执行一个 playbook，如下例所示：

1. 为仓库文件创建一个目录；

```console
mkdir inventory
```

2. 在 `inventory` 目录下创建 `host.yaml` 仓库文件；

```yaml
{{#include ../../ansible_quickstart/inventory_updated.yaml}}
```

3. 创建出 `test_remote.yaml` playbook；

```yaml
{{#include ../../ansible_quickstart/test_remote.yaml}}
```

4. 在 `postgresql_ee` 执行环境中运行该 playbook。

用适当的用户名代替其中的 `student`。根据目标主机的身份验证方法，命令中的某些参数是可选的。

```console
ansible-navigator run ansible_quickstart/test_remote.yaml -i ansible_quickstart/inventory_updated.yaml --execution-environment-image postgresql_ee:latest --mode stdout --pull-policy missing --enable-prompts -u hector -kK
```

> **译注**：译者运行此命令报出了 `unreachable` 错误，疑似 Docker 中的执行环境，与 KVM 中的目标虚拟机网络不通导致。排查发现，从 KVM 虚拟机可以 `ping` 通执行环境，但是无法从执行环境 `ping` 通 KVM 中目标机器。仔细分析后，原因是 KVM 虚拟机网络属于 NAT 网络。
>
> 然后运行如下命令：

```console
ansible-playbook -i ansible_quickstart/inventory_updated.yaml ansible_quickstart/test_remote.yaml -K
```

> 获得了对 KVM 中目标主机的该 playbook 访问。命令参数中不带 `k`，因为已经将用户 `hector` 的凭据 `ssh-copy-id` 到目标主机。因此参数 `K` 表示 `sudo` 口令。若不带该参数，将报出 `"to use the 'ssh' connection type with passwords or pkcs11_provider, you must install the sshpass program"`，故需要安装 `sshpass` 软件包。
>
> **参考**：
> - [UNREACHABLE error while running an Ansible playbook](https://stackoverflow.com/a/50883091)
> - [Missing sudo password in Ansible](https://stackoverflow.com/a/51864689)


## 使用社区 EE 映像运行 Ansible

咱们可以使用社区镜像运行 ansible，而无需构建定制执行环境。


使用仅包含 `ansible-core` 的 `community-ee-minimal` 镜像，或包含多个基本专辑的 `community-ee-base` 镜像。请运行以下命令，查看 `community-ee-base` 镜像中包含的集合：


```console
> ansible-navigator collections --execution-environment-image ghcr.io/ansible-community/community-ee-base:latest
Name               Version   Shadowed   Type        Path
0│ansible.builtin    2.18.1    False      contained   /usr/local/lib/python3.13/site-packages/ansible
1│ansible.posix      1.6.2     False      contained   /usr/share/ansible/collections/ansible_collections/ansible/posix
2│ansible.utils      5.1.2     False      contained   /usr/share/ansible/collections/ansible_collections/ansible/utils
3│ansible.windows    2.5.0     False      contained   /usr/share/ansible/collections/ansible_collections/ansible/windows
```

请运行以下在 `community-ee-minimal` 容器内，对 `localhost` 的 Ansible 临时命令：

```console
ansible-navigator exec "ansible localhost -m setup" --execution-environment-image ghcr.io/ansible-community/community-ee-minimal:latest --mode stdout
```

现在，请创建个简单的测试 playbook，并在容器内针对 `localhost` 运行：


```yaml
{{#include ../../ansible_quickstart/test_localhost.yaml}}
```

```console
ansible-navigator run ansible_quickstart/test_localhost.yaml --execution-environment-image ghcr.io/ansible-community/community-ee-minimal:latest --mode stdout --pull-policy missing --container-options='--user=0'
```

> **译注**：原文没有 `--pull-policy missing --container-options='--user=0'`。像原文那样执行该命令，将进行 `Updating the execution environment` 操作；且会报出 `"sudo: a password is required\n"` 错误。
