# 模式：选择主机及组别

当咱们通过临时命令，an ad hoc command，或运行 playbook 执行 Ansible 时，必须选择要面向哪些托管节点或组执行命令。模式可让咱们指向仓库中的特定主机，和/或组运行命令及 playbook。某种模式可以指一台主机、一个 IP 地址、一个仓库组、一个组的集合，或仓库中的全部主机。模式非常灵活，咱们可以使用通配符或正则表达式等，排除或要求主机子集。Ansible 会在该模式中所包含的所有仓库主机上执行。


## 使用模式

在执行临时命令或 playbook 的过程中，咱们几乎每次都会用到模式。模式是 [临时命令](cli.md) 中，唯一没有命令行开关的元素。他通常是命令的第二个元素：

```console
ansible <pattern> -m <module_name> -a "<module options>"
```

比如：

```console
ansible webservers -m service -a "name=httpd state=restarted"
```

在 playbook 中，模式是每次 play 的 `hosts:` 行内容：

```yaml
- name: <play_name>
  hosts: webservers
```

由于咱们经常要同时针对多台主机，运行命令或 playbook，因此模式通常会指向仓库组别。上面的临时命令和 playbook，都将针对 `webservers` 组中的所有机器执行。


## 常见模式

下面这个表格，列出了指向仓库主机和组别的一些常见模式。


| 描述 | 模式 | 目标 |
| :-- | :-- | :-- |
| 全体主机 | `all`（或 `*`） |  |
| 一台主机 | `host1` |  |
| 多台主机 | `host1:host2`（或 `host1,host2`） |  |
| 一个组别 | `webservers` |  |
| 多个组别 | `webservers:dbservers` | `webservers` 组种的全体主机加上 `dbservers` 组中的全体主机 |
| 排除某些组别 | `webservers:!atlanta` | 除了位处 Atlanta 的 `webservers` 全体主机 |
| 两个组别的交集 | `webservers:&staging` | 同时在 `webservers` 与 `staging` 组中的全部主机 |

> **注意**：咱们可使用逗号（`,`）或冒号（`:`），来分隔主机列表。在遇到范围和 IPv6 地址时，最好使用逗号。

一旦掌握了这些基本模式，咱们就可以将他们组合起来。比如下面这个例子：

```yaml
webservers:dbservers:&staging:!phoenix
```

就会指向那些，`webservers` 和 `dbservers` 组下，同时也在 `staging` 组中的所有机器，但 `phoenix` 组中的任何机器除外。

只要主机在仓库中以 FQDN 或 IP 地址命名了，咱们就可以使用 FQDN 或 IP 地址的通配符模式：

```yaml
192.0.*
*.example.com
*.com
```

咱们可同时混用通配符模式和组：

```yaml
one*.com:dbservers
```


## 模式的局限

模式取决于仓库。如果主机或组未在仓库中列出，那么就无法使用模式将其作为目标。如果模式中包含的 IP 地址或主机名，未出现在仓库中，则会出现如下错误：

```console
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: Could not match supplied host pattern, ignoring: *.not_in_inventory.com
```

