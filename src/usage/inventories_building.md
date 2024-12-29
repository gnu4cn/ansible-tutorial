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


## 添加主机范围

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
> 1 2 3 4 5 6 7 8 9 10
> 而非包含性的（exclusive） 的从 1 到 10：
> 1 2 3 4 5 6 7 8 9
>
> 参考：[What is the meaning of "exclusive" and "inclusive" when describing number ranges?](https://stackoverflow.com/q/39010041)
