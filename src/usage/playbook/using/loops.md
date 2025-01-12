# 循环


Ansible 提供了 `loop`、`with_<lookup>` 和 `until` 关键字，来多次执行某个任务。常用循环的例子，包括使用 [`file` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html#file-module)，更改多个文件与/或目录的所有权，使用 [`user` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html#user-module) 创建多个用户，以及重复某个轮询步骤，直到得出确切结果。

> **注意**：
>
> - 虽然我们（Anisble 项目）是在 Ansible 2.5 中，才将 `loop` 作为一种更简单的完成循环方式添加进来，但我们建议将其用于大多数用例；
>
> - 我们并没有弃用 `with_<lookup>`，在可预见的未来，该语法仍将有效；
>
> - `loop` 和 `with_<lookup>` 是互斥的。尽管将他们嵌套在 `until` 下是可行的，但这会影响每次循环迭代。


## 三种循环的比较

- `until` 的一般用例，与可能失败的任务有关，而 `loop` 和 `with_<lookup>`，则用于重复任务，并略有不同；
- `loop` 和 `with_<lookup>` 将对作为输入数据的列表中，每个条目运行一次任务，而 `until` 将重复运行任务，直到满足某个条件。对于程序员来说，前者属于 “`for` 循环”，后者属于 “`while`/`until` 循环”；
- `with_<lookup>` 关键字依赖于 [查找插件](https://docs.ansible.com/ansible/latest/plugins/lookup.html#lookup-plugins) - 即使 `items` 也是一种查找；
- `loop` 关键字等同于 `with_list`，是简单循环的最佳选择；
- `loop` 关键字不接受字符串作为输入，请参阅 [确保 `loop` 的列表输入：使用查询而非查找](#确保-loop-的列表输入使用查询而非查找)；
- `until` 关键字可接受 “隐式模板化”（无需 `{{ }}`）的 “结束条件”（返回 `True` 或 `False` 的表达式），通常会基于咱们为任务 `register` 的变量；
- `loop_control` 会影响 `loop` 和 `with_<lookup>`，但不会影响 `until`，后者有自己的配套关键字：`retries` 和 `delay`；
- 一般来说，[从 `with_X` 迁移到 `loop`]() 中讲到的全部 ``with_*` 用法，都可被更新到使用 `loop`；


## 确保 `loop` 的列表输入：使用查询而非查找

## 从 `with_X` 迁移到 `loop`
