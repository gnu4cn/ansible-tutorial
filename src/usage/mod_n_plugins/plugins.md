# 使用插件


所谓插件，是一些增强 Ansible 核心功能的代码片段。Ansible 使用了插件架构，实现丰富、灵活和可扩展的功能集。


Ansible 本身就有许多方便的插件，而咱们也可轻松编写咱们自己的插件。

本节介绍了 Ansible 所包含的各种类型插件。


## 动作插件

**Action plugins**


动作插件与模组一起行事，执行 playbook 任务所需的动作。他们通常在后台自动执行，于模组执行前完成前置工作。

`'normal'` 这个动作插件，会被用于那些尚无动作插件的模组。如有必要，咱们可以 [创建定制动作插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-actions)。


### 启用动作插件

通过将定制动作插件丢在与咱们的 play 相邻的 `action_plugins` 目录中，或将其放入 `ansible.cfg` 中配置的一个动作插件目录源中，赞及就可以启用该动作插件。


### 使用动作插件

默认当某个关联模组被用到时，动作插件就会被执行；而无需额外操作。


### 插件列表

咱们无法直接列出动作插件，他们会显示为对应的模组：

请使用 `ansible-doc -l` 命令查看可用模组的列表。使用 `ansible-doc <name>` 查看特定于插件的文档与示例。若该模组有个相应的动作插件，这应注明。


## 成为插件


这些成为插件的作用是，在运行一些与目标系统协同的基本命令，及执行 play 中所指定任务所需的一些模组时，Ansible 可以使用某些权限提升系统。


这些实用程序（`sudo`、`su`、`doas` 等），通常可以让咱们 “成为” 另一用户，以该用户的权限执行某个命令。


### 启用成为插件


