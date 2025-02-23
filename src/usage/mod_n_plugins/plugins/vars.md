# `vars` 插件

`vars` 会将并非来自仓库源、playbook 或命令行的一些额外变量，注入到历次 Ansible 运行。像 `host_vars` 与 `group_vars` 这样的 playbook 结构，会用到 `vars` 插件。有关 Ansible 中变量的更多详情，请参阅 [使用变量](../../playbook/using/vars.md)。

`vars` 插件是在 Ansible 2.0 中部分实现的，从 Ansible 2.4 开始就被重写为完全实现。

随 Ansible 提供的 `host_group_vars` 插件，实现了读取 [分配给一台机器的变量：主机变量](../../inventories_building.md#将变量分配给一台机器主机变量) 以及 [分配给多台机器的变量：组变量](../../inventories_building.md#将一个变量分配给多台机器组变量)。

## 启用 `vars` 插件

通过将某个定制 `vars` 插件放入与咱们 play 相邻的 `vars_plugins` 目录中，放在某个角色内，或者将其放入 `ansible.cfg` 中配置的某个目录来源中，咱们就可以激活该 `vars` 插件。要让某个 `vars` 插件在仓库构建过程中运行，咱们就不能在 play 或角色中启用他，因为 play 或角色中的插件要到稍后才会加载。而如果他们仅仅是要在任务执行时运行，则对他们于何处被提供没有限制。


大多数 `vars` 插件默认均被禁用了。要启用某个 `vars` 插件，就要在 `ansible.cfg` 的 `defaults` 小节中设置 `vars_plugins_enabled`，或将 `ANSIBLE_VARS_ENABLED` 这个环境变量，设置为咱们要执行的 `vars` 插件列表。默认情况下，随 Ansible 提供的 `host_group_vars` 这个插件已被启用。

从 Ansible 2.10 开始，咱们便可在专辑中使用 `vars` 插件。专辑中的所有 `vars` 插件都必须显式启用，且必须使用格式为 `namespace.collection_name.vars_plugin_name` 这种完全限定专辑名称。


```ini
[defaults]
vars_plugins_enabled = host_group_vars,namespace.collection_name.vars_plugin_name
```


## 使用 `vars` 插件


默认情况下，`vars` 插件在启用后自动按需使用。

从 Ansible 2.10 开始，`vars` 插件可被构造为在特定时刻运行。`ansible-inventory` 未使用这些设置，而是会始终加载 `vars` 插件。


全局设置 `RUN_VARS_PLUGINS`，可在 `ansible.cfg` 中于 `defaults` 小节使用 `run_vars_plugins` 设置，或使用 `ANSIBLE_RUN_VARS_PLUGINS` 这个环境变量来设置。默认选项 `demand`，会在任务需要变量时，运行任何相对于仓库源的已启用 `vars` 插件。相反，咱们可使用 `start` 选项，在导入该仓库源后，才运行任何相对于该仓库源的已启用 `vars` 插件。

对于那些支持 `stage` 选项的 `vars` 插件，咱们还可根据单个插件上，控制 `vars` 插件的执行。比如要在导入仓库后，运行 `host_group_vars` 这个插件，咱们可将以下内容添加到 `ansible.cfg`：


```ini
[vars_host_group_vars]
stage = inventory
```


## 插件列表

咱们可使用 `ansible-doc -t vars -l` 命令查看可用 `vars` 插件的列表。使用 `ansible-doc -t vars <plugin name>` 命令查看特定插件的文档与示例。


（End）


