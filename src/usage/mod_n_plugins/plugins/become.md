# 成为插件


这些成为插件的作用是，在运行一些与目标系统协同的基本命令，及执行 play 中所指定任务所需的一些模组时，Ansible 可以使用某些权限提升系统。


这些实用程序（`sudo`、`su`、`doas` 等），通常可以让咱们 “成为” 另一用户，以该用户的权限执行某个命令。


## 启用成为插件


随 Ansible 提供的那些 `become` 插件，均已被启用。通过把自定义插件，放在与 play 相邻的 `become_plugins` 目录中，或某个角色内，或放在 [`ansible.cfg`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 中配置的 `become` 插件目录来源中，就可以添加他们。


## 使用成为插件

除了 [“Ansible 配置设置”](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 中的默认配置设置，或 `--become-method` 命令行选项外，咱们还可以使用 play 中的 `become_method` 关键字，或者在咱们需要 “特定于主机” 时，也可使用连接变量 `ansible_become_method`，选择要使用的插件。

咱们还可以插件本身中详细说明的其他配置选项，进一步控制每个插件的设置。


## 插件清单


咱们可使用 `ansible-doc -t become -l` 命令，查看可用的插件列表。使用 `ansible-doc -t become <plugin name>` 命令，查看特定插件的文档及示例。

（End）

