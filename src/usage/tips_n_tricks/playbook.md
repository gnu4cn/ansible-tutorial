# Playbook 的技巧

下面这些技巧有助于使 playbook 和角色更易于阅读、维护和调试。


## 使用空白空间

毫不吝惜的使用空白，例如在每个区块或任务前空一行，可使 playbook 易于扫描。


## 始终给 play、任务及区块命名

Play、任务及区块的 `- name:` 是可选项，但非常有用。在其输出中，Ansible 会显示其所运行的各个命名实体的名字。要选择能描述各个 play、任务和区块的作用和原因的名字。


## 始终留意状态

对于很多模组，其 `state` 参数都是可选的。

不同模组有不同的默认 `state` 设置，有些模组还支持多种 `state` 设置。显式地设置 `state: present` 或 `state: absent`，会让 playbook 及角色更清晰。


## 使用注释


即使带有任务名称和显式的状态，有时某个 playbook 或角色（或仓库/变量文件）的某个部分，也需要更多解释。添加注释（以 `#` 开头的任何行）可以帮助他人（将来也可能是咱们自己），理解某个 play 或任务（或变量设置）的作用、实现方式和原因。


## 使用完全限定的专辑名字

要使用 [完全限定的专辑名字 (FQCN)](https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html#term-Fully-Qualified-Collection-Name-FQCN)，避免在为各个任务，在哪个专辑中检索正确的模组或插件时出现歧义。

对于那些 [内置模组和插件](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html#plugin-index)，要使用 `ansible.builtin` 这个专辑名称作为前缀，例如 `ansible.builtin.copy`。


（End）


