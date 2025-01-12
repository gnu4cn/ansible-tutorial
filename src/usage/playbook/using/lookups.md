# 查找

查找插件从外部来源，如文件、数据库、键/值存储、API 及其他服务等获取数据。与所有模板一样，查找是在 Ansible 控制机器上，执行与求值的。Ansible 利用标准模板系统，令到由查找插件返回的数据可用。在 Ansible 版本 2.5 前，查找大多是在循环中的 `with_<lookup>` 结构中，间接得以使用的。从 Ansible 2.5 开始，查找作为喂给 `loop` 关键字数据的 Jinja2 表达式的一部分，被更明确地使用了。


## `lookup` 函数


咱们可以使用 `lookup`函数，动态填充变量。在某个任务（或模板）中，每次执行到该函数时，Ansible 就会计算出其值。

```yaml
  vars:
    motd_value: "{{ lookup('file', '/etc/motd') }}"
  tasks:
    - debug:
        msg: "motd value is {{ motd_value }}"
```

> **译注**：这将查找控制节点本地，而非远端托管节点上的 `/etc/motd` 文件，若本地没有这个文件，则任务会失败。


`lookup` 函数的第一个参数是必需的，他指定了查找插件的名字。如果该查找插件位于某个专辑中，则必须提供其完全限定的名称，因为 [集合关键字](https://docs.ansible.com/ansible/latest/collections_guide/collections_using_playbooks.html#collections-keyword) 不适用于查找插件。

`lookup` 函数还接受一个可选的布尔关键字 `wantlist`，默认值为 `False`。为 `True` 时，将确保查找结果是个列表。

请参阅查找插件的文档，了解特定于插件的那些参数和关键字。

### `query`/`q` 函数

该函数是 `lookup(..., wantlist=True)` 的简写。二者是等价的：


```yaml
block:
  - debug:
      msg: "{{ item }}"
    loop: "{{ lookup('ns.col.lookup_items', wantlist=True) }}"

  - debug:
      msg: "{{ item }}"
    loop: "{{ q('ns.col.lookup_items') }}"
```
