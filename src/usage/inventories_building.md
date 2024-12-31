# 建立 Ansible 仓库

> **注意**：
>
> **让开源更具包容性，Making Open Source More Inclusive**
>
> 红帽致力于找到和替换掉代码、文档和网络属性中有问题的语言。我们将从以下四个术语开始：`master`、`slave`、`blacklist` 和 `whitelist`。如果发现我们遗漏的术语，请提交问题或拉取请求。更多详情，请参阅 [首席技术官 Chris Wright 的致辞](https://www.redhat.com/en/blog/making-open-source-more-inclusive-eradicating-problematic-language)。

欢迎阅读建立 Ansible 仓库指南。仓库是 Ansible 要部署与配置的托管节点或主机的列表。本指南将向咱们介绍仓库，并涵盖以下主题：

- 创建出跟踪咱们打算实现自动化的服务器和设备仓库；

- 使用动态仓库，来跟踪那些有着会不断启动和停止的服务器与设备的云服务；

- 使用模式来自动处理仓库的某个特定子集；

- 扩展及改进 Ansible 用于仓库的连接方法。


## 如何建立仓库

Ansible 使用名为仓库的列表或组别，使基础设施中托管节点或 “主机” 上的任务自动化。咱们可在命令行中传递主机名，但大多数 Ansible 用户都会创建仓库文件。仓库定义了咱们要自动化的托管节点，并带有组别，这样咱们就可以同时在多个主机上，运行自动化任务。一旦定义了仓库，咱们就可以使用 [模式](patterns.md)，来选择 Ansible 要运行的主机或组别。

最简单的仓库，是个具有主机及组别列表的文件。该文件的默认位置，是 `/etc/ansible/hosts`。咱们可在命令行中，使用 `-i <path>` 选项，或在配置中使用 `inventory`，指定出别的仓库文件。

Ansible 的 [Inventory 插件](../plugins/inventory.md) 支持多种格式和来源，从而使咱们的清单灵活且可定制。随着清单的扩展，咱们可能需要更多文件来组织咱们的主机和组别。以下是 `/etc/ansible/hosts` 文件之外的三种选择：

- 咱们可以创建一个包含多个仓库文件的目录。请参阅 [在目录中组织仓库](#在目录中组织仓库)。这些文件可以使用不同格式（`YAML`、`ini` 等）；

- 咱们可以动态拉取仓库。例如，咱们可以使用动态仓库插件，列出一或多个云提供商中的资源。请参阅 [使用动态仓库](#使用动态仓库)；

- 咱们可以使用多个仓库源，包括动态仓库与静态文件。请参阅 [传递多个仓库源](#传递多个仓库源)。

> **注意**：以下 YAML 代码段包含的省略号，表示他们是更大 YAML 文件的一部分。有关 YAML 语法的更多信息，在 [YAML 基础知识](../YAML_syntax.md#YAML-基础) 处可以找到。

## 仓库基础知识：格式、主机与组别

咱们可根据所使用的仓库插件，以多种格式创建仓库文件。最常见的格式是 INI 和 YAML。一个基本 INI 格式的 `/etc/ansible/hosts` 文件，可能如下所示：


```ini
mail.example.com

[webservers]
foo.example.com
bar.example.com

[dbservers]
one.example.com
two.example.com
three.example.com
```

方括号（`[]`）中的标题属于组别名字，用于对主机进行分类，并确定出在什么时间出于什么目的，控制什么样的主机。组别名应遵循与 [创建有效变量名](../playbooks/using_vars.md) 同样的准则。

下面是 YAML 格式的同一基本仓库文件：


```yaml
ungrouped:
  hosts:
    mail.example.com:
webservers:
  hosts:
    foo.example.com:
    bar.example.com:
dbservers:
  hosts:
    one.example.com:
    two.example.com:
    three.example.com:
```

### 默认组别

即使咱们没在仓库文件中定义任何组别，Ansible 也会创建两个默认组别：`all` 和 `ungrouped`。`all` 组别包含了所有主机。`ungrouped` 组别包含除在 `all` 组别中外，再无其他组别的所有主机。每个主机总是属于至少两个组（`all` 和 `ungrouped` 或 `all` 及其他组别）。例如，在上面的基本仓库中，主机 `mail.example.com` 属于 `all` 组和 `ungrouped` 组；主机 `two.example.com` 属于 `all` 组和 `dbservers` 组。虽然 `all` 和 `ungrouped` 始终存在，但他们可以是隐式的，不会像 `group_names` 一样出现在组别列表中。


### 位处多个组别中的主机


咱们可把各台主机，放在多个组别中。例如，位于亚特兰大数据中心的生产 web 服务器，就可能会被归入名为 `[prod]` 和 `[atlanta]` 以及 `[webservers]` 的组别中。咱们可创建出跟踪以下内容的组别：


- 为何，What - 某个应用程序、堆栈或微服务（如数据库服务器、web 服务器等）；

- 何处，Where - 某个数据中心或区域（如东部、西部），要与本地 DNS、存储等进行对话；

- 何时，When - 比如开发阶段，以避免在生产资源上进行测试（如 `prod`、`test`）。


扩展之前的 YAML 仓库，使其包括内容、时间和地点，就会变成这样：

```yaml
ungrouped:
  hosts:
    mail.example.com:
webservers:
  hosts:
    foo.example.com:
    bar.example.com:
dbservers:
  hosts:
    one.example.com:
    two.example.com:
    three.example.com:
east:
  hosts:
    foo.example.com:
    one.example.com:
    two.example.com:
west:
  hosts:
    bar.example.com:
    three.example.com:
prod:
  hosts:
    foo.example.com:
    one.example.com:
    two.example.com:
test:
  hosts:
    bar.example.com:
    three.example.com:
```

咱们可以看到，`one.example.com` 就存在于 `dbservers`、`east` 和 `prod` 组中。

### 对组别进行分组：父/子的组别关系

咱们可在组别与组别之间，创建出父/子关系。父组别也称为嵌套组，或组别的组。例如，如果所有生产主机，都已在 `atlanta_prod` 和 `denver_prod` 等组别中，则可以创建一个其中包括这些较小组别的 `production` 组别。这种方法可以减少维护工作，因为咱们可通过编辑子组别，添加或移除父组别中的主机。


要创建组别的父/子关系：

- 在 INI 格式下，要使用 `:children` 后缀；

- 在 YAML 格式下，要使用 `children:` 条目。


下面是与以上所示的相同仓库，但以父组别，简化了 `prod` 和 `test` 两个组别。这两个仓库文件给到同样的结果：


```yaml
ungrouped:
  hosts:
    mail.example.com:
webservers:
  hosts:
    foo.example.com:
    bar.example.com:
dbservers:
  hosts:
    one.example.com:
    two.example.com:
    three.example.com:
east:
  hosts:
    foo.example.com:
    one.example.com:
    two.example.com:
west:
  hosts:
    bar.example.com:
    three.example.com:
prod:
  children:
    east:
test:
  children:
    west:
```

子组别有几个要注意的属性：

- 作为子组别成员的任何主机，都自动成为父组别的成员；

- 组别可以有多个父和子组别，但不能有循环关系；

- 主机同样可位于多个组别中，但在运行时一个主机只会有 **一个** 实例。Ansible 会合并多个组别的数据。


### 添加主机范围

**Adding ranges of hosts**


如果咱们有很多具有相似模式的主机，就可以将他们作为一个范围添加，而不是单独列出每个主机名：

在 INI 格式下：

```ini
[webservers]
www[01:50].example.com
```

在 YAML 下：


```yaml
# ...
  webservers:
    hosts:
      www[01:50].example.com:
```

在定义主机的数字范围时，咱们可指定跨距（序列数字之间的增量）：


在 INI 格式下：

```ini
[webservers]
www[01:50:2].example.com
```

在 YAML 下：


```yaml
# ...
  webservers:
    hosts:
      www[01:50:2].example.com:
```

上面的示例会匹配子域名 `www01`、`www03`、`www05`、...、`www49`，但不会匹配 `www00`、`www02`、`www50`，因为每步的跨距（增量）是 2 个单位。

对于数字模式，可以根据需要包含或移除前导的零。范围是包含性的，ranges are inclusive<sup>1</sup>。咱们还可以定义字母范围：

```yaml
# ...
  database:
    db-[a:f].example.com:
```

> **译注**：这里说范围是包含性的，比如包含性的从 1 到 10：
>
> 1 2 3 4 5 6 7 8 9 10
>
> 而非包含性的（exclusive） 的从 1 到 10：
>
> 1 2 3 4 5 6 7 8 9
>
> 参考：[What is the meaning of "exclusive" and "inclusive" when describing number ranges?](https://stackoverflow.com/q/39010041)


## 传递多个仓库源

通过在命令行中提供多个仓库参数，或配置 `ANSIBLE_INVENTORY`，咱们可同时指向多个仓库源（目录、仓库插件所支持的动态仓库脚本或文件）。当咱们打算针对不同环境，如暂存，staging与生产环境，执行某项特定操作时，这将非常有用。

从命令行指向两个仓库源：


```console
ansible-playbook get_logs.yml -i staging -i production
```

## 将仓库组织在目录中

咱们可将多个仓库源，合并到一个目录中。最简单的做法，便是在目录中包含多个，而不是一个仓库文件。单个文件变得太长，就会难以维护。如果咱们有多个团队，以及多个自动化项目，那么每个团队或项目拥有一个仓库文件，就能让每个人都轻松找到，与自己相关的主机和组别。

咱们还可以在仓库目录中，组合多种仓库源类型。这对于合并静态和动态主机，并将其作为一个仓库进行管理非常有用。下面的仓库目录，结合了一个仓库插件的源、一个动态仓库脚本，以及一个包含静态主机的文件：


```console
inventory/
  openstack.yml          # 配置了从 OpenStack 云服务获取主机的仓库插件
  dynamic-inventory.py   # 使用动态仓库脚本添加额外主机
  on-prem                # 添加静态主机与组别
  parent-groups          # 添加静态主机与组别
```

咱们可以像下面这样，指向该仓库目录：


```console
ansible-playbook example.yaml -i inventory
```

咱们也可在 `ansible.cfg` 文件中，配置仓库目录。更多详情，请参阅 [配置 Ansible](../configuring.md)。


### 管理仓库加载顺序

Ansible 会根据文件名的 ASCII 顺序，加载仓库源。如果在某个文件或目录中定义了父组别，在其他文件或目录中定义了子组别，则必须先加载定义子组别的文件。如果先加载父组别，则会出现错误 `Unable to parse /path/to/source_of_parent_groups as an inventory source`。

例如，如果有个名为 `groups-of-groups` 的文件，定义了个 `production` 组，其子组定义在名为 `on-prem` 的文件中，那么 Ansible 就无法解析出 `production` 组。为避免这个问题，可以通过往文件名添加前缀，来控制加载顺序：

```console
inventory/
  01-openstack.yml          # 配置从 OpenStack 云服务上获取主机的仓库插件
  02-dynamic-inventory.py   # 以动态仓库脚本，添加额外主机
  03-on-prem                # 添加静态主机与组别
  04-groups-of-groups       # 添加父组别
```

在 [“仓库设置示例”](#仓库设置示例) 中，咱们可以找到如何组织仓库，及对主机进行分组的示例。


## 将变量添加到仓库

在仓库中，咱们存储与特定主机或组别相关的变量值。首先，咱们可以在主仓库文件中，直接向主机和组添加变量。

为简单起见，我们就在主仓库文件中添加变量。不过，在单独的主机和组变量文件中存储变量，是描述系统策略的一种更稳健方法。在主仓库文件中设置变量，只是一时之便。有关在 `“host_vars”` 目录下的单个文件中存储变量值的指南，请参阅 [组织主机和组变量](#组织主机和组变量)。有关详情，请参阅 [组织主机和组变量](#组织主机和组变量)。


## 将变量分配给一台机器：主机变量

咱们可轻松地将变量分配给单台主机，并随后在 playbook 中使用他。咱们可直接在仓库文件中完成。

在 INI 格式下：

```ini
[atlanta]
host1 http_port=80 maxRequestsPerChild=808
host2 http_port=303 maxRequestsPerChild=909
```

在 YAML 下：

```yaml
atlanta:
  hosts:
    host1:
      http_port: 80
      maxRequestsPerChild: 808
    host2:
      http_port: 303
      maxRequestsPerChild: 909
```

像非标准 SSH 端口这样的唯一值，亦可作为主机变量。咱们可在主机名后使用冒号添加端口号，将其添加到 Ansible 清单中：

```ini
badwolf.example.com:5309
```

连接变量也可以作为主机变量使用：

```ini
[targets]

localhost              ansible_connection=local
other1.example.com     ansible_connection=ssh        ansible_user=myuser
other2.example.com     ansible_connection=ssh        ansible_user=myotheruser
```


> **注意**：如果在 SSH 配置文件中列出了非标准 SSH 端口，那么 `openssh` 连接会找到并使用他们，但 [`paramiko`](https://www.paramiko.org/) 连接则不会。


### 仓库别名

使用主机变量，咱们还可以在仓库中定义别名：


在 INI 格式下：


```ini
jumper ansible_port=5555 ansible_host=192.0.2.50
```

在 YAML 下：


```yaml
# ...
  hosts:
    jumper:
      ansible_port: 5555
      ansible_host: 192.0.2.50
```

在本例中，针对主机别名 “jumper” 运行 Ansible，将连接到 `192.0.2.50` 上的 `5555` 端口。请参阅 [行为仓库参数](#连接到主机：行为仓库参数)，进一步定制到主机的连接。


## 以 INI 格式定义变量

使用 `key=value` 语法以 INI 格式传递的值，会根据其声明位置的不同，而被各异地解析：

- 在主机行内声明时，INI 值会被解析为 Python 字面结构（字符串、数字、元组、列表、字典、布尔值与 `None` 等）。主机行接受每行多个 `key=value` 参数。因此，他们需要某种表示空格是值一部分，而不是分隔符的方法。包含空格的值，可以使用引号（单引号或双引号）。详见 [Python `shlex` 解析规则](https://docs.python.org/3/library/shlex.html#parsing-rules)；

- 在 `:vars` 小节中声明时，INI 值就被解析为字符串。例如，`var=FALSE` 将创建一个等于 `“FALSE”` 的字符串。与主机行不同，`:vars` 小节每行只接受一个条目，因此 `=` 后面的所有内容，都必须是该条目的值。


如果在 INI 仓库中设置的变量值，必须是某种类型（例如字符串或布尔值），就要在任务中使用过滤器指定出类型。在使用变量时，不要依赖 INI 仓库中设置的类型。


请考虑对仓库源使用 YAML 格式，以避免变量实际类型的混淆。YAML 仓库插件，能一致、正确地处理变量值。


## 将一个变量分配给多台机器：组变量

如果组中的所有主机共享某个变量值，则可将该变量一次性应用于整个组。


在 INI 格式下：

```ini
[atlanta]
host1
host2

[atlanta:vars]
ntp_server=ntp.atlanta.example.com
proxy=proxy.atlanta.example.com
```

在 YAML 下：


```yaml
atlanta:
  hosts:
    host1:
    host2:
  vars:
    ntp_server: ntp.atlanta.example.com
    proxy: proxy.atlanta.example.com
```

组变量是将变量同时应用于多台主机的便捷方法。不过，在执行之前，Ansible 总是会将变量（包括仓库变量）扁平化到主机级别。如果某台主机是多个组的成员，Ansible 会从所有这些组中，读取变量值。如果在不同组中为同一变量分配了不同值，Ansible 会根据内部 [合并规则](#合并变量规则)，选择使用哪个值。

### 继承变量值：组别组的组变量

**Inheriting variable values: group variables for groups of groups**


咱们可将变量应用于父组别（嵌套组或组别组，nested groups or groups of groups），以及子组别。语法相同：INI 格式为 `:vars`，YAML 格式为 `vars:`：

在 INI 格式下：

```ini
[atlanta]
host1
host2

[raleigh]
host2
host3

[southeast:children]
atlanta
raleigh

[southeast:vars]
some_server=foo.southeast.example.com
halon_system_timeout=30
self_destruct_countdown=60
escape_pods=2

[usa:children]
southeast
northeast
southwest
northwest
```

YAML 下：


```yaml
usa:
  children:
    southeast:
      children:
        atlanta:
          hosts:
            host1:
            host2:
        raleigh:
          hosts:
            host2:
            host3:
      vars:
        some_server: foo.southeast.example.com
        halon_system_timeout: 30
        self_destruct_countdown: 60
        escape_pods: 2
    northeast:
    northwest:
    southwest:
```

子组别变量的优先级高于（会覆盖）父组变量。


## 组织主机和组变量

虽然咱们可在主仓库文件中存储变量，但存储单独主机及组变量文件，可以帮助咱们更轻松地组织咱们的变量值。咱们还可以在主机及组变量文件中，使用列表和哈希数据，这在主仓库文件中是做不到的。

主机及组变量文件，必须使用 YAML 语法。有效的文件扩展名包括 `.yml`、`.yaml`、`.json` 或无文件扩展名。如果咱们对 YAML 不熟悉，请参阅 [YAML 语法](../refs/YAML_syntax.md)。

Ansible 通过检索相对于仓库文件或 playbook 文件的路径，来加载主机与组变量文件。如果 `/etc/ansible/hosts` 目录处的仓库文件中，包含了一台名为 `“foosball”` 的主机，其属于 `“raleigh”` 和 `“webservers”` 两个组，那么该主机将使用位于以下位置处 YAML 文件中的变量：


```console
/etc/ansible/group_vars/raleigh # 可以选择以 ".yml"、".yaml" 或 ".json" 结尾
/etc/ansible/group_vars/webservers
/etc/ansible/host_vars/foosball
```


例如，如果咱们按数据中心对仓库中的主机进行分组，而每个数据中心都使用自己的 NTP 服务器和数据库服务器，那么咱们可以创建一个名为 `/etc/ansible/group_vars/raleigh` 的文件，来存储 `raleigh` 组的变量：

```yaml
---
ntp_server: acme.example.org
database_server: storage.example.org
```

咱们还可以创建以组或主机命名的 *目录* 。Ansible 会按词典顺序，读取这些目录中的所有文件。以 `raleigh` 组为例：

```console
/etc/ansible/group_vars/raleigh/db_settings
/etc/ansible/group_vars/raleigh/cluster_settings
```

`raleigh` 组中的所有主机，都可以使用这些文件中定义的变量。当单个文件过大，或想在某些组变量上使用 [Ansible Vault](../vault.md) 时，这对保持变量组织有序非常有用。


对于 `ansible-playbook`，咱们也可以在咱们的  playbook 目录，添加 `group_vars/` 和 `host_vars/` 目录。其他 Ansible 命令（例如，`ansible`、`ansible-console` 等）只会在该目录中，查找 `group_vars/` 和 `host_vars/`。如果想让其他命令从某个 playbook 目录，加载组变量和主机变量，咱们必须在命令行中提供 `--playbook-dir` 选项。如果咱们要同时从 playbook 目录和仓库目录加载仓库文件，则 playbook 目录中的变量，将优先于仓库目录中的变量。

将仓库文件和变量，保存在某个 Git 源代码仓库（或其他版本控制系统）中，是跟踪仓库与主机变量变更的绝佳方式。


## 变量合并方式

默认情况下，变量会在某次运行前，合并/扁平化到特定主机。这样可以让 Ansible 专注于主机与任务，因此组别不会存活于仓库和主机匹配之外。默认情况下，Ansible 会覆盖变量，包括为组和/或主机定义的变量（参见 [`DEFAULT_HASH_BEHAVIOUR`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-hash-behaviour)）。顺序/优先级为（从低到高）：

- 组 `all`（因为他是所有其他组别的 “父” 组）

- 父组

- 子组

- 主机

默认情况下，Ansible 会按 ASCII 顺序，合并同一父/子级别的组，最后加载组中的变量，会覆盖前面组中的变量。例如，`a_group` 将被 `b_group` 合并，`b_group` 中匹配的变量将覆盖 `a_group` 中的变量。

> **注意**：Ansible 会合并不同来源的变量，并根据一系列规则，将某些变量优先于其他变量。例如，出现在仓库中较高位置的变量，可以优先于出现在清单中较低位置的变量。更多信息，请参阅 [变量优先级：我应该把变量放在哪里？](../playbooks/using_vars.md)

咱们可通过设置组变量 `ansible_group_priority`，改变同级别组的合并顺序（在父/子顺序确定之后）。数字越大，合并时间越晚，优先级越高。如果未设置该变量，则其默认值为 `1`。例如：

```yaml
a_group:
  vars:
    testvar: a
    ansible_group_priority: 10
b_group:
  vars:
    testvar: b
```

在本例中，如果两个组的优先级相同，结果通常会是 `testvar == b`，但由于我们赋予了 `a_group` 更高的优先级，结果将是 `testvar == a`。


> **注意**：`ansible_group_priority` 只能在仓库源中设置，而不能在 `group_vars/` 中设置，因为该变量用于 `group_vars` 的加载。


### 管理仓库变量加载顺序


在使用多个仓库源时，请记住任何变量冲突，都是根据[变量合并方式](#变量合并方式) 及 [变量优先级：我应该把变量放在哪里？](../playbooks/using_vars.md) 中，所述的规则来解决。咱们可以控制仓库源中变量的合并顺序，以获得咱们所需的变量值。

当咱们在命令行传递多个仓库源时，Ansible 会按照传递参数的顺序合并变量。如果 `staging` 仓库中的 `[all:vars]` 定义了 `myvar = 1`，而 `production` 仓库定义了 `myvar = 2`，那么：


- 传入 `-i staging -i production` 就会以 `myvar=2` 运行该 playbook；

- 传入 `-i production -i staging` 就会以 `myvar=1` 运行该 playbook。


当咱们将多个仓库源放入一个目录中时，Ansible 会根据文件名按 ASCII 顺序合并他们。咱们可以通过给文件添加前缀，来控制加载顺序：

```console
inventory/
  01-openstack.yml          # 配置仓库插件来获取 OpenStack 云服务上的主机
  02-dynamic-inventory.py   # 使用动态仓库插件添加额外主机
  03-static-inventory       # 添加静态主机
  group_vars/
    all.yml                 # 指派变量给全部主机
```

如果 `01-openstack.yml` 为组 `all` 定义了 `myvar = 1`，`02-dynamic-inventory.py` 定义了 `myvar = 2`，`03-static-inventory` 定义了 `myvar = 3`，那么将以 `myvar = 3` 运行 playbook。


有关仓库插件与动态仓库脚本的更多详情，请参阅 [清单插件](../plugins/inventory.md) 和 [使用动态仓库](dynamic_inventory.md)。


## 连接主机：行为清单参数

**Connecting to hosts: bevavioral inventory parameters**


如上所述，设置以下变量，可控制 Ansible 与远端主机的交互方式。


主机连接参数：

> **注意**：在使用 SSH 连接插件时（默认情况），Ansible 没有提供允许用户与 `ssh` 进程通信，以便手动接受密码，解密 `ssh` 密钥的通道。强烈建议使用 `ssh-agent`。


- `ansible_connection`
与主机的连接类型。这可以是任何 Ansible 连接插件的名称。SSH 协议类型为 `ssh` 或 `paramiko`。默认为 `ssh`。



适用于全部连接方式的参数：

- `ansible_host`
- `ansible_port`
- `ansible_user`
- `ansible_password`



专用于 SSH 连接的参数：

- `ansible_ssh_private_key_file`
- `ansible_ssh_common_args`
- `ansible_sftp_extra_args`
- `ansible_scp_extra_args`
- `ansible_ssh_extra_args`
- `ansible_ssh_pipelining`
- `ansible_ssh_executable` （在 v2.2 中加入）



权限提升（详见 [Ansible 权限提升](../playbooks/privilege_escalation.md)）参数：

- `ansible_become`
- `ansible_become_method`
- `ansible_become_user`
- `ansible_become_password`
- `ansible_become_flags`

远端主机环境参数：

- `ansible_shell_type`
- `ansible_python_interperter`
- `ansible_*_interpreter`
- `ansible_shell_executable`

### 非 SSH 连接类型

如上一节所述，Ansible 可通过 SSH 执行 playbook，但并不局限于这种连接类型。使用特定于主机的参数 `ansible_connection=<connector>`，可以更改连接类型。有关可用插件和示例的完整列表，请参阅 [插件列表](../plugins/connection.md)。

## 仓库设置示例

另请参阅 [Ansible 设置示例](tips_tricks/sample_setup.md)，该示例显示了仓库、playbook 及其他 Ansible 部件。


### 示例：每种环境一个仓库

如果需要管理多种环境，有时谨慎的做法是，每个仓库只定义单个环境的主机。这样，当咱们打算更新某些 “暂存” 服务器时，就更不会意外地改变 “测试” 环境中节点的状态。

在上面提到的示例中，咱们可以有个 `inventory_test` 文件：


```ini
[dbservers]
db01.test.example.com
db02.test.example.com

[appservers]
app01.test.example.com
app02.test.example.com
app03.test.example.com
```

该文件只包括属于 “测试” 环境的主机。而在另一个名为 `inventory_staging` 的文件中定义 “暂存” 机器：


```ini
[dbservers]
db01.staging.example.com
db02.staging.example.com

[appservers]
app01.staging.example.com
app02.staging.example.com
app03.staging.example.com
```

要将名为 `site.yml` 的 playbook，应用到测试环境中的所有应用程序服务器，请使用以下命令：

```console
ansible-playbook -i inventory_test -l appservers site.yml
```

### 示例：按功能分组

在上一小节，我们已经举例说明了，如何使用组别来将具有相同功能的主机编为集群。例如，下面这样就可以在 playbook 或角色中，定义出仅影响那些数据库服务器的防火墙规则：

```yaml
- hosts: dbservers
  tasks:
  - name: Allow access from 10.0.0.1
    ansible.builtin.iptables:
      chain: INPUT
      jump: ACCEPT
      source: 10.0.0.1
```


### 示例：按地理位置分组


其他任务可能侧重于某个主机的位置。假设 `db01.test.example.com` 和 `app01.test.example.com` 位于 `DC1`，而 `db02.test.example.com` 位于 `DC2`：


```ini
[dc1]
db01.test.example.com
app01.test.example.com

[dc2]
db02.test.example.com
```

在实践中，咱们甚至可能最终混合使用所有这些设置，因为咱们可能需要，在某一天更新特定数据中心的所有节点，而在另一天则需要更新所有应用服务器（无论其位于何处）。
