# 动作插件

**Action plugins**


动作插件与模组一起行事，执行 playbook 任务所需的动作。他们通常在后台自动执行，于模组执行前完成前置工作。

`'normal'` 这个动作插件，会被用于那些尚无动作插件的模组。如有必要，咱们可以 [创建定制动作插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-actions)。


## 启用动作插件

通过将定制动作插件丢在与咱们的 play 相邻的 `action_plugins` 目录中，或将其放入 `ansible.cfg` 中配置的一个动作插件目录源中，赞及就可以启用该动作插件。


## 使用动作插件

默认当某个关联模组被用到时，动作插件就会被执行；而无需额外操作。


## 插件列表

咱们无法直接列出动作插件，他们会显示为对应的模组：

请使用 `ansible-doc -l` 命令查看可用模组的列表。使用 `ansible-doc <name>` 查看特定于插件的文档与示例。若该模组有个相应的动作插件，这应注明。

（End）