随 Ansible 提供的那些 `become` 插件，均已被启用。通过把自定义插件，放在与 play 相邻的 `become_plugins` 目录中，或某个角色内，或放在 [`ansible.cfg`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 中配置的 `become` 插件目录来源中，就可以添加他们。


### 使用成为插件

除了 [“Ansible 配置设置”](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 中的默认配置设置，或 `--become-method` 命令行选项外，咱们还可以使用 play 中的 `become_method` 关键字，或者在咱们需要 “特定于主机” 时，也可使用连接变量 `ansible_become_method`，选择要使用的插件。

咱们还可以插件本身中详细说明的其他配置选项，进一步控制每个插件的设置。


### 插件清单


咱们可使用 `ansible-doc -t become -l` 命令，查看可用的插件列表。使用 `ansible-doc -t become <plugin name>` 命令，查看特定插件的文档及示例。


## 缓存插件


缓存插件允许 Ansible 存储收集到的事实或仓库源数据，而消除从数据源检索的影响性能。

默认缓存插件是只会缓存 Ansible 当前执行数据的内存插件。其他带有持久存储的插件，可用于允许跨运行数据的缓存。这些缓存插件有的会写入文件，而其他的会写入数据库。

对于仓库与事实，咱们可使用不同的缓存插件。若咱们在未设置某种特定于仓库的缓存插件下，启用了仓库缓存，Ansible 就会对事实和仓库，同时使用事实缓存插件。如有必要，咱们可 [创建定制的缓存插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-cache-plugins)。


### 启用事实缓存插件

事实缓存始终是启用的。不过，同一时间只能有一种事实缓存插件，处于活动状态。咱们既可在 Ansible 配置文件中，选择用于事实缓存的缓存插件，也可以一个环境变量选择：

```console
export ANSIBLE_CACHE_PLUGIN=jsonfile
```

或在 `ansible.cfg` 文件中：


```ini
[defaults]
fact_caching=redis
```

若缓存插件是在某个专辑种，就要使用完全限定名字：


```ini
[defaults]
fact_caching = namespace.collection_name.cache_plugin_name
```

要启用某个定制缓存插件，就要将其保存在 `ansible.cfg` 中配置的目录来源之一，或某个专辑中，然后通过完全限定专辑名字， FQCN，引用他。

咱们还需配置特定于各个插件的其他设置项。详情请查阅各个插件的文档，或 [Ansible 配置](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings)。


### 启用仓库缓存插件

仓库缓存默认是关闭的。要缓存仓库数据，咱们必须启用仓库缓存，然后选择咱们要使用的特定缓存插件。并非所有仓库插件都支持缓存，因此要检视咱们打算使用的仓库插件文档。咱们可以一个环境变量，启用仓库缓存：


```console
export ANSIBLE_INVENTORY_CACHE=True
```

或者在 `ansible.cfg` 文件中：


```ini
[inventory]
cache=True
```

或在仓库插件接受 YAML 的配置来源时，在其配置文件中：


```yaml
# dev.aws_ec2.yaml
plugin: aws_ec2
cache: True
```

同一时间只能有一种仓库缓存插件是活动的。咱们可以一个环境变量设置他：


```console
export ANSIBLE_INVENTORY_CACHE_PLUGIN=jsonfile
```

或在 `ansible.cfg` 文件中：

```ini
[inventory]
cache_plugin=jsonfile
```

要使用咱们插件路径中的某个定制插件缓存仓库，请依照 [缓存插件的开发人员指南](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-cache-plugins)。

要使用某专辑中的某个缓存插件缓存仓库，请使用完全限定专辑名字：


```ini
[inventory]
cache_plugin=collection_namespace.collection_name.cache_plugin
```


若咱们在没有选取某个特定于仓库的缓存插件下，启用了仓库缓存，那么 Ansible 会退回到使用咱们配置的事实缓存插件，缓存仓库。详情请查阅单个仓库插件文档，或 [Ansible 配置](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings)。


### 使用缓存插件

一旦缓存插件被启用，他们会自动被用到。


### 插件列表

咱们可使用 `ansible-doc -t cache -l` 命令查看可用插件的列表。使用 `ansible-doc -t cache <plugin name>` 查看特定插件的文档与示例。


## 回调插件

回调插件令到在响应事件时，添加新行为到 Ansible 可行。默认情况下，回调插件控制了运行命令行程序时，咱们所看到的大部分输出，但也可用于添加额外输出、与其他工具集成以及将事件汇聚到某种存储后端。如有必要，你可 [创建定制的回调插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-callbacks)。


### 示例回调插件


[`log_plays`](https://docs.ansible.com/ansible/2.9/plugins/callback/log_plays.html#log-plays-callback) 回调是如何将 playbook 事件记录到某个日志文件的示例，而 [`mail`](https://docs.ansible.com/ansible/2.9/plugins/callback/mail.html#mail-callback) 回调则会在 playbook 失败时发送电子邮件。

[`say`](https://docs.ansible.com/ansible/2.9/plugins/callback/say.html#say-callback) 回调会以一段与 playbook 事件有关的计算机合成语音响应之。


### 启用回调插件


通过将某个定制回调放入 `ansible.cfg` 中配置的回调目录来源之一，或某个专辑中并以 FQCN 在配置中引用他，然后根据其 `NEEDS_ENABLED` 属性，激活该回调。

这些插件会按字母数字顺序加载。例如，在名为 `1_first.py` 文件中实现的某个插件，将在名为 `2_second.py` 的插件文件之前运行。

随 Ansible 提供的大多数回调，默认都是关闭的，需要在咱们的 `ansible.cfg` 文件中启用后才能发挥作用。例如：


```ini
#callbacks_enabled = timer, mail, profile_roles, collection_namespace.collection_name.custom_callback
```

### 给 `ansible-playbook` 设置某个回调插件

咱们只能有一个插件，作为咱们控制台输出的主管理器插件。若咱们打算替换默认的控制台输出主管理器插件，应在子类中定义 `CALLBACK_TYPE = stdout`，然后在 `ansible.cfg` 中配置 `stdout` 插件。例如：


```ini
stdout_callback = dense
```

或者使用咱们的定制回调：

```ini
stdout_callback = mycallback
```

默认这只会影响 `ansible-playbook` 命令。


### 给 ad hoc 命令设置某个插件


`ansible` 临时命令特别为 `stdout` 使用了别的回调插件，因此在 [“Ansible 配置设置”](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 中有个咱们需要添加的额外设置，来使用上面定义的 `stdout` 回调：


```ini
[defaults]
bin_ansible_callback = True
```

咱们也可以一个环境变量，设置这个插件：


```console
export ANSIBLE_LOAD_CALLBACK_PLUGIN=1
```


### 回调插件的类型

有以下三种类型的回调插件：

- `stdout` 的回调插件：这些插件处理主控制台输出。只能有一个是活动的。他们总是会首先获取到事件；其余回调会按配置顺序获取到事件；
- 聚合回调插件，aggregate callback plugins：聚合回调可将一些额外控制台输出，添加到某个 `stdout` 回调后面。这可以是 playbook 运行结束时的一些聚合信息、每个任务的额外输出或其他任何内容；
- 通知回调插件，notification callback plugins：通知回调会通知其他应用程序、服务或系统。这包括日志记录到数据库、在即时信息应用中的通知错误，或在服务器不可达时发送电子邮件等。


### 插件列表

咱们可使用 `ansible-doc -t callback -l` 命令查看可用插件的列表。使用 `ansible-doc -t callback <plugin name>` 命令查看特定插件的文档与示例。


## `cliconf` 插件

`cliconf` 插件是到各种网络设备的 CLI 接口抽象。他们为 Ansible 在这些网络设备上执行任务，提供了标准接口。

这些插件通常与网络设备平台一一对应。Ansible 会根据 `ansible_network_os` 这个变量，自动加载相应的 `cliconf` 插件。


### 添加 `cliconf` 插件

通过将某个定制插件，放入 `cliconf_plugins` 目录，咱们便可将 Ansible 扩展为支持其他网络设备。


### 使用 `cliconf` 插件

要用到的 `cliconf` 插件是由 `ansible_network_os` 变量自动决定的。没有理由改写这一功能。

大多数 `cliconf` 插件都无需配置即可运行。少数 `cliconf` 插件有一些可被设置以对将任务转化为 CLI 命令方式，施加影响的额外选项。

这些 `cliconf` 插件都是自带文档的。各个插件都应记录了其配置选项。


### 查看 `cliconf` 插件

这些插件均已迁移到 [Ansible Galaxy](https://galaxy.ansible.com/) 上一些专辑。如果咱们使用 `pip` 安装了 Ansible 2.10 或更高版本，就可以访问到多个 `cliconf` 插件。咱们可使用 `ansible-doc -t cliconf -l` 查看可用插件的列表。使用 `ansible-doc -t cliconf <plugin name>` 查看特定插件的文档与示例。


## 连接插件


连接插件允许 Ansible 连接到目标主机，从而他可在目标主机上执行任务。Ansible 随附了许多连接插件，但同一时间每台主机只能使用一种。

默认情况下，Ansible 附带多个连接插件。最常用到的是 [`paramiko` SSH](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/paramiko_ssh_connection.html#paramiko-connection)、原生 ssh（只称为 [`ssh`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html#ssh-connection)）与 [`local`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/local_connection.html#local-connection) 三种连接类型。所有这些插件都可用于 playbook 中和 `/usr/bin/ansible`，以决定咱们打算与远端机器对话的方式。如有必要，咱们还可 [创建定制连接插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-connection-plugins)。要更改咱们任务的连接插件，可使用 `connection` 关键字。


这些连接类型的基础知识，在 [入门](https://docs.ansible.com/ansible/2.9/user_guide/intro_getting_started.html#intro-getting-started) 小节中有讲到。


### `ssh` 插件

由于 SSH 是系统管理中用到的默认协议，也是 Ansible 中使用最多的协议，因此 SSH 的那些选项，就被包含在了命令行工具中。详情请参阅 [`ansible-playbook`](../cli/ansible-playbook.md)。


### 使用连接插件


咱们可以通过 [ Ansible 配置](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 全局地设置连接插件、通过命令行（`-c`、`--connection`）设置、通过咱们 play 中的 [关键字](https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html#playbook-keywords) 设置，或设置一个通常在咱们仓库中的 [变量](../inventories_building.md#连接主机行为清单参数)。例如，对于 Windows 机器，咱们可能需要将 `winrm` 插件设置为一个仓库变量。

大多数连接插件都只需最少配置即可运行。默认情况下，他们使用 [仓库主机名](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/inventory_hostnames_lookup.html#inventory-hostnames-lookup) 与默认设置，查找目标主机。

这些插件都自带文档。各个插件都应记录其配置选项。以下是大多数连接插件通用的及各连接变量：


- `ansible_host`：在不同于 [仓库](../inventories_building.md#如何建立仓库) 主机时，要连接的主机名；
- `ansible_port`：ssh 的端口号，对于 [`ssh`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html#ssh-connection) 与 [`paramikoo_ssh`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/paramiko_ssh_connection.html#paramiko-connection) 其默认为 `22`；
- `ansible_user`：用于登录的默认用户名。大多数连接插件都默认为 “运行 Ansible 的当前用户”。


各个插件还可能有覆盖某个变量通用版本的指定版本。例如，[`ssh`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html#ssh-connection) 插件的 `ansible_ssh_host` 变量。


### 插件列表

咱们可使用 `ansible-doc -t connection -l` 命令查看可用插件的列表。使用 `ansible-doc -t connection <plugin name>` 命令查看特定插件的文档与示例。


## 文档片段

**Docs fragments**


文档片段允许咱们在一处，记录多个插件或模组的常用参数。


### 启用文档片段

与添加其他插件一样，咱们可将某个自定义文档片段，放入与专辑或角色相邻的 `doc_fragments` 目录中。


### 使用文档片段

只有专辑开发者与维护者，才会用到文档片段。有关使用文档片段的更多信息，请参阅 [文档片段](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_documenting.html#module-docs-fragments) 或 [在专辑中使用文档片段](https://docs.ansible.com/ansible/latest/dev_guide/developing_collections_shared.html#docfragments-collections)。
