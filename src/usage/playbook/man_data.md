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


在这个示例中，我们打算找出所有机器上，某个指定路径的挂载点，由于我们已经收集了挂载事实，因此我们可使用下面的方法：


```yaml
---
- hosts: all:!win10-133
  gather_facts: yes
  vars:
    path: /boot

  tasks:
    - name: The mount point for {{path}}, found using the Ansible mount facts, [-1] is the same as the 'last' filter
      ansible.builtin.debug:
       msg: "{{(ansible_facts.mounts | selectattr('mount', 'in', path) | list | sort(attribute='mount'))[-1]['mount']}}"
```

> **译注**：可以看到，在任务的 `name` 字段中，也可以使用模板插值语法。


### 略去列表中的一些元素


这个特殊的 `omit` 变量，只适用于模组的选项，但咱们仍可以其他方式，将其用作其他裁剪某个元素清单的标识符：


*在喂给某个模组选项数据时的内联列表过滤器*


```yaml
   - name: Enable a list of Windows features, by name
     ansible.builtin.set_fact:
       win_feature_list: "{{ namestuff | reject('equalto', omit) | list }}"
     vars:
       namestuff:
         - "{{ (fs_installed_smb_v1 | default(False)) | ternary(omit, 'FS-SMB1') }}"
         - "foo"
         - "bar"
```

另一种方法是避免在列表开头添加元素，这样咱们就可以直接使用，another way is to avoid adding elements to the list in the first place, so you can just use it directly：


*在循环中使用 `set_fact` 有条件地递增某个列表*


```yaml
   - name: Build unique list with some items conditionally omitted
     ansible.builtin.debug:
        msg: ' {{ (namestuff | default([])) | union([item]) }}'
     when: item != omit
     loop:
         - "{{ (fs_installed_smb_v1 | default(False)) | ternary(omit, 'FS-SMB1') }}"
         - "foo"
         - "bar"
```


### 合并同一字典列表中的值


结合上述示例中的正向与负向过滤器，咱们就可以得到 “确实存在的值”，以及当不存在时的 “回退值”。


*使用 `selectattr` 和 `rejectattr` 获取获取所需的 `ansible_host` 或 `inventory_hostname`*

```yaml
- hosts: localhost

   tasks:
     - name: Check hosts in inventory that respond to ssh port
       wait_for:
         host: "{{ item }}"
         port: 22
       loop: '{{ has_ah + no_ah }}'
       vars:
         has_ah: '{{ hostvars|dictsort|selectattr("1.ansible_host", "defined")|map(attribute="1.ansible_host")|list }}'
         no_ah: '{{ hostvars|dictsort|rejectattr("1.ansible_host", "defined")|map(attribute="0")|list }}'
```

### 根据某个变量定制 `fileglob`

下面这个示例使用了 [Python 参数列表解包语法](https://docs.python.org/3/tutorial/controlflow.html#unpacking-argument-lists)，以根据某个变量，创建出一个自定义的 `fileglob` 列表。


```yaml
- hosts: webservers
  gather_facts: no

  vars:
    mygroups:
      - prod
      - web

  tasks:
    - name: Copy a glob of files based on a list of groups
      copy:
        src: "{{ item }}"
        dest: "/tmp/{{ item }}"
      loop: '{{ q("fileglob", *globlist) }}'
      vars:
        globlist: '{{ mygroups | map("regex_replace", "^(.*)$", "files/\1/*.conf") | list }}'
```

> **译注**：这个示例中，`globlist` 的值如下：

```json
[
    "files/prod/*.conf",
    "files/web/*.conf"
]
```

> `q("fileglob", *globlist)` 将查找出 playbook 所在目录下，与 `globlist` 匹配的文件。


## 复杂的类型转换


Jinja 提供了简单数据类型转换（`int`、`bool` 等）的过滤器，但当咱们想转换某些数据结构时，事情就没那么简单了。咱们可以使用循环和列表综合（如上示）来帮忙，也可使用一些其他可以链接起来的过滤器和查找，实现更复杂的转换。


### 从列表创建字典

在大多数语言中，从成对的列表，创建出字典（也称为映射/关联数组/哈希表，map/associative array/hash，等）都不难。在 Ansible 中，有几种方法可以做到这点，而最适合咱们的方法，则可能取决于咱们的数据源。


下面这两个示例，会产生出 `{"a": "b", "c": "d"}` 这个字典。


*假定列表为 `[key, value, key, value, ...]` 形式下的简单列表到字典转换*


```yaml
  vars:
    single_list: [ 'a', 'b', 'c', 'd' ]
    mydict: "{{ dict(single_list[::2] | zip_longest(single_list[1::2])) }}"
```

*当咱们有个成对的列表时，就更简单*：


```yaml
 vars:
     list_of_pairs: [ ['a', 'b'], ['c', 'd'] ]
     mydict: "{{ dict(list_of_pairs) }}"
```


两者的最终结果一样，`zip_longest` 将 `single_list`，转换为一个 `list_of_pairs` 的生成器。


稍微复杂一些，使用 `set_fact` 和 `loop`，从来自 2 个列表的键值对创建/更新出一个字典：

*使用 `set_fact` 从列表集合创建出一个字典*

```yaml
    - name: Uses 'combine' to update the dictionary and 'zip' to make pairs of both lists
      ansible.builtin.set_fact:
        mydict: "{{ mydict | default({}) | combine({item[0]: item[1]}) }}"
      loop: "{{ (keys | zip(values)) | list }}"
      vars:
        keys:
          - foo
          - var
          - bar
        values:
          - a
          - b
          - c
```

这会得到 `{"foo": "a", "var": "b", "bar": "c"}`。

咱们甚至可以将这些简单示例与其他筛选器和查找插件结合，通过变量名模式匹配，动态地创建出字典：


```yaml
  vars:
    xyz_stuff: 1234
    xyz_morestuff: 567
    abc_stuff: 890
    myvarnames: "{{ q('varnames', '^xyz_') }}"
    mydict: "{{ dict(myvarnames|map('regex_replace', '^xyz_', '')|list | zip(q('vars', *myvarnames))) }}"
```

简单解释一下，因为从这两行中可以看出很多东西：

- 其中的 `varnames` 查找，会返回一个匹配 “以 `xyz_` 开头” 的变量列表；
- 随后将上一步的列表，喂给其中的 `vars` 查找，以获得值的列表。`*` 用于 “解引用列表”（一种在 Jinja 中有效的 python 机制），否则他将把该列表作为单一参数；
- 两个列表都会传递给 `zip` 过滤器，将他们配对成一个统一列表`(key、value、key2、value2...)`；
- 随后 `dict` 函数会利用这个 “配对列表”，创建出字典。

下面是个如何使用事实，找出某个满足条件 X 的主机数据：

```yaml
  vars:
    uptime_of_host_most_recently_rebooted: "{{ansible_play_hosts_all | map('extract', hostvars, 'ansible_uptime_seconds') | sort | first}}"
```


下面是个以 天/小时/分钟/秒 为单位，显示某个主机运行时间的示例（假设事实已收集）。


```yaml
    - name: Show the uptime in days/hours/minutes/seconds
      ansible.builtin.debug:
       msg: Uptime {{ now().replace(microsecond=0) - now().fromtimestamp(now(fmt='%s') | int - ansible_uptime_seconds) }}
```

（End）