咱们的模式，必须与仓库语法相匹配。如果咱们将某台主机定义为了某个 [别名](inventories_building.md#仓库别名)：

```yaml
atlanta:
  hosts:
    host1:
      http_port: 80
      maxRequestsPerChild: 808
      ansible_host: 127.0.0.2
```

那么咱们必须在模式中使用别名。在上例中，咱们必须在模式中使用 `host1`。如果咱们使用了 IP 地址，则会再次出现错误：

```console
[WARNING]: Could not match supplied host pattern, ignoring: 127.0.0.2
```


## 模式的处理顺序

处理过程有点特殊，会按以下顺序进行：

1. `:` 与 `,`；

2. `&`

3. `!`

这种定位，只考虑每个操作内部的处理顺序：`a:b:&c:!d:!e == &c:a:!d:b:!e == !d:a:!e:&c:b`

所有这些操作，会得出以下结果：

主机在/是（`a` 或 `b`）**且，AND** 主机在/是全部（`c`），**且，AND** 主机不在/是全部（`d`，`e`）。


## 高级模式选项


上述常见模式，可以满足咱们的大部分需求，但 Ansible 还提供了其他几种方法，来定义主机和组。


### 在模式种使用变量

使用传递给 `ansible-playbook` 命令的 `-e` 参数，咱们可以使用变量，来启用组别标识符的传递：


```yaml
webservers:!{{ excluded }}:&{{ required }}
```

### 在模式中使用组别位置


咱们可以在组别中，按照主机位置来定义出某台主机或某个主机子集。例如，给定以下组别：


```ini
[webservers]
cobweb
webbing
weber
```

咱们就可以使用下标，在 `webservers` 组中选择单台主机或范围。

### 切分特定项目

- 操作：`s[i]`；

- 结果：`s` 的 `i-th` 项目，其中索引原点为 `0`。

如果 `i` 为负数，那么会被相对于序列 `s` 末尾：`len(s) + i` 处的索引。但 `-0` 是为 `0`。


```ini
webservers[0]       # == cobweb
webservers[-1]      # == weber
```

### 从起点与终点切片

- 操作: `s[i:j]`；

- 结果: `s` 中从索引 `i` 至 `j` 处的切片

`s` 从 `i` 到 `j` 的切片的定义为，索引为 `k` 且 `i <= k <= j` 的项目序列。如果省略 `i`，则使用 `0`。如果省略 `j`，则使用 `len(s)`。省略 `i` 和 `j` 的切片，会导致无效的主机模式。如果 `i` 大于 `j`，则切片为空。如果 `i` 等于 `j`，则被替换为 `s[i]`。


```ini
webservers[0:2]     # == webservers[0],webservers[1],webservers[2]
                    # == cobweb,webbing,weber
webservers[1:2]     # == webservers[1],webservers[2]
                    # == webbing,weber
webservers[1:]      # == webbing,weber
webservers[:3]      # == cobweb,webbing,weber
```


### 在模式中使用正则表达式


咱们可以用 `~` 开头的正则表达式，指定出某种模式：


```ini
~(web|db).*\.example\.com
```

## 模式与临时命令

咱们可以使用命令行选项，改变定义在临时命令中模式的行为。咱们还可以使用 `--limit` 命令行开关，限制某次特定运行中，咱们所针对的主机。


- 限制为单台主机；

```console
ansible all -m <module> -a "<module options>" --limit "host1"
```

- 限制为多台主机；

```console
ansible all -m <module> -a "<module options>" --limit "host1,host2"
```

- 否定限制，negated limit。请注意 **必须** 使用单引号，以阻止 bash 的（字符串）插值运算；

```console
ansible all -m <module> -a "<module options>" --limit 'all:!host1'
```

- 限制为主机组别。

```console
ansible all -m <module> -a "<module options>" --limit 'group1'
```


## 模式与 `ansible-playbook` 命令行开关

咱们可以使用命令行选项，改变定义在 playbook 中模式的行为。例如，通过指定 `-i 127.0.0.2,`（请注意尾部的逗号），咱们可以在单台主机上，运行某个定义了 `hosts: all` 的 playbook。即使目标主机未在仓库中定义，这种方法也起作用，不过这种方法将 **不会** 读取仓库中，与该主机绑定的变量，因此需要在命令行手动指定出，该 playbook 所需的任何变量。咱们也可以使用 `--limit` 命令行开关，限制某次特定运行中的目标主机，其将参考咱们的仓库：

```console
ansible-playbook site.yaml --limit datacenter2
```

最后，咱们可以使用 `--limit`，从某个文件中读取主机列表，方法是在文件名前加上 `@`：


```console
ansible-playbook site.yaml --limit @retry_hosts.txt
```

如果 [`RETRY_FILES_ENABLED`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#retry-files-enabled) 设置为了 `True`，那么在 `ansible-playbook` 运行后，将创建出一个 `.retry` 文件，其中包含所有 play 中，失败主机的列表。每次 `ansible-playbook` 运行结束后，该文件都会被覆盖。


```console
ansible-playbook site.yaml --limit @site.retry
```

要将这些模式知识应用于 Ansible 命令与 playbook，请阅读 [临时命令](cli.md) 和 [Ansible playbooks](playbooks.md)。
