# 操作数据

在许多情况下，咱们都将需要对咱们的变量，执行复杂操作。虽然不建议将 Ansible 作为数据处理/操作的工具，但咱们可将现有的 Jinja2 模板，与许多新增的 Ansible 过滤器、查找和测试插件结合使用，执行一些非常复杂的转换。


我们先来了解一下，每种插件的定义：

- 查找插件：主要用于查询 “外部数据”，在 Ansible 中他们是那些用到 `with_<lookup>` 结构的循环的主要部分，但也可单独用于返回数据以供处理。如前所述，由于在循环中的这种首要功能，他们通常会返回一个列表。他们与Jinja2 的 `lookup` 或 `query` 操作符一起使用；
- 过滤器插件：用于修改/转换数据，与 Jinja2 的 `|` 操作符一起使用；
- 测试插件：用于验证数据，与 Jinja2 的 `is` 操作符一起使用。

### 循环与列表综合

**Loops and list comprehensions**

大多数编程语言都有着循环（`for`、`while` 等），以及对包含对象列表的列表进行转换的列表综合。Jinja2 有几个提供这种功能的过滤器：`map`、`select`、`reject`、`selectattr`、`rejectattr` 等。


- `map`：这是个只允许咱们更改列表中各个条目的基本 `for` 循环，而使用 `attribute` 关键字，咱们就可以根据列表元素的属性，完成转换；
- `select`/`reject`：这是个允许咱们根据条件结果，创建出匹配（或不匹配）列表的列表子集的带条件 `for` 循环；
- `selectattr`/`rejectattr`：与上面的 `select`/`reject` 过滤器非常相似，但他会将列表元素的某个特定属性，用作条件语句。


使用循环创建指数后退。


```yaml
    - name: try wait_for_connection up to 10 times with exponential delay
      ansible.builtin.wait_for_connection:
        delay: '{{ item | int }}'
        timeout: 1
      loop: '{{ range(1, 11) | map("pow", 2) }}'
      loop_control:
        extended: true
      ignore_errors: "{{ not ansible_loop.last }}"
      register: result
      when: result is not defined or result is failed
```


### 从字典中提取与某个列表元素匹配的键

Python 的等效代码将是：


```python
chains = [1, 2]
for chain in chains:
    for config in chains_config[chain]['configs']:
        print(config['type'])
```


*从某个字典列表中，提取匹配键的方法*

```yaml
  tasks:
    - name: Show extracted list of keys from a list of dictionaries
      ansible.builtin.debug:
        msg: "{{ chains | map('extract', chains_config) | map(attribute='configs') | flatten | map(attribute='type') | flatten }}"
      vars:
        chains: [1, 2]
        chains_config:
            1:
                foo: bar
                configs:
                    - type: routed
                      version: 0.1
                    - type: bridged
                      version: 0.2
            2:
                foo: baz
                configs:
                    - type: routed
                      version: 1.0
                    - type: bridged
                      version: 1.1
```

*`debug` 任务的结果，一个所提取出键的列表*


```console
ok: [localhost] => {
    "msg": [
        "routed",
        "bridged",
        "routed",
        "bridged"
    ]
}
```

*获取在主机上各异的某个值的唯一列表*


```yaml
      vars:
        unique_value_list: "{{ groups['all'] | map('extract', hostvars, 'varname') | list | unique }}"
```

> **译注**：其中的 `'varname'` 应替换成具体的某个 `hostvars` 字段名，否则会报出错误：`'ansible.vars.hostvars.HostVarsVars object' has no attribute 'varname'`。

### 找出挂载点

