# 仓库技巧

下面这些技巧有助于让咱们的仓库井井有条。

## 对云主机使用动态仓库

对于维护咱们基础设施规范列表的云服务提供商及其他系统，要使用 [动态仓库](../dynamic_inventory.md) 检索这些列表，而不是手动更新静态仓库文件。对于云资源，咱们可以使用标签，区分生产环境和暂存环境，use tags to differentiate production and stagging environments。


## 按功能对仓库分组

某个系统可以位处多个组别中。请参阅 [如何构建仓库](../inventories_building.md#如何建立仓库) 及 [模式：选取主机和组](../patterns.md)。如果咱们以组内节点的功能，比如 `webservers` 或 `dbservers`，创建一些命名组，咱们的 playbook 就可以根据功能来选取机器。咱们可使用组变量系统，指定一些特定于功能的变量，并设计一些 Ansible 角色，处理特定于功能的用例。请参阅 [角色](../playbook/using/roles.md)。

## 将生产仓库与暂存仓库分开

通过为开发、测试及暂存等环境使用单独的仓库文件或目录，咱们可以将咱们的生成环境从这些环境分开。这样，咱们就可以用 `-i` 命令行选项，选择目标环境。将所有环境保存在一个文件中，可能会导致意外！例如，在使用某个仓库时，该仓库中用到的所有 vault 密码都必须可用。如果某个仓库同时包含了生产环境和开发环境，那么使用该清单的开发人员就可以访问到生产环境的秘密。


## 保持 vault 变量安全可见

咱们应使用 Ansible Vault 加密敏感或秘密变量。不过，对变量名和变量值都加密，会造成难于找到变量值的来源。为避免这种情况，咱们可使用 `ansible-vault encrypt_string` 对变量单独加密，或者添加以下的间接层，在不暴露任何秘密下保持变量名的可访问性（例如通过 `grep`）：

1. 创建一个以该组名命名的 `group_vars/` 子目录；
2. 在该子目录下创建两个文件，分别名为 `vars` 和 `vault`；
3. 在 `vars` 文件中，定义出全部所需变量，包括敏感变量；
4. 将所有敏感变量拷贝到 `vault` 文件，并在这些变量前加上 `vault_`；
5. 使用 jinja2 语法：`db_password："{{ vault_db_password }}"`，将 `vars` 文件中的变量调整为使其指向匹配的 `vault_` 变量；
6. 加密 `vault` 这个文件，以保护其内容；
7. 在咱们的 playbook 中使用 `vars` 文件中的变量名。


在运行某个 playbook 时，Ansible 就会在未加密文件中找到这些变量，他们会从加密文件中拉取到敏感变量的值。变量与 vault 文件，或他们的名字数量没有限制。

请注意，在咱们的仓库使用此策略，仍需要在使用该仓库运行时，*所有 vault 密码可用*（例如，`ansible-playbook` 或 AWX/Ansible Tower）。

（End）


