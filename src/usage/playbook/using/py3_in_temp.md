# 模板中的 Python3


Ansible 使用 Jinja2，来充分利用 Python 数据类型，及模板中的标准函数，还有变量。咱们可以使用这些数据类型和标准函数，对咱们的数据执行丰富操作。但是，如果咱们用到了模板，就必须注意 Python 版本之间的差异。

下面这些主题，可以帮助咱们设计出，在 Python2 和 Python3 上都能运行的模板。如果咱们要从 Python2 升级到 Python3，他们也会有所帮助。在 Python2 或 Python3 内部的升级，通常不会引入影响到 Jinja2 模板的变化。


## 字典视图

在 Python2 中，`dict.keys()`、`dict.values()` 和 `dict.items()` 三个方法，都会返回一个列表。Jinja2 会使用一种 Ansible 可以将其转换回列表的字符串表示法，将其返回给 Ansible。

在 Python3 中，这些方法会返回一个 [字典视图](https://docs.python.org/3/library/stdtypes.html#dict-views) 对象。Ansible 无法将 Jinja2 返回的字典视图字符串，解析为列表。不过，在用到 `dict.keys()`、`dict.values()` 或 `dict.items()` 时，可以通过 `list` 过滤器轻松实现可移植性。

```yaml
  vars:
    hosts:
      testhost1: 127.0.0.2
      testhost2: 127.0.0.3

  tasks:
    - debug:
        msg: '{{ item }}'
      # 下面的写法仅适用于 Python 2
      # loop: "{{ hosts.keys() }}"
      # 这种写法同时适用于 Python2 和 Python3
      loop: "{{ hosts.keys() | list }}"
```

## `dict.iteritems()`

Python2 的字典有 `iterkeys()`、`itervalues()` 和 `iteritems()` 方法。

Python3 的字典没有这些方法。要让咱们的 playbook 和模板，同时兼容 Python2 和 Python3，就要使用 `dict.keys()`、`dict.values()` 和 `dict.items()` 方法。


```yaml
  vars:
    hosts:
      testhost1: 127.0.0.2
      testhost2: 127.0.0.3

  tasks:
    - debug:
        msg: '{{ item }}'
      # 下面的写法仅适用于 Python 2
      # loop: "{{ hosts.iteritems() }}"
      # 这种写法同时适用于 Python2 和 Python3
      loop: "{{ hosts.items() | list }}"
```
