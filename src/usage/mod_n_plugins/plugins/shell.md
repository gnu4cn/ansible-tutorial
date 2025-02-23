# `shell` 插件


`shell` 插件的作用，是确保 Ansible 运行的一些基本命令有被恰当格式化，能在目标计算机上运行，并允许用户配置与 Ansible 执行任务方式相关的某些行为。

## 启用 `shell` 插件

通过把某个定制 `shell` 插件放如与咱们 play 相邻的 `shell_plugins` 目录中，或者放在 `ansible.cfg` 中配置的 `shell` 插件目录来源之一中，咱们即可添加该 `shell` 插件。


> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> - 除非默认的 `/bin/sh` 并非 POSIX 兼容的 shell，或其无法执行，否则咱们不应更改所使用的插件。

## 使用 `shell` 插件

除了 [“Ansible 配置设置”](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 中的默认配置设置外，咱们还可使用连接变量 [`ansible_shell_type`](../../inventories_building.md#ansible_shell_type) ，选择要使用的插件。在这种情况下，咱们还需要更新 [`ansible_shell_executable`](../../inventories_building.md#ansible_shell_executable) 以匹配。

使用插件本身详细说明的其他配置选项，咱们还可进一步控制各个插件的设置。


## 插件列表

咱们可使用 `ansible-doc -t shell -l` 命令查看可用插件的列表。使用 `ansible-doc -t shell <命令>` 查看特定插件的文档与示例。

（End）


