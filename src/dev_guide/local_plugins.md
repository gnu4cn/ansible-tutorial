# 在本地添加模组与插件


咱们可通过添加一些定制模组或插件，扩展 Ansible。咱们可从头开始创建模组或插件，也可复制现有模组或插件供本地使用。咱们可在咱们的 Ansible 控制节点上存储本地模组或插件，并与咱们的团队或组织共享。咱们还可以将插件和模组包含在一个专辑中，然后在 Ansible Galaxy 上发布该专辑，从而共享插件和模组。


若咱们正使用某个本地模组或插件，但 Ansible 却无法找到他，那么这个页面就是咱们所需的全部内容。


如果咱们打算创建一个插件或模组，请参阅 [开发插件](mod_dev.md)、[开发模组](plugin_dev.md) 及 [开发专辑](collection_dev.md)。


以本地模组和插件扩展 Ansible，提供了以下捷径：

- 咱们可以拷贝他人的模组和插件；
- 在编写某个新模组时，咱们可选择任何编程语言；
- 咱们不必克隆任何代码仓库；
- 咱们不必开启拉取请求；
- 咱们不必添加测试（尽管我们建议添加！）。


## 模组与插件：二者有何区别？


如果咱们正想为 Ansible 添加功能，咱们就可能想知道咱们是需要一个模组，还是插件。下面是个快速概述，帮助咱们了解自己需要什么：

- [插件](../usage/mod_n_plugins/plugins.md) 扩展了 Ansible 的核心功能。大多数插件类型，都在控制节点上 `/usr/bin/ansible` 进程中执行。插件为 Ansible 的核心功能，提供了选项和扩展：转换数据、记录输出、连接仓库等等；
- 模组是一类在 “目标”（通常为某个远端系统）上，执行自动化任务的插件。模组以独立脚本的形式运作，由 Ansible 在控制节点之外，他们自己的进程中执行。模组与 Ansible 的接口主要是 JSON 形式，他们接受参数并在退出前，通过向 `stdout` 打印 JSON 字符串返回信息。与其他插件（他们必须用 Python 编写）不同，模组可以任何语言编写；不过 Ansible 只提供了 Python 和 Powershell 语言的模组。


## 在专辑中添加模组与插件


咱们可以通过 [创建专辑](collection_dev.md)，添加模组和插件。在某个专辑下，咱们就可以在任何 playbook 或角色中，使用定制模组与插件。咱们可随时通过 Ansible Galaxy，轻松共享咱们的专辑。


本页其余部分介绍了使用本地、独立模组或插件的其他方法。


## 在专辑外添加模组或插件

咱们将 Ansible 配置为加载某个特定位置中的独立的本地模组或插件，并令到他们对所有 playbook 和角色可用（使用配置的路径）。或者，咱们可以将某个非专辑的本地模组或插件，构造为只对某些 playbook 或角色可用（使用相邻路径）。


### 为所有 playbook 和角色添加独立本地模组


要自动加载独立的本地模组，并让所有 playbook 和角色都能使用他们，就要使用 [`DEFAULT_MODULE_PATH`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-module-path) 配置设置，或 `ANSIBLE_LIBRARY` 这个环境变量。与 `$PATH` 类似，该配置设置和环境变量取一个以冒号分隔的列表。咱们有两种选项：


- 将独立咱们的本地模组添加到默认配置的位置之一。详情请参阅 [`DEFAULT_MODULE_PATH`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-module-path) 配置设置。这些默认位置可能会在没有通知下就变动；
+ **将咱们的独立本地模组位置，添加到某个环境变量或配置中**：
    - `ANSIBLE_LIBRARY` 这个环境变量；
    - `DEFAULT_MODULE_PATH` 这个配置设置。


查看咱们当前模组的配置设置：

```console
$ ansible-config dump | grep DEFAULT_MODULE_PATH
DEFAULT_MODULE_PATH(default) = ['/home/hector/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
```

将咱们把咱们的模组文件，保存到这些位置之一中后，Ansible 就会加载他，咱们就可以在任何本地任务、playbook 或角色中使用他。


要确认 `my_local_module` 是否可用：

- 输入 `ansible localhost -m my_local_module`，查看该模组的输出，或；
- 输入 `ansible-doc -t module my_local_module`，查看该模组的文档。


> **注意**：这适用于所有插件类型，但每种插件类型均需特定配置和/或目录相邻，请参见下文。

