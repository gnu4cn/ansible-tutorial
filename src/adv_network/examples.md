# Anisble 网络示例

本文档介绍了使用 Ansible 管理咱们网络基础设施的一些示例。


## 先决条件


此示例有以下要求：

- 已安装 **Ansible 2.10**（或更高版本）。更多信息，请参阅 [安装 Ansible](../installing.md)；
- 一或多个与 Ansible 兼容的网络设备；
- 对 YAML 有基本掌握。参见 [YAML 语法](../refs/YAML_syntax.md)；
- 对 Jinja2 模板有基本掌握。有关详细信息，请参阅 [模板化 (Jinja2)](../usage/playbook/using/templating.md)；
- 会使用基本的 Linux 命令；
- 有网络交换机与路由器配置的基础知识。


## 仓库文件中的分组与变量

所谓 `inventory` 文件，是个定义了主机到组的映射关系的 YAML 或类 INI 的配置文件。

在这个示例中，仓库文件定义了 `eos`、`ios`、`vyos` 三个组，以及名为 `switches` 的 “分组的组，group of groups”。有关子组别与仓库文件的更多详情，请参阅 [Ansible 仓库分组文档](../usage/inventories_building.md#继承变量值组别组的组变量)。


由于 Ansible 是种灵活的工具，因此有多种指定连接信息与凭证的方法。我们建议在仓库文件中，使用 `[my_group:vars]` 这种能力。


```ini
{{#include ../../network_run/example_inventory}}
```


若咱们使用了 `ssh-agent`，那么就不需要 `ansible_password` 这行。若咱们使用的是 ssh 密钥而非 `ssh-agent`，并且有多个密钥，就要在 `[group:vars]` 小节中，以 `ansible_ssh_private_key_file=/path/to/correct/key` 变量，指定出每个连接的密钥。有关 `ansible_ssh_` 的那些选项的更多信息，请参阅 [连接到主机：行为清单参数](../usage/inventories_building.md#连接主机行为清单参数)。


> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> 绝不要以明文方式存储密码。


### 用于密码加密的 Ansible vault

Ansible 的 “Vault” 功能，允许咱们将密码或密钥等敏感数据，保存在加密文件中，而不是以纯文本形式保存在 playbook，或角色中。然后，这些 vault 文件就可被分发或置于源代码控制系统中。更多信息，请参阅 [使用加密变量与文件](../usage/vault/encrypting.md)。


下面是咱们在变量中间，指定出 SSH 密码（使用 Ansible Vault 加密）时，看起来的样子：


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: vyos.vyos.vyos
ansible_user: my_vyos_user
ansible_ssh_pass: !vault |
                  $ANSIBLE_VAULT;1.1;AES256
                  39336231636137663964343966653162353431333566633762393034646462353062633264303765
                  6331643066663534383564343537343334633031656538370a333737656236393835383863306466
                  62633364653238323333633337313163616566383836643030336631333431623631396364663533
                  3665626431626532630a353564323566316162613432373738333064366130303637616239396438
                  9853
```


### 常用仓库变量

以下变量是仓库中所有平台的常用变量，尽管可针对特定仓库组或主机，他们可被重写。

- `ansible_connection`：Ansible 使用 `ansible-connection` 这个设置，决定如何连接远端设备。在使用 Ansible 网络时，要此设置为合适的网络连接选项，如 `ansible.netcommon.network_cli`，这样 Ansible 就会将远端节点，视为具有有限执行环境的网络设备。如果没有这个设置，Ansible 就会尝试使用 ssh 连接到远端节点，并在网络设备上执行 Python 脚本，这将会失败，因为 Python 通常在网络设备上不可用；

- `ansible_network_os`：通知 Ansible 该主机所对应的网络平台。在使用 `ansible.netcommon.*` 连接选项时，此选项是必需的；
- `ansible_user`：连接到远端设备（交换机）的用户。若没有此设置，则将使用运行 `ansible-playbook` 的用户名。指定出连接到网络设备上的用户；
- `ansible_password`：`ansible_user` 对应的登录密码。若未指定，将使用 SSH 密钥；
- `ansible_become`：是否应使用 `enable` 模式（特权模式），请参阅下一小节；
- `ansible_become_method`：应使用河中类型的 `become`，对于 `network_cli` 唯一有效的选择便是 `enable`。


### 权限提升

一些网络平台，如 Arista EOS 和 Cisco IOS，有着不同权限模式的概念。而一些网络模组，比如修改包括用户等系统状态的模组，就只能在高权限状态下运作。Ansible 支持在使用 `ansible.netcommon.network_cli` 时的 `become`。这一特性允许为需要高权限的特定任务，提升权限。添加 `become: yes` 以及 `become_method: enable` 设置，就通知了 Ansible 在执行任务前，进入特权模式，如下所示：


```ini
[eos:vars]
ansible_connection=ansible.netcommon.network_cli
ansible_network_os=arista.eos.eos
ansible_become=yes
ansible_become_method=enable
```

更多信息，请参阅 [在网络模组下使用 `become`](../usage/playbook/executing/become.md#become-与网络自动化) 指南。


### 跳转主机

**Jump hosts**


如果 Ansible 控制节点没有到远端设备的直接路由，咱们就需要使用一个跳转主机，Jump Host，请参阅 [Ansible 网络代理命令](./troubleshooting.md#delegate_to-与-ProxyCommand) 指南，了解如何达到这一目的。


## 示例 1：使用 playbook 收集事实并创建备份文件


Ansible 的事实模组，可以收集系统信息 “事实”，并将其提供给咱们 playbook 的其余部分。


Ansible 网络随附了许多特定于网络的事实模组。在本例中，我们会使用 `_facts` 的模组 `arista.eos.eos_facts`、`cisco.ios.ios_facts` 以及 `vyos.vyos.vyos_facts`，连接远端网络设备。由于凭据未使用模组参数显式传递，因此 Ansible 会使用仓库文件中的用户名和密码。

Ansible 的 “网络事实模组” 会从系统收集信息，并将结果存储在以 `ansible_net_` 为前缀的事实中。这些模组收集的数据，在模组文档的 *返回值，Return Values* 小节中有说明，本例中为 [`arista.eos.eos_facts`](https://docs.ansible.com/ansible/latest/collections/arista/eos/eos_facts_module.html#ansible-collections-arista-eos-eos-facts-module) 和 [`vyos.vyos.vyos_facts`](https://docs.ansible.com/ansible/latest/collections/vyos/vyos/vyos_facts_module.html#ansible-collections-vyos-vyos-vyos-facts-module)。稍后在 “显示一些事实” 任务中，咱们就可以使用这些事实，比如 `ansible_net_version`。


为确保咱们调用了正确的模式 (`*_facts`)，任务会根据仓库文件中定义的组有条件地运行，有关在 Ansible Playbook 中使用条件的更多信息，请参阅 [“使用 `when` 的基本条件”](../usage/playbook/using/conditionals.md#使用-when-的基本条件)。


在这个示例中，我们将创建一个包含了一些网络交换机的仓库文件，然后运行一个 playbook 来连接到这些网络设备，并返回一些相关信息。


### 步骤 1：创建仓库

首先，创建一个名为 `inventory` 的文件，其中包含：


```ini
{{#include ../../network_run/inventory}}
```

> **译注**：这里 Arista EOS、Cisco IOSXE 与 VyOS 三个设备均使用了 SSH 密钥认证。IOS 设备指定了 `ansible_become_password` 密码。

### 步骤 2：创建 playbook


接下来，创建一个名为 `facts-demo.yml`，包含以下内容的 playbook 文件：


```yaml
{{#include ../../network_run/facts_demo.yml}}
```

> **译注**：这里的 playbook 移除了三种设备 `Write facts to disk using a template` 任务中的 `Model: {{ hostvars[host].ansible_net_model }}`，因为实验里三种设备都是运行在 GNS3 中的虚拟机。可能没有 `model` 信息而会报出错误：

```console
The task includes an option with an undefined variable.. 'ansible.vars.hostvars.HostVarsVars object' has no attribute 'ansible_net_model'

The error appears to be in '/home/hector/ansible-tutorial/network_run/facts_demo.yml': line 32, column 7, but may be elsewhere in the file depending on the exact syntax problem.

The offending line appears to be:

- name: Write facts to disk using a template
  ^ here
```

### 步骤 3：运行该 playbook


要运行这个 playbook，在某个控制台提示符中，运行以下命令：

```console
ansible-playbook -i network_run/example_inventory network_run/facts_demo.yml
```

这将返回与下面类似的输出：

```console
...

PLAY RECAP *********************************************************************************************************************************
arista-sw                  : ok=7    changed=1    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0
ios-sw                     : ok=6    changed=2    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0
vyos-sw                    : ok=6    changed=1    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0

```


### 步骤 4：检查该 playbook 的结果

接下来，查看我们创建出的包含了那些交换机事实的文件内容：

```console
$ cat /tmp/switch-facts
EOS device info:
  Hostname: arista-sw
  Version: 4.24.3M
  Serial:

IOS device info:
  Hostname: ios-sw
  Version: 17.15.1
  Serial: 2048001

VyOS device info:
  Hostname: vyos
  Version: VyOS 1.4.0
  Serial: Hardware
```


咱们还可以查看那些备份文件：


```console
$ find /tmp/backups
/tmp/backups
/tmp/backups/ios-sw
/tmp/backups/ios-sw/ios-sw.bck
/tmp/backups/vyos-sw
/tmp/backups/vyos-sw/vyos-sw.bck
/tmp/backups/arista-sw
/tmp/backups/arista-sw/arista-sw.bck
```


如果 `ansible-playbook` 命令失败，请按照 [网络调试和故障排除指南](./troubleshooting.md) 中的调试步骤进行操作。



## 示例 2：使用平台无关模组简化 playbook


(本示例最初出现在 Sean Cavanaugh -[@IPvSean](https://github.com/IPvSean) 撰写的博文 “Deep Dive on `cli_command` for Network Automation” 中。）


若咱们的环境中有两个或更多的网络平台，那么咱们可使用平台无关的模组，简化咱们的 playbook。咱们可在诸如 `arista.eos.eos_config`、`cisco.ios.ios_config` 以及 `junipernetworks.junos.junos_config` 这些特定于平台模组的地方，使用诸如 `ansible.netcommon.cli_command` 或 `ansible.netcommon.cli_config` 这些独立于平台的模组。这样做会减少了咱们在 playbook 中所需的任务和条件数量。


> **注意**：独立于平台的模组需要 `ansible.netcommon.network_cli` 连接插件。


### 带有平台特定模组的示例 playbook

这个示例假定有三种平台：Arista EOS、Cisco NXOS 与 Juniper JunOS。在没有独立于平台的模组下，示例 playbook 可能包含以下三个有着平台特定命令的任务：


```yaml
---
    - name: Run Arista command
      arista.eos.eos_command:
        commands: show ip int br
      when: ansible_network_os == 'arista.eos.eos'

    - name: Run Cisco NXOS command
      cisco.nxos.nxos_command:
        commands: show ip int br
      when: ansible_network_os == 'cisco.nxos.nxos'

    - name: Run Vyos command
      vyos.vyos.vyos_command:
        commands: show interface
      when: ansible_network_os == 'vyos.vyos.vyos'
```

### 使用独立于平台的 `cli_command` 模组简化 playbook


你可以像下面这样，以独立于平台的 `ansible.netcommon.cli_command` 模组，替换这些特定于平台的模组：


```yaml
{{#include ../../network_run/platform-specific_example.yml}}
```


若咱们按平台类型，使用一些分组与 `group_vars`，那么这个 playbook 可进一步简化为：


```yaml
{{#include ../../network_run/platform-specific_example.refactored.yml}}
```


在 [平台独立示例](https://github.com/network-automation/agnostic_example) 中，咱们可以看到使用 `group_vars` 的完整示例，以及配置备份的示例。


### 在 `ansible.netcommon.cli_command` 下使用多个输入提示符

`ansible.netcommon.cli_command` 模组还支持多个输入提示符。


```yaml
---
- name: Change password to default
  ansible.netcommon.cli_command:
    command: "{{ item }}"
    prompt:
      - "New password"
      - "Retype new password"
    answer:
      - "mypassword123"
      - "mypassword123"
    check_all: True
  loop:
    - "configure"
    - "rollback"
    - "set system root-authentication plain-text-password"
    - "commit"
```


有关此命令的完整文档，请参见 [`ansible.netcommon.cli_command`](https://docs.ansible.com/ansible/2.9/modules/cli_command_module.html#cli-command-module)。


## 实现说明


### 演示变量

虽然要将数据写入磁盘并不需要这些任务，但在本示例中使用了这些任务，来演示了访问给定设备或已命名主机事实的一些方式。

Ansible 的 `hostvars`，允许咱们访问某个命名主机的变量。若没有 `hostvars` 这一特性，我们将返回当前主机的详细信息，而不是某个命名主机的详细信息。

更多信息，请参阅 [“有关 Ansible 的信息：魔法变量”](../usage/playbook/using/facts_and_magic_vars.md#关于-ansible-的信息魔法变量)。


### 获取运行配置

`arista.eos.eos_config` 和 `vyos.vyos.vyos_config` 两个模组都有个 `backup: ` 选项，设置了该选项后，模组就会在进行任何更改前，创建出远端设备当前运行配置的完整备份。备份文件会写入 playbook 根目录下的 `backup` 文件夹。如果该目录不存在，则会被创建。

为演示如何将备份文件迁移到别的位置，我们注册了结果，并迁移了存储在 `backup_path` 中路径的文件。


请注意，在使用任务中的变量时，我们使用了双引号（`"`）和双括号（`{{...}}`）这种方式，告诉 Ansible 这是个变量。


## 故障排除

若咱们收到连接错误，请仔细检查仓库与 playbook 是否有错字或缺行。如果问题仍然出现，请依照 [网络调试和故障排除指南](./troubleshooting.md) 中的调试步骤进行操作。


（End）


