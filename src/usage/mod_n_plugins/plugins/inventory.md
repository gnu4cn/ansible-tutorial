# 仓库插件


仓库插件允许用户使用 `-i /path/to/file` 和/或 `-i 'host1, host2'` 这样的命令行参数或其他配置来源，指向数据源以编译出 Ansible 用于目标任务的主机仓库。如有必要，咱们可 [创建定制仓库插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-inventory-plugins)。


## 启用仓库插件


大多数随 Ansible 提供的仓库插件，都默认是启用的，或者可与 `auto` 插件一起使用。

在某些情况下，例如该仓库插件未使用 YAML 的配置文件时，咱们可能需要启用该特定插件。通过在咱们的 `ansible.cfg` 文件中，`[inventory]` 小节设置 `enable_plugins`，完成该仓库插件的启用。修改此设置将覆盖已启用插件的默认列表。以下是 Ansible 随附的已启用仓库插件的默认列表：

```ini
[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml
```

如果插件位于某个专辑中，且未被 `auto` 语句选中，则咱们可追加其全限定名称：


```ini
[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml, namespace.collection_name.inventory_plugin_name
```

或者，如果他是个本地插件，可能存储在由 [`DEFAULT_INVENTORY_PLUGIN_PATH` 配置设置](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-inventory-plugin-path) 所设置的路径中，则咱们可以如下方式引用他：


```ini
[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml, my_plugin
```

若咱们使用了某个支持 YAML 的配置源插件，则要确保其名字，与仓库来源文件的 `plugin` 条目中，所提供的名字相符。对于其他插件，咱们必须将其保存到 `ansible.cfg` 中配置的目录来源之一并启用他，或者将其添加到某个专辑中，然后通过 FQCN 引用。


## 使用仓库插件

要使用某个仓库插件，咱们必须提供某个仓库来源。大多数情况下，这会是个包含着主机信息的文件，或者是个带有该插件选项的 YAML 的配置文件。咱们可以使用 `-i` 命令行开关提供仓库来源，或配置某个默认的仓库路径。


```console
ansible hostname -i inventory_source -m ansible.builtin.ping
```

要开始使用某种带有 YAML 的配置来源的仓库插件，就要创建一个文件名符合该插件文档中所描述文件名模式的文件，然后添加 `plugin：plugin_name`。若该插件是在某个专辑中，则要使用完全限定的名字。


```yaml
# demo.aws_ec2.yml
plugin: amazon.aws.aws_ec2
```

> **注意**：仓库插件都有他们必须符合的要求名字模式，比如：
>
> 某个包含了 `kubevirt.core.kubevirt` 仓库插件的仓库，就必须使用 `*.kubevirt.yml` 这种文件名模式。而某个包含了 `servicenow.servicenow.now` 仓库插件的仓库，就必须使用 `*.servicenow.yml` 这种文件名模式。


