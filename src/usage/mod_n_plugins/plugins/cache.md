# 缓存插件


缓存插件允许 Ansible 存储收集到的事实或仓库源数据，而消除从数据源检索的影响性能。

默认缓存插件是只会缓存 Ansible 当前执行数据的内存插件。其他带有持久存储的插件，可用于允许跨运行数据的缓存。这些缓存插件有的会写入文件，而其他的会写入数据库。

对于仓库与事实，咱们可使用不同的缓存插件。若咱们在未设置某种特定于仓库的缓存插件下，启用了仓库缓存，Ansible 就会对事实和仓库，同时使用事实缓存插件。如有必要，咱们可 [创建定制的缓存插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-cache-plugins)。


## 启用事实缓存插件

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


## 启用仓库缓存插件

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


## 使用缓存插件

一旦缓存插件被启用，他们会自动被用到。


## 插件列表

咱们可使用 `ansible-doc -t cache -l` 命令查看可用插件的列表。使用 `ansible-doc -t cache <plugin name>` 查看特定插件的文档与示例。

（End）

