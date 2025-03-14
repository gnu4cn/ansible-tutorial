# 使用 Ansible 网络角色

角色是一组一起工作的 Ansible 的默认值、文件、任务、模板、变量及其他 Ansible 组件。正如咱们在 [“运行咱们第一个命令和 playbook”](initial.md) 中所看到的，从命令迁移到 playbook 就可以很容易运行多个任务，及以同一顺序重复相同的任务。而从 playbook 转移到角色，则可以更方便地重用和共享咱们的有序任务。咱们可以看看 Ansible Galaxy，他能让咱们共享角色，以及直接使用他人的角色或受其启发。


## 理解角色

那么，角色到底是什么，咱们为何要重视角色？Ansible 角色本质上就是一些拆分为已知文件结构的 playbook。从 playbook 迁移到角色可以让共享、阅读和更新 Ansible 工作流程变得更容易。用户可以编写自己的角色。因此，举例来说，咱们不必编写咱们自己的 DNS playbook。相反，咱们可以指定出某个 DNS 服务器，以及某个角色来为咱们配置他。


为了进一步简化咱们的工作流程，Ansible 网络团队为常见网络用例编写了一系列角色。使用这些角色意味着咱们不必重新发明轮子。与其编写和维护咱们自己的 `create_vlan` playbook 或角色，咱们可以 Ansible 的网络角色来完成这些工作，咱们转而专注于设计、编纂和维护描述网络拓扑与仓库的解析器模板。请查看 Ansible Galaxy 上的 [网络相关角色](https://galaxy.ansible.com/ui/search/?keywords=network)。


## 一个 DNS playbook 的示例


为了演示角色是什么的概念，下面的 `playbook.yml` 示例是个包含了两个任务的 YAML 文件。该 Ansible playbook 在某个 Cisco IOS XE 设备上配置主机名，然后配置 DNS（域名系统）服务器。

```yaml
{{#include ../../network_run/cisco_dns.yml}}
```

> **译注**：上述 playbook 对应的仓库文件配置如下。

```yaml
leafs:
  hosts:
    ...
    cisco-r1:
      ansible_host: 192.168.122.69
      ansible_network_os: cisco.ios.ios
      ansible_ssh_user: hector
      ansible_network_cli_ssh_type: paramiko

    ...
  vars:
    ansible_connection: ansible.netcommon.network_cli

```

> 之所以这里配置了 `ansible_network_cli_ssh_type: paramiko`，是因为在默认的 `ansible_network_cli_ssh_type: libssh` 下会报出 `libssh: The authenticity of host '192.168.122.69' can't be established due to 'Host is unknown: 95:...83:d1'.\nThe ssh-rsa key fingerprint is SHA1:lde...g9E.` 错误。紧接着报出了 `"No existing session"` 错误。在 `~/.ansible.cfg` 中添加如下设置后解决了这两个问题。


```ini
[paramiko_connection]
host_key_auto_add = True
look_for_keys = False
```

> 此时需用以下命令运行这个 playbook。

```console
ansible-playbook -i network_run/inventory.yml network_run/cisco_dns.yml -bkK
```

> 其中 `-bkK` 表示运行此 playbook 需要 `become`（`-b`）、需要提供 SSH 密码（`-k`）及需要提供 `become`/`enable` 的密码（`-K`）。

> 参考：
>
> - [paramiko: The authenticity of host '[ios-xe-mgmt-latest.cisco.com]:8181](https://community.cisco.com/t5/network-devices/paramiko-the-authenticity-of-host-ios-xe-mgmt-latest-cisco-com/m-p/4919606/highlight/true#M392)
>
> - [Can’t connect to Cisco router using network_cli but ssh from raw module works fine](https://forum.ansible.com/t/cant-connect-to-cisco-router-using-network-cli-but-ssh-from-raw-module-works-fine/4281)


```console
SSH password:
BECOME password[defaults to SSH password]:

PLAY [configure cisco routers] ************************************************************************************************************

TASK [configure hostname] *****************************************************************************************************************
changed: [cisco-r1]

TASK [configure DNS] **********************************************************************************************************************
changed: [cisco-r1]

PLAY RECAP ********************************************************************************************************************************
cisco-r1                   : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```


这个 playbook 配置了主机名和 DNS 服务器。咱们可在 Cisco IOSv（译注：在 GNS3 上运行的实验用虚拟路由器）路由器 `cisco-r1` 上验证该配置：


```console
cisco-r1#sh run | i name
hostname cisco-r1
ip domain name xfoss.com
ip name-server 223.5.5.5
ip name-server 223.6.6.6
multilink bundle-name authenticated
username hector password 7 01435F550E5A51
  username hector
```

### 将这个 playbook 转换成角色

下一步是将此 playbook 转换为可重用的角色。咱们可以手动创建目录结构，也可以使用 `ansible-galaxy init` 命令，创建出角色的标准框架。

```console
$ ansible-galaxy init system_demo
$ cd system_demo
$ tree
.
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── README.md
├── tasks
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml

9 directories, 8 files
```

第首个演示只用到 `tasks` 和 `vars` 目录。目录结构看起来如下：


```console
$ tree
.
├── tasks
│   └── main.yml
└── vars
    └── main.yml

3 directories, 2 files
```


接下来，将原先 Ansible Playbook 中 `vars` 和 `tasks` 两个小节的内容，迁移到这个角色中。首先，将两个任务迁移到 `tasks/main.yml` 这个文件中：


```yaml
{{#include ../../network_run/system_demo/tasks/main.yml}}
```

接着，把那些变量迁移到 `vars/main.yml` 文件：


```yaml
{{#include ../../network_run/system_demo/vars/main.yml}}
```


最后，将原先的 Ansible Playbook 修改为移除 `tasks` 和 `vars` 两个小节，并添加关键字 `roles` 和这个角色的名字，在此示例中为 `system_demo`。咱们将有着下面这个 playbook：


```yaml
{{#include ../../network_run/cisco_dns_refined.yml}}
```


总的来说，这个演示现在共有三个目录及三个 YAML 文件。其中 `system_demo` 文件夹代表着该角色。`system_demo` 包含了两个文件夹，分别是 `tasks` 和 `vars`。每个文件夹都有个 `main.yml` 文件。`vars/main.yml` 包含 `playbook.yml` 中的变量。`tasks/main.yml` 包含了 `playbook.yml` 中的任务。`playbook.yml` 文件已修改为调用这个角色，而不是直接指定 `vars` 和 `tasks`。下面是当前工作目录的树形结构：

```console
$ tree
.
├── cisco_dns_refined.yml
└── system_demo
    ├── tasks
    │   └── main.yml
    └── vars
        └── main.yml
```


运行该 playbook 的结果完全相同，但输出略有不同：


```console
$ ansible-playbook -i network_run/inventory.yml network_run/cisco_dns_refined.yml -bkK
SSH password:
BECOME password[defaults to SSH password]:

PLAY [configure cisco routers] ************************************************************************************************************

TASK [system_demo : configure hostname] ***************************************************************************************************
ok: [cisco-r1]

TASK [system_demo : configure DNS] ********************************************************************************************************
[WARNING]: To ensure idempotency and correct diff the input configuration lines should be similar to how they appear if present in the
running configuration on device
changed: [cisco-r1]

PLAY RECAP ********************************************************************************************************************************
cisco-r1                   : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```


如上所见，现在每个任务冠以了该角色的名字，在本例中为 `system_demo`。当运行包含了多个角色的 playbook 时，这将有助于确定某个任务是从何处调用的。这个 playbook 返回了 `ok` 而不是 `changed`，因为其行为与我们开始时使用的单个文件 playbook 完全相同。

> **译注**：这里截取的实验输出中，`system_demo: configure DNS` 任务结果为 `changed`，可能是 `cisco.ios` 专辑，或因为在 GNS3 上运行的 Cisco 路由器虚拟机的问题造成。


与之前一样，这个 playbook 将在某台 Cisco IOSv 路由器上生成以下配置：


```console
cisco-r1#sh run | i name
hostname cisco-r1
ip domain name xfoss.com
ip name-server 223.5.5.5
ip name-server 223.6.6.6
multilink bundle-name authenticated
username hector password 7 01435F550E5A51
  username hector
```

这就是为何 Ansible 角色可以简单地看作是解构的 playbook。角色简单、有效且可重用。现在，其他用户只需包含 `system_demo` 这个角色，而不必创建一个定制 “硬编码” 的 playbook。


## 变量优先级


如果咱们要更改 DNS 服务器，该怎么办呢？不要指望修改角色结构中的 `vars/main.yml`。Ansible 有着很多咱们可以指定出特定角色变量的地方。有关变量与优先级的详细信息，请参阅 [“使用变量”](../usage/playbook/using/vars.md)。实际上有 21 个地方可以放置变量。虽然乍一看这个列表会让人不知所措，但绝大多数用例都只涉及了解最低优先级变量的位置，以及如何传递最高优先级的变量。请参见 [变量优先级： 我该把变量放在哪里？](../usage/playbook/using/vars.md#变量优先级我该把变量放在哪里)，了解咱们应将变量置于何处的更多指导。


### 最低优先级

优先级最低的是角色中的 `defaults` 目录。这意味着，无论是其他 20 个咱们可能指定变量的位置中的哪个地方，他们的优先级都高于 `defaults`。要立即将这个 `system_demo` 角色中的变量置于最低优先级，就把 `vars` 目录重命名为 `defaults`。


```console
$ mv vars defaults
$ tree
.
├── defaults
│   └── main.yml
└── tasks
    └── main.yml

3 directories, 2 files
```

在那个 playbook 中添加一个新的 `vars` 小节，以覆盖该默认行为（其中变量 `dns` 被设置为 `223.5.5.5` 和 `223.6.6.6`）。在这个演示中，要将 `dns` 设为 `8.8.8.8`，这样 `playbook.yml` 就变成了：

```yaml
{{#include ../../network_run/cisco_dns_vars.yml}}
```


在 `cisco-r1` 上运行这个更新后的 playbook：

```console
ansible-playbook -i network_run/inventory.yml network_run/cisco_dns_vars.yml -bkK
```

`cisco-r1` 这个思科路由器上的配置将看起来如下：


```console
cisco-r1#sh run | i name-server
ip name-server 8.8.8.8
```


现在，在这个 playbook 中配置的变量，就优先于 `defaults` 目录中的变量。事实上，咱们在任何其他地方配置的变量，都会优先于 `defaults` 目录中的。


### 最高优先级

在某个角色内的 `defaults` 目录中指定变量时，优先级总是最低的，而使用 `-e` 或 `--extra-vars=` 将 `vars` 指定为额外变量时，则无论是何变量，优先级总是最高的。使用 `-e` 选项重新运行这个 playbook 时，就会覆盖 `defaults` 目录（`223.5.5.5` 和 `223.6.6.6`），以及包含着 `8.8.8.8` 的 `dns` 服务器该 playbook 新创建的 `vars`。

```console
ansible-playbook -i network_run/inventory.yml network_run/cisco_dns_vars.yml -e "dns=114.114.114.114" -bkK
```

那个 Cisco IOSv 路由器上的结果，将只包含 `114.114.114.114` 的最高优先级设置：


```console
cisco-r1#sh run | i name-server
ip name-server 114.114.114.114
```


这有什么用？咱们为什么要引起注意呢？网络管理员通常会使用额外变量，来覆盖一些默认值。AWX 或 Red Hat Ansible 自动化平台上的作业模板调查功能，就是个很好的例子。通过 web 用户界面，提示网络管理员使用 web 表单填写一些参数是可行的。这对于非技术的 playbook 编写者来说，使用 Web 浏览器执行 playbook 就非常简单。


## 更新某个已安装角色

某个角色的 Ansible Galaxy 页面，列出了其所有可用版本。要将某个本地安装的角色，更新到某个新版本或另一版本，可将 `ansible-galaxy install` 命令与版本号及 `--force` 选项一起使用。咱们可能还需要手动更新任何依赖项角色，以支持该版本。有关依赖项角色的最低版本要求，请参阅 Galaxy 中的 **Read Me** Tab 页。

```console
$ ansible-galaxy install mynamespace.my_role,v2.7.1 --force
```


（End）