> **注意**：`ansible-doc` 命令可以解析用 Python 或某个相邻 YAML 文件编写的模组文档。如果模组是以 Python 以外的编程语言编写的，咱们则应将文档编写在该模组文件旁边的 Python 或 YAML 文件中。关于 [相邻的 YAML 文档文件](https://docs.ansible.com/ansible/latest/dev_guide/sidecar.html#adjacent-yaml-doc)


### 为选定的 playbook 或单个角色添加独立本地模组


Ansible 会自动将咱们 playbook 或角色相邻的一些目录中的所有可执行文件，作为模组加载。这些位置中的独立模组，只对父级目录中的特定 playbook、playbooks 或角色可用。


- 要只在选定的一个或多个 playbook 中使用某个独立模组，可将该模组存储在包含了一或多个 playbook 的目录下的名为 `library` 的子目录下；
- 要在某单个角色中使用某个独立模组，可将该模组存储在该角色中的一个名为 `library` 的子目录中。


{{#include ./local_plugins.md:73}}

> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> 包含在专辑中的角色，不能包含任何模组或其他插件。专辑中的所有插件，都必须位于该专辑的 `plugins` 目录树中。该目录树中的所有插件，都可以被该专辑中的所有角色访问。如果咱们正在开发新模组，我们建议将他们发布在 [专辑](collection_dev.md) 不是角色中。


## 在专辑外的本地添加非模组插件


咱们可将 Ansible 配置为加载某个指定位置或某些指定位置中的独立本地插件，并将这些插件构造为对所有 playbook 和角色可用。或者，咱们也可以让某个独立本地插件，只对特定 playbook 或角色可用。

> **注意**：虽然模组也属于插件，但适用于其他插件类型的目录名和环境变量命名模式，并不适用于模组。请参阅 [在专辑外添加模组或插件](#在专辑外添加模组或插件)。


### 为全部 playbook 和角色添加本地非模组插件


要自动加载独立的本地插件，并使其对所有 playbook 和角色可用，就要使用咱们要添加插件类型的配置设置或环境变量。与 `$PATH` 类似，这些配置设置和环境变量，均会取一个冒号分隔的列表。咱们有两种选项：


- 将咱们的本地插件添加到默认配置的位置之一。有关插件类型的正确配置设置详细信息，请参阅 [配置设置](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings)。这些默认位置可能会在没有通知下更改；
+ **将咱们本地插件的位置，添加到某个环境变量或配置中**：
    - 相关的 `ANSIBLE_plugin_type_PLUGINS` 环境变量 - 比如 `$ANSIBLE_INVENTORY_PLUGINS` 或 `$ANSIBLE_VARS_PLUGINS`；
    - 相关的 `plugin_type_PATH` 配置设置，其中多数以 `DEFAULT_` 开头，例如 `DEFAULT_CALLBACK_PLUGIN_PATH` 或 `DEFAULT_FILTER_PLUGIN_PATH` 或 `BECOME_PLUGIN_PATH` 等。


要查看当前的非模组插件配置设置：

```console
$ ansible-config dump | grep DEFAULT_CALLBACK_PLUGIN_PATH
DEFAULT_CALLBACK_PLUGIN_PATH(default) = ['/home/hector/.ansible/plugins/callback', '/usr/share/ansible/plugins/callback']
$ ansible-config dump | grep DEFAULT_FILTER_PLUGIN_PATH
DEFAULT_FILTER_PLUGIN_PATH(default) = ['/home/hector/.ansible/plugins/filter', '/usr/share/ansible/plugins/filter']
$ ansible-config dump | grep BECOME_PLUGIN_PATH
BECOME_PLUGIN_PATH(default) = ['/home/hector/.ansible/plugins/become', '/usr/share/ansible/plugins/become']
...

```


在咱们的插件插件文件添加到这些位置之一后，Ansible 就会加载他，咱们就可以在任何本地模组、任务、playbook 或角色中使用他。有关环境变量和配置设置的更多信息，请参阅 [Ansible 配置设置](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings)。


要确认 `plugins/plugin_type/my_local_plugin` 可用：


- 输入 `ansible-doc -t <plugin_type> my_local_lookup_plugin` 命令，查看该插件的文档，例如：`ansible-doc -t lookup my_local_lookup_plugin`。


`ansible-doc` 命令适用于大多数插件类型，但不适用于 `action`、`filter` 或 `test` 插件。详见 [`ansible-doc`](../usage/cli/ansible-doc.md)。


### 为选定 playbook 或单个角色添加独立本地插件

Ansible 会自动从与咱们 playbook 或角色相邻的某些目录中，加载所有插件，并从以插件类型命名的目录中，单独加载各种类型的插件。这些位置中的独立插件，只对父级目录中的特定 playbook、playbooks 或角色有效。


- 要仅在选定的一个或多个 playbook 中使用某个独立插件，就要将该插件存储在包含这些 playbook 目录中，对应的 `plugin_type`（例如，`callback_plugins` 或 `inventory_plugins`）子目录中。这些目录必须使用 `_plugins` 后缀。有关插件类型的完整列表，请参阅 [使用插件](../usage/mod_n_plugins/plugins.md)；
- 要在某单个角色中使用某个独立插件，就要将该插件存储在该角色中，对应的 `plugin_type`（如 `cache_plugins` 或 `strategy_plugins`）子目录中。当插件作为某个角色一部分发布时，那么在该角色执行后，这个插件便立即可用。这些目录必须使用 `_plugins` 后缀。有关插件类型的完整列表，请参阅 [使用插件](../usage/mod_n_plugins/plugins.md)。


> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> 包含在专辑中的角色，不能包含任何插件。专辑中的所有插件，必须位于该专辑的 `plugins` 目录树中。该目录树中的所有插件，都可以被这个专辑中的所有角色访问。如果咱们正在开发新插件，我们建议咱们将其发布在专辑而不是角色中。


> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> 有些插件类型在 Ansible 执行早期阶段就需要，比如 `callback`、`inventory` 及 `cache` 等。这些插件类型无法被动态加载，而必须存在于配置的路径中，或由 FQCN 在配置中引用。


## 使用 `ansible.legacy` 访问某个 `ansible.builtin` 模组的定制版本


若咱们需要覆盖某个 `ansible.builtin` 模组且要使用 FQCN，咱们就需要使用 `ansible.legacy`，作为完全限定专辑名字（FQCN）的一部分。例如，若咱们有着咱们自己的 `copy` 模组，就可以用 `ansible.legacy.copy` 访问他。请参阅 [使用 `ansible.legacy` 访问基于专辑角色中的本地定制模组](https://docs.ansible.com/ansible/latest/dev_guide/migrating_roles.html#using-ansible-legacy)，了解如何通过角色，使用某个专辑中的定制模组。

（End）


