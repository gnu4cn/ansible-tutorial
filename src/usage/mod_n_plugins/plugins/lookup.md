# 查找插件


查找插件是对 Jinja2 模板化语言的一项特定于 Ansible 的扩展。咱们可在咱们的 playbook 中，使用查找插件从外部来源（文件、数据库、键/值存储、API 及其他服务），访问数据。与所有 [模板化](../../playbook/using/templating.md) 一样，查找会在 Ansible 控制机器上执行和求值。Ansible 使用标准模板化系统，令到由某个查找插件返回的数据可用。你可以使用查找插件，以来自外部资源的数据，加载变量或模板。咱们可以 [创建定制查找插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-lookup-plugins)。


> **注意**：
>
> - 与在相对于被执行脚本的目录下执行的本地任务相反，查找是在相对于角色 或 play 的目录下执行的；
>
> - 要在 Jinja2 模板的 `for` 循环中使用查找，就要将 `wantlist=True` 传递给查找插件；
>
> - 默认情况下，出于安全原因，查找返回值会被标记为不安全。若咱们信任咱们查找访问的外部来源，就要传入 `allow_unsafe=True` 以允许 Jinja2 模板计算查找值。


> **警告**：一些查找会将参数传递给 shell。在使用来自某个远端/不可信来源的变量时，要使用 `|quote` 过滤器，以确保安全使用。

## 启用查找插件

Ansible 会启用他所找到的所有查找插件。通过将定制查找插件放入与咱们 play 相邻的 `lookup_plugins` 目录中、咱们已安装专辑的 `plugins/lookup/` 目录中、在某个独立角色中，或者在 `ansible.cfg` 中配置的查找目录来源之一中，咱们便可激活该定制查找插件。


## 使用查找插件

咱们在 Ansible 中可使用模板的任何地方，都可以使用查找插件：在某个 play 中、在变量文件中或在 `template` 模组的 Jinja2 模板中等。有关使用查找插件的更多信息，请参阅 [查找](../../playbook/using/lookups.md)。


```yaml
  vars:
    file_contents: "{{ lookup('file', 'path/to/file.txt') }}"
```

查找是循环不可或缺的一部分。无论咱们在哪里看到 `with_`，下划线后面的部分都是某个查找的名字。由于这个，查找便预期会输出列表；例如，`with_items` 便使用了 [`items`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/items_lookup.html#items-lookup) 查找：

```yaml
    - name: count to 3
      debug: msg={{ item }}
      with_items: [1, 2, 3]
```

可以将查找与 [过滤器](../../playbook/using/filters.md)、[测试](../../playbook/using/tests.md)，甚至他们相互之间结合起来，完成复杂的数据生成及操作。例如：


```yaml
    - name: Complicated chained lookups and filters
      debug: msg="find the answer here:\n{{ lookup('url', 'https://google.com/search/?q=' + item|urlencode)|join(' ') }}"
      with_nested:
        - "{{ lookup('consul_kv', 'bcs/' + lookup('file', '/the/question') + ', host=localhost, port=2000')|shuffle }}"
        - "{{ lookup('sequence', 'end=42 start=2 step=2')|map('log', 4)|list) }}"
        - ['a', 'c', 'd', 'c']
```

*版本 2.6 中的新特性*。


通过将查找插件的 `errors` 选项设置为 `ignore`、`warn` 或 `strict`，咱们可以控制所有查找插件中，错误的行为方式。默认设置为 `strict`，这会在查找返回某个错误时，引发任务失败。例如：


要忽略查找错误：


```yaml
    - name: if this file does not exist, I do not care .. file plugin itself warns anyway ...
      debug: msg="{{ lookup('file', '/nosuchfile', errors='ignore') }}"
```


```console
ok: [localhost] => {
    "msg": ""
}
```

> **译注**：上面的输出是 Ansible 2.18 中的输出，完全不带警告信息。原文带有 `[WARNING]: Unable to find '/nosuchfile' in expected paths (use -vvvvv to see paths)` 警告信息。

要获取一条警告信息而非任务失败：

```yaml
    - name: if this file does not exist, I do not care .. file plugin itself warns anyway ...
      debug: msg="{{ lookup('file', '/nosuchfile', errors='warn') }}"
```

```console
[WARNING]: Lookup failed but the error is being ignored: The 'file' lookup had an issue accessing the file '/nosuchfile'.
file not found, use -vvvvv to see paths searched
ok: [localhost] => {
    "msg": ""
}
```

要获得一个致命错误（默认行为）：


```yaml
    - name: if this file does not exist, I do not care .. file plugin itself warns anyway ...
      debug: msg="{{ lookup('file', '/nosuchfile', errors='strict') }}"
```

```console
fatal: [localhost]: FAILED! => {"msg": "The 'file' lookup had an issue accessing the file '/nosuchfile'. file not found, use -vvvvv to see paths searched"}
```

## 强制查找返回列表：`query` 与 `wantlist=True`


*版本 2.5 中的新特性*。


Ansible 2.5 中，为调用查找插件而新增了一个名为 `query` 的 Jinja2 函数。`lookup` 和 `query` 的区别，主要在于 `query` 将总是会返回一个列表。而 `lookup` 的默认行为是返回一个逗号分隔值的字符串。使用 `wantlist=True` 插件选项，便可将 `lookup` 显式配置为返回列表。

此特性在保持了 `lookup` 其他用途的向后兼容性的同时，为与新 `loop` 关键字的交互，提供了一个更简便、更一致的界面的接口。

以下两个示例是等价的：


```yaml
lookup('dict', dict_variable, wantlist=True)

query('dict', dict_variable)
```


如上所示，使用查询时，`wantlist=True` 的行为是隐式的。

此外，作为 `query` 的简短形式引入了 `q`：


```yaml
q('dict', dict_variable)
```


## 插件列表

咱们可使用 `ansible-doc -t lookup -l` 命令查看可用插件的列表。使用 `ansible-doc -t lookup <plugin name>` 查看特定插件的文档与示例。

（End）