每个插件都应记录下全部的命名约束。此外，YAML 的配置文件，必须以扩展名 `.yml` 或 `.yaml` 结尾，以默认由 `auto` 插件启用（否则，就要参阅上面有关 [启用插件](#启用仓库插件) 小节）。


在提供了所需的全部选项后，咱们就可使用 `ansible-inventory -i demo.aws_ec2.yml --graph`命令，查看产生出的仓库：


```console
@all:
  |--@aws_ec2:
  |  |--ec2-12-345-678-901.compute-1.amazonaws.com
  |  |--ec2-98-765-432-10.compute-1.amazonaws.com
  |--@ungrouped:
```


若咱们使用了某个在与 playbook 相邻专辑中的仓库插件，并打算以 `ansible-inventory` 测试咱们的设置，就要使用 `--playbook-dir` 这个命令行开关。


咱们的仓库来源，可能是个仓库配置文件的目录。而构造型仓库插件，只会对已在清单中的主机运行，因此咱们就可能希望在某个特定时刻（比如最后时刻），这种构造型仓库配置才得以解析。Ansible 会按字母顺序，递归解析该目录。咱们无法配置这种解析方式，因此就要以使其可预测地运作方式，命名咱们的文件。一些直接扩展了构造特性的仓库插件，通过在仓库插件选项之外添加一些构造选项方式，可以绕过这种限制。如若不行，咱们则使用带有多个来源的 `-i` 命令行选项，指明某种特定顺序，例如 `-i demo.aws_ec2.yml -i clouds.yml -i constructed.yml`。

通过构建的 `keyed_groups` 选项，咱们可使用一些主机变量，创建出动态组。选项 `groups` 同样可用于创建组，而选项 `compose` 则会创建及修改一些主机变量。下面是利用了一些构建特性的一个 `aws_ec2` 示例：

```yaml
# demo.aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
  - us-east-2
keyed_groups:
  # add hosts to tag_Name_value groups for each aws_ec2 host's tags.Name variable
  - key: tags.Name
    prefix: tag_Name_
    separator: ""
  # If you have a tag called "Role" which has the value "Webserver", this will add the group
  # role_Webserver and add any hosts that have that tag assigned to it.
  - key: tags.Role
    prefix: role
groups:
  # add hosts to the group development if any of the dictionary's keys or values is the word 'devel'
  development: "'devel' in (tags|list)"
  # add hosts to the "private_only" group if the host doesn't have a public IP associated to it
  private_only: "public_ip_address is not defined"
compose:
  # use a private address where a public one isn't assigned
  ansible_host: public_ip_address|default(private_ip_address)
  # alternatively, set the ansible_host variable to connect with the private IP address without changing the hostname
  # ansible_host: private_ip_address
  # if you *must* set a string here (perhaps to identify the inventory source if you have multiple
  # accounts you want to use as sources), you need to wrap this in two sets of quotes, either ' then "
  # or " then '
  some_inventory_wide_string: '"Yes, you need both types of quotes here"'
```

现在 `ansible-inventory -i demo.aws_ec2.yml --graph` 命令的输出为：


```console
@all:
  |--@aws_ec2:
  |  |--ec2-12-345-678-901.compute-1.amazonaws.com
  |  |--ec2-98-765-432-10.compute-1.amazonaws.com
  |  |--...
  |--@development:
  |  |--ec2-12-345-678-901.compute-1.amazonaws.com
  |  |--ec2-98-765-432-10.compute-1.amazonaws.com
  |--@role_Webserver
  |  |--ec2-12-345-678-901.compute-1.amazonaws.com
  |--@tag_Name_ECS_Instance:
  |  |--ec2-98-765-432-10.compute-1.amazonaws.com
  |--@tag_Name_Test_Server:
  |  |--ec2-12-345-678-901.compute-1.amazonaws.com
  |--@ungrouped
```

如果某个主机没有上述配置中的那些变量（也就是，没有 `tags.Name`、`tags`、`private_ip_address`），则该主机就不会被添加到该仓库插件创建的组之外的组中，`ansible_host` 这个主机变量也不会被修改。


支持缓存的那些仓库插件，可使用定义在 `ansible.cfg` 文件 `[defaults]` 小节中事实缓存的通用设置，或者在 `[inventory]` 小节中定义的特定于仓库的设置。单个插件也可在其配置文件中，定义特定于插件的缓存设置：


```yaml
# demo.aws_ec2.yml
plugin: amazon.aws.aws_ec2
cache: true
cache_plugin: ansible.builtin.jsonfile
cache_timeout: 7200
cache_connection: /tmp/aws_inventory
cache_prefix: aws_ec2
```

下面是在 `ansible.cfg` 文件中，以事实缓存所使用的缓存插件及超时的一些默认值，设置仓库缓存的示例：


```ini
[defaults]
fact_caching = ansible.builtin.jsonfile
fact_caching_connection = /tmp/ansible_facts
cache_timeout = 3600

[inventory]
cache = yes
cache_connection = /tmp/ansible_inventory
```

## 插件清单


咱们可使用 `ansible-doc -t inventory -l` 命令查看可用插件的列表。使用 `ansible-doc -t inventory <plugin name>` 命令查看特定插件的文档与示例。

（End）


