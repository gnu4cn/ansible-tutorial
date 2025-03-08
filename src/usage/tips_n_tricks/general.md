# 通用技巧

以下这些概念适用于所有 Ansible 活动与工件，these concepts apply to all Ansible activities and artifacts。


## 保持简单

只要有可能，都要简单行事。

只有在必要时，才使用那些高级功能，并选择最符合咱们用例的特性。例如，咱们可能不需要同时使用 `vars`、`vars_files`、`vars_prompt` 及 `--extra-vars`，同时还要使用外部仓库文件。


如果咱们觉得有的东西复杂了，那么他很可能就是复杂了。要花时间找到更简单的解决方案。


## 要使用版本控制

在 `git` 或其他版本控制系统中，保管咱们的 playbook、角色、仓库及变量文件，并在进行更改时向代码仓库发起带有意义注释的提交。版本控制系统可为咱们提供审计跟踪，说明咱们何时以及为何修改了自动化咱们基础架构的规则。


## 定制 CLI 的输出

咱们可使用 [回调插件](../mod_n_plugins/plugins/callback.md)，修改 Ansible CLI 命令的输出。


## 避免依赖配置的内容

**Avoid configuration-dependent content**


要确保咱们的自动化项目易于理解、修改和与他人共享，就应避免使用依赖于配置的内容。例如，与其引用某个 `ansible.cfg` 作为项目的根目录，咱们可使用诸如 `playbook_dir` 或 `role_name` 等魔法变量，确定出与咱们项目目录中已知位置相对的路径。这样做有助于保持自动化内容的灵活性、可重用性及易维护。更多信息，请参阅 [特殊变量](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html#special-variables)。




（End）

