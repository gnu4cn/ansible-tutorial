# 使用过滤器来操作数据

过滤器可让咱们将 JSON 数据转换为 YAML 数据、切分 URL 来提取主机名、获取字符串的 SHA1 哈希值、对整数进行加法或乘法运算，等等。咱们可以使用这里所记录的特定于 Ansible 的过滤器，来处理数据，也可以使用 Jinja2 提供的任何标准过滤器 -- 请参阅 Jinja2 官方模板文档中的 [内置过滤器](https://jinja.palletsprojects.com/en/stable/templates/#builtin-filters) 列表。咱们也可以使用 [Python 的方法](https://jinja.palletsprojects.com/en/stable/templates/#python-methods) 来转换数据。咱们可以插件方式，[创建自定义的 Ansible 过滤器](../../dev_guide/plugins.md)，不过我们通常欢迎将新的过滤器，放到 `ansible-core` 的源码仓库中，以便每个人都能使用他们。


由于模板化发生在 Ansible 控制节点上，而非目标主机上，因此过滤器是在控制节点上执行，并在本地转换数据。


## 处理未定义的变量

通过提供默认值或使某些变量成为可选，过滤器可以帮助咱们管理缺失或未定义的变量。如果咱们将 Ansible 配置为了忽略大多数未定义变量，则可以使用 `mandatory` 过滤器，将某些变量标记为必需值。


### 提供默认值

使用 Jinja2 的 `default` 过滤器，咱们就可以直接在模板中为变量提供默认值。与在因某个变量为定义而失败相比，这是种更好的方案：

```yaml
{{ some_variable | default(5) }}
```

在上面的示例中，如果变量 `some_variable` 未被定义，那么 Ansible 会使用默认值 `5`，而不是抛出 `undefined variable` 错误并导致失败。如果咱们在某个角色中工作，也可以添加一些为咱们角色中变量，定义默认值的角色默认值。要了解有关角色默认值的更多信息，请参阅 [角色目录结构](../roles.md)。


从 2.8 版开始，在 Jinja 中尝试访问某个未定义值的属性时，将返回另一未定义值，而不是立即抛出错误。这意味着在咱们不知道中间值是否已定义的情况下，现在可以在某个嵌套数据结构中，简单地使用默认值了（也即是 `{{ foo.bar.baz | default('DEFAULT') }}`）。

若咱们打算在变量求值为 `false` 或空字符串时使用默认值，则必须将第二个参数设置为 `true`：


```yaml
{{ lookup('env', 'MY_USER') | default('admin', true) }}
```

### 将变量标记为可选


默认情况下，Ansible 需要模板表达式中所有变量的值。不过，咱们可以将特定的模组变量，设置为可选。例如，咱们可能想对某些项目使用系统默认值，并控制其他项目的值。要使某个模组变量成为可选，就要将默认值，设置为特殊变量 `omit`：

```yaml
- name: Touch files with an optional mode
  ansible.builtin.file:
    dest: "{{ item.path }}"
    state: touch
    mode: "{{ item.mode | default(omit) }}"
  loop:
    - path: /tmp/foo
    - path: /tmp/bar
    - path: /tmp/baz
      mode: "0444"
```

在这个示例中，文件 `/tmp/foo` 和 `/tmp/bar` 的默认模式，由系统的 `umask` 决定。Ansible 没有发送 `mode` 值。只有第三个文件 `/tmp/baz`，收到了 `mode=0444` 选项。

> **注意**：如果咱们要在 `default(omit)` 过滤器后， “链接” 其他过滤器，应该这样做： `"{{ foo | default(None) | some_filter or omit }}"`。在本例中，默认 `None`（Python 的 `null`）值将导致随后的过滤器失败，从而触发该逻辑的 `or omit` 部分。不过，以这种方式使用 `omit` 与随后的过滤器有很大的关系，所以如果咱们要这样做，就要做好试错的准备。


### 定义强制值

如果咱们将 Ansible 配置为忽略未定义变量，那么就可能需要将某些值定义为强制值。默认情况下，如果咱们的 playbook 或命令中某个变量未被定义，Ansible 就会失败。咱们可以通过设置 `DEFAULT_UNDEFINED_VAR_BEHAVIOR` 为 `false`，将 Ansible 配置为允许未定义变量。在这种情况下，咱们可能要求某些变量必须定义。咱们可以使用：


```yaml
{{ variable | mandatory }}
```

变量值将按原样使用，但如果其未被定义，那么模板的求值将抛出一个错误。

要求某个变量被覆盖的一种便捷方法，是使用 `undef()` 函数为其赋予一个未定义的值。


```yaml
galaxy_url: "https://galaxy.ansible.com"
galaxy_api_key: "{{ undef(hint='You must specify your Galaxy API key') }}"
```


## 为 `true`/`false`/`null` 定义不同值（`ternary`）


咱们可以创建个测试，然后定义一个在该测试返回 `true` 时使用的值，另一个在返回 `false` 时使用（1.9 版新增）：


```yaml
{{ (status == 'needs_restart') | ternary('restart', 'continue') }}
```

此外，咱们还可以定义一个在 `true` 时使用的值，一个在 `false` 时使用的值，以及第三个在 `null` 时使用的值（2.8 版新增）：


```yaml
{{ enabled | ternary('no shutdown', 'shutdown', omit) }}
```


## 管理数据类型

咱们可能需要了解、修改或设置某个变量的数据类型。例如，当咱们的下一任务需要某个列表时，某个注册变量却可能包含著一个字典；当咱们的 playbook 需要一个布尔值时，用户 [输入提示符](prompts.md) 却可能返回个字符串。请使用 [`ansible.builtin.type_debug`](../../../collections/ansible_builtin.md)、[`ansible.builtin.dict2items`](../../../collections/ansible_builtin.md) 以及 [`ansible.builtin.items2dict`](../../../collections/ansible_builtin.md) 过滤器，管理数据类型。咱们也可以使用数据类型本身，将某个值转换为指定数据类型。


### 发现数据类型


*版本 2.3 中新引入*。

若咱们不确定某个变量的地层 Python 类型，可以使用 `ansible.builtin.type_debug` 过滤器来将其显示出来。这对咱们需要某个特定类型变量时的调试很有用：

```yaml
{{ myvar | type_debug }}
```

需要注意的是，虽然这看起来像是个，可以用来检查某个变量中的数据类型是否正确的有用过滤器，但咱们通常更喜欢 [类型测试](tests.md)，他允许咱们测试出特定数据类型。

### 将字符串转换为列表

使用 [`ansible.builtin.split`](../../../collections/ansible_builtin.md) 过滤器，将字符/字符串分隔的字符串，转换为适合 [循环](loops.md) 的项目列表。例如，如果咱们打算切分一个以逗号分隔的字符串变量 `fruits`，就可以使用：

```yaml
{{ fruits | split(',') }}
```

字符串数据（在应用 `ansible.builtin.split` 过滤器前）：

```yaml
fruits: apple,banana,orange
```

列表数据（应用 `ansible.builtin.split` 后）：

```yaml
- apple
- banana
- orange
```


### 将字典转化为列表

*版本 2.6 中的新特性*。

使用 [`ansible.builtin.dict2items`](../../../collections/ansible_builtin.md) 过滤器，将字典转换为适合 [循环](loops.md) 的项目列表：

```yaml
{{ dict | dict2items }}
```

字典数据（在应用 `ansible.builtin.dict2items` 前）：

```yaml
tags:
  Application: payment
  Environment: dev
```


列表数据（应用 `ansible.builtin.dict2items` 后）：


```yaml
- key: Application
  value: payment
- key: Environment
  value: dev
```

*版本 2.8 中的新特性*。


`ansible.builtin.dict2items` 过滤器与 [`ansible.builtin.items2dict`](../../../collections/ansible_builtin.md) 过滤器相反。


若咱们想要配置键的名称，那么 `ansible.builtin.dict2items` 过滤器就要接受两个关键字参数。就要传递 `key_name` 和 `value_name` 两个参数，来配置列表输出中的键名：


```yaml
{{ files | dict2items(key_name='file', value_name='path') }}
```

字典数据（在应用 `ansible.builtin.dict2items` 前）：

```yaml
files:
  users: /etc/passwd
  groups: /etc/group
```

列表数据（应用 `ansible.builtin.dict2items` 后）：


```yaml
- file: users
  path: /etc/passwd
- file: groups
  path: /etc/group
```


### 将列表转换为字典


*版本 2.7 中的新特性*。


使用 [`ansible.builtin.items2dict`](../../../collections/ansible_builtin.md) 过滤器，将列表转换为字典，将内容映射为 `key: value` 对：


```yaml
{{ tags | items2dict }}
```



列表数据（在应用 `ansible.builtin.items2dict` 前）：

```yaml
tags:
  - key: Application
    value: payment
  - key: Environment
    value: dev
```


字典数据（应用 `ansible.builtin.items2dict` 后）：


```yaml
Application: payment
Environment: dev
```

`ansible.builtin.items2dict` 过滤器与 `ansible.builtin.dict2items` 过滤器相反。

并非所有列表都用 `key` 表示键，用 `value` 表示值。例如：

```yaml
fruits:
  - fruit: apple
    color: red
  - fruit: pear
    color: yellow
  - fruit: grapefruit
    color: yellow
```

在这个示例中，咱们就必须传递 `key_name` 和 `value_name` 参数，来配置转换。例如：


```yaml
{{ fruits | items2dict(key_name='fruit', value_name='color') }}
```


若咱们没有传递这些参数，或没有为咱们的列表传递正确值，就将看到 `KeyError: key` 或 `KeyError: my_typo`。


### 强制数据类型

咱们可以将值，转换为某些类型。例如，如果咱们期望从 [vars_prompt](prompts.md) 中得到输入 `True`，并希望 Ansible 将其识别为一个布尔值而非字符串：


```yaml
- ansible.builtin.debug:
     msg: test
  when: some_string_value | bool
```

若咱们打算对某个事实进行数学比较，并希望 Ansible 将其识别为一个整数而非字符串：


```yaml
- shell: echo "only on Red Hat 6, derivatives, and later"
  when: ansible_facts['os_family'] == "RedHat" and ansible_facts['lsb']['major_release'] | int >= 6
```


*版本 1.6 中的新特性*。


## 格式化数据：YAML 与 JSON


你可以将模板中的某个数据结构，在 JSON 和 YAML 格式之间互相转换，并带有格式化、缩进和加载数据等选项。基本的筛选器，偶尔也能用于调试目的：


```yaml
{{ some_variable | to_json }}
{{ some_variable | to_yaml }}
```

有关这两个过滤器的文档，请参阅 [`ansible.builtin.to_json`](../../../collections/ansible_builtin.md) 和 [`ansible.builtin.to_yaml`](../../../collections/ansible_builtin.md)。


要获得人类可读的输出，可以使用：

```yaml
{{ some_variable | to_nice_json }}
{{ some_variable | to_nice_yaml }}
```


有关这两个过滤器的文档，请参阅 [`ansible.builtin.to_nice_json`](../../../collections/ansible_builtin.md) 和 [`ansible.builtin.to_nice_yaml`](../../../collections/ansible_builtin.md)。


咱们可以改变两种格式的缩进：

```yaml
{{ some_variable | to_nice_json(indent=2) }}
{{ some_variable | to_nice_yaml(indent=8) }}
```

`ansible.builtin.to_yaml` 和 `ansible.builtin.to_nice_yaml` 过滤器使用了 [PyYAML 库](https://pyyaml.org/)，该库有着默认字符串长度为 80 个符号的限制。这会导致第 80 个符号后出现意外换行（如果第 80 个符号后有个空格）。要避免这种行为并产生出长行，请使用 `width` 选项。咱们必须使用一个硬编码数字定义宽度，而不是使用 `float("inf")` 这样的结构，因为过滤器不支持代理 Python 函数。例如：

```yaml
{{ some_variable | to_yaml(indent=8, width=1337) }}
{{ some_variable | to_nice_yaml(indent=8, width=1337) }}
```

过滤器确实支持传递其他 YAML 参数。有关所支持参数的完整列表，请参阅 [`dump()` 的 PyYAML 文档](https://pyyaml.org/wiki/PyYAMLDocumentation)。

如果咱们读入的是一些已经格式化好的数据：


```yaml
{{ some_variable | from_json }}
{{ some_variable | from_yaml }}
```

比如：


```yaml
tasks:
  - name: Register JSON output as a variable
    ansible.builtin.shell: cat /some/path/to/file.json
    register: result

  - name: Set a variable
    ansible.builtin.set_fact:
      myvar: "{{ result.stdout | from_json }}"
```

### `to_json` 过滤器与 Unicode 支持


默认情况下，`ansible.builtin.to_json` 和 `ansible.builtin.to_nice_json` 都会将接收到的数据，转换为 ASCII 格式，因此：

```yaml
{{ 'München'| to_json }}
```

将返回：

```console
'M\u00fcnchen'
```

要保留 Unicode 字符，就要传递 `ensure_ascii=False` 参数给该过滤器：


```console
{{ 'München'| to_json(ensure_ascii=False) }}

'München'
```


*版本 2.7 中的新特性*。

为解析多文档 YAML 字符串，就提供了 [`ansible.builtin.from_yaml_all`](../../../collections/ansible_builtin.md) 过滤器。`ansible.builtin.from_yaml_all` 过滤器将返回一个已解析 YAML 文档的生成器。

比如：


```yaml
tasks:
  - name: Register a file content as a variable
    ansible.builtin.shell: cat /some/path/to/multidoc-file.yaml
    register: result

  - name: Print the transformed variable
    ansible.builtin.debug:
      msg: '{{ item }}'
    loop: '{{ result.stdout | from_yaml_all | list }}'
```


## 合并与选择数据


咱们可以从多个来源、多种类型，组合出数据，以及从大型数据结构中选取某些值，从而对复杂数据进行精确控制。


### 合并多个列表中的项目： `zip` 和 `zip_longest`

*版本 2.3 中新引入*。

使用 [`ansible.builtin.zip`](../../../collections/ansible_builtin.md) 获取一个结合了其他列表元素的列表：


```yaml
- name: Give me list combo of two lists
  ansible.builtin.debug:
    msg: "{{ [1,2,3,4,5,6] | zip(['a','b','c','d','e','f']) | list }}"

# => [[1, "a"], [2, "b"], [3, "c"], [4, "d"], [5, "e"], [6, "f"]]

- name: Give me the shortest combo of two lists
  ansible.builtin.debug:
    msg: "{{ [1,2,3] | zip(['a','b','c','d','e','f']) | list }}"

# => [[1, "a"], [2, "b"], [3, "c"]]
```


要始终穷举全部列表，请使用 [`ansible.builtin.zip_longest`](../../../collections/ansible_builtin.md)：


```yaml
- name: Give me the longest combo of three lists, fill with X
  ansible.builtin.debug:
    msg: "{{ [1,2,3] | zip_longest(['a','b','c','d','e','f'], [21, 22, 23], fillvalue='X') | list }}"

# => [[1, "a", 21], [2, "b", 22], [3, "c", 23], ["X", "d", "X"], ["X", "e", "X"], ["X", "f", "X"]]
```


与上面提到的 `ansible.builtin.items2dict` 过滤器的输出类似，这些过滤器可用于构建出一个 `dict`：


```yaml
{{ dict(keys_list | zip(values_list)) }}
```

列表数据（在应用 `ansible.builtin.zip` 过滤器前）：

```yaml
keys_list:
  - one
  - two
values_list:
  - apple
  - orange
```

字典数据（应用 `ansible.builtin.zip` 过滤器后）：


```yaml
one: apple
two: orange
```


### 组合对象与子元素


*版本 2.7 中新引入*。


[`ansible.builtin.subelements`](../../../collections/ansible_builtin.md) 过滤器，会产生出一个对象与该对象的子元素值的叉积，类似于 `ansible.builtin.subelements` 的查找。这让咱们可以在模板中指定出，要使用的单个子元素。例如：


```yaml
{{ users | subelements('groups', skip_missing=True) }}
```

应用 `ansible.builtin.subelements` 过滤器前的数据：

```yaml
users:
- name: alice
  authorized:
  - /tmp/alice/onekey.pub
  - /tmp/alice/twokey.pub
  groups:
  - wheel
  - docker
- name: bob
  authorized:
  - /tmp/bob/id_rsa.pub
  groups:
  - docker
```


应用 `ansible.builtin.subelements` 过滤器后的数据：


```yaml
-
  - name: alice
    groups:
    - wheel
    - docker
    authorized:
    - /tmp/alice/onekey.pub
    - /tmp/alice/twokey.pub
  - wheel
-
  - name: alice
    groups:
    - wheel
    - docker
    authorized:
    - /tmp/alice/onekey.pub
    - /tmp/alice/twokey.pub
  - docker
-
  - name: bob
    authorized:
    - /tmp/bob/id_rsa.pub
    groups:
    - docker
  - docker
```

对转换后的数据使用 `loop`，咱们就可以遍历多个对象的相同子元素了：

```yaml
- name: Set authorized ssh key, extracting just that data from 'users'
  ansible.posix.authorized_key:
    user: "{{ item.0.name }}"
    key: "{{ lookup('file', item.1) }}"
  loop: "{{ users | subelements('authorized') }}"
```


### 组合哈希值/字典


*版本 2.0 中新引入*。


`ansible.builtin.combine` 过滤器允许合并哈希值。例如，以下代码将覆盖一个哈希值中的键：


```yaml
{{ {'a':1, 'b':2} | combine({'b':3}) }}
```

得到的哈希值将是：


```console
{'a':1, 'b':3}
```


该过滤器还可以接受多个要合并的参数：


```yaml
{{ a | combine(b, c, d) }}
{{ [a, b, c, d] | combine }}
```

在这种情况下，`d` 中的键值将覆盖 `c` 中的键值，而 `c` 中的键值又会覆盖 `b` 中的键值，以此类推。


该过滤器还接受两个可选参数：`recursive` 和 `list_merge`。


- `recursive`

是个布尔值，默认为 `False`。`ansible.builtin.combine` 是否应该递归合并嵌套的哈希值。注意：其 *不* 依赖于 `ansible.cfg` 中的 `hash_behaviour` 设置值。


- `list_merge`

是个字符串，可能的值分别是 `replace`（默认的）、`keep`、`append`、`prepend`、`append_rp` 或 `prepend_rp`。当要合并的哈希值包含了数组/列表时，他会修改 `ansible.builtin.combine` 的行为。


```yaml
default:
  a:
    x: default
    y: default
  b: default
  c: default
patch:
  a:
    y: patch
    z: patch
  b: patch
```

如果 `recursive=False` （默认值），嵌套哈希值就不会被合并：


```yaml
{{ default | combine(patch) }}
```

这会得到：


```yaml
a:
  y: patch
  z: patch
b: patch
c: default
```

如果 `recursive=True`，就会递归进入到嵌套的哈希值，并合并他们的键：


```yaml
{{ default | combine(patch, recursive=True) }}
```

这将得到：


```yaml
a:
  x: default
  y: patch
  z: patch
b: patch
c: default
```


如果 `list_merge='replace'`（默认值），那么右侧哈希中的数组，将 “替换” 左侧哈希中的数组：


```yaml
default:
  a:
    - default
patch:
  a:
    - patch
```

```yaml
{{ default | combine(patch) }}
```


这将得到：


```yaml
a:
  - patch
```


而如果 `list_merge='keep'`，那么左侧哈希中的数组将被保留：


```yaml
{{ default | combine(patch, list_merge='keep') }}
```

这将得到：

```yaml
a:
  - default
```


如果 `list_merge='append'`，那么右侧哈希中的数组，将追加到左侧哈希中的那些：

```yaml
{{ default | combine(patch, list_merge='append') }}
```

这将得到：


```yaml
a:
  - default
  - patch
```

如果 `list_merge='prepend'`，那么右侧散列中的数组，将被添加到左侧散列中数组之前：

```yaml
{{ default | combine(patch, list_merge='prepend') }}
```

这将得到：


```yaml
a:
  - patch
  - default
```


如果 `list_merge='append_rp'`，那么右侧散列中的数组，将被追加到左侧散列中的数组。左侧哈希数组中的元素，如果也在右边哈希的相应数组中，则会被移除（“rp” 表示 “移除存在的，remove present”）。不同时存在于两个哈希的重复元素将被保留：


```yaml
default:
  a:
    - 1
    - 1
    - 2
    - 3
patch:
  a:
    - 3
    - 4
    - 5
    - 5
```

```yaml
{{ default | combine(patch, list_merge='append_rp') }}
```


这将得到：

```yaml
a:
  - 1
  - 1
  - 2
  - 3
  - 4
  - 5
  - 5
```

如果 `list_merge='prepend_rp'`，则行为与 `append_rp` 类似，但右侧散列中的数组元素会被添加在前面：


```yaml
{{ default | combine(patch, list_merge='prepend_rp') }}
```

这会得到：

```yaml
a:
  - 3
  - 4
  - 5
  - 5
  - 1
  - 1
  - 2
```


`recursive` 和 `list_merge` 可以一起使用：


```yaml
default:
  a:
    a':
      x: default_value
      y: default_value
      list:
        - default_value
  b:
    - 1
    - 1
    - 2
    - 3
patch:
  a:
    a':
      y: patch_value
      z: patch_value
      list:
        - patch_value
  b:
    - 3
    - 4
    - 4
    - key: value
```

```yaml
{{ default | combine(patch, recursive=True, list_merge='append_rp') }}
```


这将得到：


```yaml
a:
  a':
    x: default_value
    y: patch_value
    z: patch_value
    list:
      - default_value
      - patch_value
b:
  - 1
  - 1
  - 2
  - 3
  - 4
  - 4
  - key: value
```

### 从数组或哈希表中选取值


*版本 2.1 中新引入*。


`extract` 过滤器用于将索引列表，映射到容器（哈希或数组）中的值列表：


```yaml
{{ [0,2] | map('extract', ['x','y','z']) | list }}
{{ ['x','y'] | map('extract', {'x': 42, 'y': 31}) | list }}
```


上面的表达式的结果将是：


```console
['x', 'z']
[42, 31]
```


该过滤器可接受另一参数：


```yaml
{{ groups['x'] | map('extract', hostvars, 'ec2_ip_address') | list }}
```

这个表达式会获取组 “x” 中的主机列表，在 `hostvars` 中查找他们，然后查找结果中的 `ec2_ip_address`。最后得到的结果是组 “x” 中主机的 IP 地址列表。


该过滤器的第三个参数，也可以是个列表，以便在容器内进行递归查找：

```yaml
{{ ['a'] | map('extract', b, ['x','y']) | list }}
```

这将返回一个包含 `b['a']['x']['y']` 值的列表。


### 合并列表


这组过滤器会返回一个合并列表后的列表。


- `permutations`

获取某个列表的排列组合：


```yaml
- name: Give me the largest permutations (order matters)
  ansible.builtin.debug:
    msg: "{{ [1,2,3,4,5] | ansible.builtin.permutations | list }}"

- name: Give me permutations of sets of three
  ansible.builtin.debug:
    msg: "{{ [1,2,3,4,5] | permutations(3) | list }}"
```

> **译注**：可以看出，在 playbook 的 YAML 脚本中使用 `ansible.builtin` 专辑中的插件，可以省略 `ansible.builtin` 这个模组前缀。`ansible.builtin.debug` 这样的写法，成为完全限定专辑名称，Fully Qualified Collection Name, FQCN。以 FQCN 写出模组插件，可以容易的链接到该插件的文档，还可以避免与其他有着同样插件名称的专辑冲突。

- `combinations`


组合始终需要个固定的大小：


```yaml
- name: Give me combinations for sets of two
  ansible.builtin.debug:
    msg: "{{ [1,2,3,4,5] | ansible.builtin.combinations(2) | list }}"
```

另请参见 [`zip` 过滤器](https://docs.ansible.com/ansible/9/collections/ansible/builtin/zip_filter.html#zip-filter)。


- `products`


叉积过滤器返回输入迭代表的[笛卡尔积](https://docs.python.org/3/library/itertools.html#itertools.product)。这大致相当于生成器表达式中的嵌套 `for` 循环。


比如：

```yaml
- name: Generate multiple hostnames
  ansible.builtin.debug:
    msg: "{{ ['foo', 'bar'] | product(['com']) | map('join', '.') | join(',') }}"
```

这将得到：

```json
{ "msg": "foo.com,bar.com" }
```


### 选取 JSON 数据： JSON 查询


要从 JSON 格式的复杂数据结构（如 Ansible facts），选取某个元素或数据子集，就要使用 [`community.general.json_query`](https://docs.ansible.com/ansible/latest/collections/community/general/json_query_filter.html#ansible-collections-community-general-json-query-filter) 过滤器。`community.general.json_query` 过滤器允许咱们查询复杂的 JSON 结构，并使用某种循环结构，对其进行遍历。


> **注意**：此过滤器已迁移到 `community.general` 专辑。请按照安装说明，安装该专辑（`ansible-galaxy collection install community.general`）。

> **注意**：使用此过滤器前，咱们必须在 Ansible 控制节点上手动安装 `jmespath` 依赖项（`python -m pip install jmespath`）。此过滤器基于 `jmespath` 构建，因此咱们可以使用同样的语法。有关示例，请参阅 [`jmespath` 示例](https://jmespath.org/examples.html)。


设想下面这个数据结构：


```json
{{#include domain_definition.json:3:44}}
```


> **译注**：在 playbook YAML 文件中，可以使用 `vars`、~~`vars_files`~~ 关键字，分别定义变量，及从 JSON 文件中加载变量。下面是从一个 JSON 文件加载变量的示例。

```yaml
---
- name: Test filters
  hosts: nginx
  gather_facts: False
  vars:
    domain_definition: "{{ lookup('file', '../using/domain_definition.json') | from_json }}"

  tasks:

  ...
```

> 其中文件 `domain_definition.json` 是控制节点上的本地文件，在托管节点上无需该文件。
>
> 参考：
>
> - [`ansible-playbook` 变量定义与引用](https://www.cnblogs.com/liaojiafa/p/9353760.html)
>
> - [reading json like variable in ansible](https://stackoverflow.com/a/36730164)



要从该结构中提取所有集群，咱们可以使用以下查询：


```yaml
- name: Display all cluster names
  ansible.builtin.debug:
    var: item
  loop: "{{ domain_definition | community.general.json_query('domain.cluster[*].name') }}"
```

> **译注**：上面任务的输出为：

```json
ok: [debian_199] => (item=cluster1) => {
    "ansible_loop_var": "item",
    "item": "cluster1"
}
ok: [debian_199] => (item=cluster2) => {
    "ansible_loop_var": "item",
    "item": "cluster2"
}
```

要提取全部的服务器名字：


```yaml
- name: Display all server names
  ansible.builtin.debug:
    var: item
  loop: "{{ domain_definition | community.general.json_query('domain.server[*].name') }}"
```


要提取 `cluster1` 的端口：


```yaml
- name: Display all ports from cluster1
  ansible.builtin.debug:
    var: item
  loop: "{{ domain_definition | community.general.json_query(server_name_cluster1_query) }}"
  vars:
    server_name_cluster1_query: "domain.server[?cluster=='cluster1'].port"
```

> **译注**：这里就用到了 `jmespath` 查询语法。

> **注意**：咱们可以使用一个变量，提高查询的可读性。


以逗号分隔的字符串，打印出 `cluster1` 中的端口：


```yaml
- name: Display all ports from cluster1 as a string
  ansible.builtin.debug:
    msg: "{{ domain_definition | community.general.json_query(query_str) | join(', ') }}"
  vars:
    query_str: 'domain.server[?cluster==`cluster1`].port'
```

> **注意**：在上面的示例中，使用反引号（"`"）将字面量括起来，避免了对引号的转义，保持了可读性。
>
> **译注**：也可以写作：`query_str: "domain.server[?cluster=='cluster1'].port"`。

咱们可以使用 YAML 的 [单引号转义语法](https://yaml.org/spec/current.html#id2534365)：


```yaml
- name: Display all ports from cluster1
  ansible.builtin.debug:
    var: item
  loop: "{{ domain_definition | community.general.json_query('domain.server[?cluster==''cluster1''].port') }}"
```

> **注意**：在 YAML 中，在单引号内转义单引号的方法，是将单引号加倍。
>
> **译注**：测试发现该任务会因查询结果为空，而报出 `skipping` 结果。故上面这种写法值得商榷。

要获取包含某个集群所有端口和名称的哈希映射：

```yaml
- name: Display all server ports and names from cluster1
  ansible.builtin.debug:
    var: item
  loop: "{{ domain_definition | community.general.json_query(server_name_cluster1_query) }}"
  vars:
    server_name_cluster1_query: "domain.server[?cluster=='cluster1'].{name: name, port: port}"
```

要提取出所有集群中，名称以 `"server1"` 开头的所有端口：

```yaml
- name: Display ports from all clusters with the name starting with 'server1'
  ansible.builtin.debug:
    msg: "{{ domain_definition | to_json | from_json | community.general.json_query(server_name_query) }}"
  vars:
    server_name_query: "domain.server[?starts_with(name,'server1')].port"
```

> **注意**：在使用 `starts_with` 和 `contains` 时，为了正确解析数据结构，就必须使用 ` to_json | from_json ` 过滤器。


## 随机化数据

当咱们需要一个随机生成值时，就要使用下面这些过滤器之一。


### 随机的 MAC 地址


*版本 2.6 中新引入*。

该过滤器可用于从一个字符串前缀，生成随机 MAC 地址。

{{#include filters.md:919}}

从以 `'52:54:00'` 开头的字符串前缀，获取一个随机 MAC 地址：

```yaml
"{{ '52:54:00' | community.general.random_mac }}"
# => '52:54:00:ef:1c:03'
```

请注意，如果前缀字符串有任何错误，过滤器都将发出报错。

> **译注**：比如若提供的前缀字串为 `'52:5h:00'`，将报出如下错误：

```console
fatal: [debian_199]: FAILED! => {"msg": "Invalid value (52:5h:00) for random_mac: 5h not hexa byte"}
```


*版本 2.9 中新引入*。

从 Ansible 2.9 版开始，咱们还可以使用某个种子，初始化随机数生成器，从而创建出随机但幂等的 MAC 地址来，initialize the random number generator from a seed to create random-but-idempotent MAC addresses：

```yaml
"{{ '52:54:00' | community.general.random_mac(seed=inventory_hostname) }}"
```

### 随机条目或数字

Ansible 中的 `ansible.builtin.random` 过滤器，是个默认 Jinja2 `random` 过滤器的扩展，可用于从某个条目序列，返回一个随机条目，或根据范围生成一个随机数。

要从某个列表，获取一个随机条目：

```yaml
"{{ ['a','b','c'] | random }}"
# => 'c'
```

获取介于 `0`（包含）和指定整数（不包含）之间的随机数：

```yaml
"{{ 60 | random }} * * * * root /script/from/cron"
# => '21 * * * * root /script/from/cron'
```

要获取 `0` 到 `100` 之间的随机数，不过步长为 `10`：

```yaml
{{ 101 | random(step=10) }}
# => 70
```


要获取 `1` 到 `100` 之间的随机数，不过步长为 `10`：

```yaml
{{ 101 | random(start=1, step=10) }}
# => 31
```

咱们可以从某个种子，初始化随机数生成器，以创建随机但幂等的数字，random-but-idempotent numbers：

```yaml
"{{ 60 | random(seed=inventory_hostname) }} * * * * root /script/from/cron"
```

### 打乱列表


[`ansible.builtin.shuffle`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shuffle_filter.html#ansible-collections-ansible-builtin-shuffle-filter) 过滤器会随机化某个现有列表，每次调用都会给出不同的顺序。

从现有列表中获取随机列表：

```yaml
{{ ['a','b','c'] | shuffle }}
# => ['c','a','b']
{{ ['a','b','c'] | shuffle }}
# => ['b','c','a']
```

咱们可以自某个种子，初始化该生成器，以生成一种随机但幂等的顺序：

```yaml
{{ ['a','b','c'] | shuffle(seed=inventory_hostname) }}
# => ['b','a','c']
```

随机过滤器会尽可能返回一个列表。但如果咱们将其与一个非 “可列出” 项目使用，那么该过滤器就不会执行任何操作。


## 管理列表变量

您可以检索到某个列表中的最小值或最大值，或展开某个多级列表。

获取某个数字列表中的最小值：


```yaml
{{ list1 | min }}
```

*版本 2.11 中新引入*。

获取某个对象列表中的最小值：

```yaml
{{ [{'val': 1}, {'val': 2}] | min(attribute='val') }}
```

获取某个数字列表中的最大值：

```yaml
{{ [3, 4, 2] | max }}
```

*版本 2.11 中新引入*。


获取某个对象列表中的最大值：

```yaml
{{ [{'val': 1}, {'val': 2}] | max(attribute='val') }}
```

*版本 2.5 中新引入*。

展开某个列表（与 `flatten` 查找所做的一样）：


```yaml
{{ [3, [4, 2] ] | flatten }}
# => [3, 4, 2]
```


*版本 2.11 中新引入*。


保留列表中的空值，默认情况下，展开会移除他们：

```yaml
{{ [3, None, [4, [2]] ] | flatten(levels=1, skip_nulls=False) }}
# => [3, None, 4, [2]]
```


## 从集合或列表中选取（集合论）


咱们可以从集合或列表中，选取或组合某些项目。

*版本 1.4 中新引入*。


从列表中获取一个唯一集合（消除重复元素），a unique set from a list：


```yaml
# list1: [1, 2, 5, 1, 3, 4, 10]
{{ list1 | unique }}
# => [1, 2, 5, 3, 4, 10]
```


获取两个列表的交集（两个列表中所有项目的唯一列表）：


```yaml
# list1: [1, 2, 5, 3, 4, 10]
# list2: [1, 2, 3, 4, 5, 11, 99]
{{ list1 | intersect(list2) }}
# => [1, 2, 5, 3, 4]
```

获取两个列表的差值（1 中那些不存在于 2 中的项目）：


```yaml
# list1: [1, 2, 5, 1, 3, 4, 10]
# list2: [1, 2, 3, 4, 5, 11, 99]
{{ list1 | difference(list2) }}
# => [10]
```

## 数字计算（数学）


*版本 1.9 中新引入*。

咱们可以使用 Ansible 过滤器，计算数字的对数、幂和根。Jinja2 还提供了其他数学函数，如 `abs()` 和 `round()` 等。

获取对数（默认为 `e`）：


```yaml
{{ 8 | log }}
# => 2.0794415416798357
```


获取以 `10` 为底的对数：


```yaml
{{ 8 | log(10) }}
# => 0.9030899869919435
```


给我 `2!` 的幂(或 `5`）：

```yaml
{{ 8 | pow(5) }}
# => 32768.0
```

平方根或 5 次方根：

```yaml
{{ 8 | root }}
# => 2.8284271247461903

{{ 8 | root(5) }}
# => 1.5157165665103982
```


## 管理网络交互

这些过滤器可帮助咱们，完成常见的网络任务。

> **注意**：这些过滤器已迁移到 `ansible.utils` 专辑。请按照安装说明安装该专辑（`ansible-galaxy collection install ansible.utils`）。
>
> **译注**：此外还需要安装 Python `netaddr` 模组（`python -m pip install netaddr`）。


### IP 地址过滤器


*版本 1.9 中新引入*。

测试某个字符串，是否为有效 IP 地址：


```yaml
{{ myvar | ansible.utils.ipaddr }}
```

咱们还可以获取到特定 IP 协议版本：


```yaml
{{ myvar | ansible.utils.ipv4 }}
{{ myvar | ansible.utils.ipv6 }}
```


IP 地址过滤器还可用于从某个 IP 地址，提取特定信息。例如，要从某个 CIDR 获取 IP 地址本身，可以使用：

```yaml
{{ '192.0.2.1/24' | ansible.utils.ipaddr('address') }}
# => 192.0.2.1
```


关于 [`ansible.utils.ipaddr`](https://docs.ansible.com/ansible/latest/collections/ansible/utils/ipaddr_filter.html#ansible-collections-ansible-utils-ipaddr-filter) 过滤器的更多信息与完整使用指南，请参见 [Ansible.Utils](https://docs.ansible.com/ansible/latest/collections/ansible/utils/index.html#plugins-in-ansible-utils)。

> **译注**：上述文档中的信息已过时。比如要查询某个 IP 地址的网络地址，文档原文为：
>
```yaml
{{ '192.0.2.1/24' | ansible.utils.ipaddr('net') }}
```
> 新版本下应为：
```yaml
{{ '192.0.2.1/24' | ansible.utils.ipaddr('network') }}
```
> 查询某个 IP 地址网络规模，原文为：
```yaml
{{ '192.0.2.1/24' | ansible.utils.ipaddr('net') | ansible.utils.ipaddr('size') }}
```
> 新版本下应为：
```yaml
{{ '192.0.2.1/24' | ansible.utils.ipaddr('size') }}
```
>
> 需要引起注意。


### 网络 CLI 过滤器


*版本 2.4 中新引入*。


要将某个网络设备 CLI 命令的输出，转换为结构化的 JSON 输出，请使用 [`ansible.netcommon.parse_cli`](https://docs.ansible.com/ansible/latest/collections/ansible/netcommon/parse_cli_filter.html#ansible-collections-ansible-netcommon-parse-cli-filter) 过滤器：

```yaml
{{ output | ansible.netcommon.parse_cli('path/to/spec') }}
```

`ansible.netcommon.parse_cli` 过滤器将加载所指定的规格文件，并经由他传递命令输出，返回 JSON 输出。YAML 格式的规范文件，定义了如何解析 CLI 输出。

> **译注**：使用命令 `ansible-galaxy collection install ansible.netcommon` 安装 `ansible.netcommon` 专辑。

规格文件应时有效的 YAML 格式。他定义了如何解析 CLI 输出并返回 JSON 数据。下面是个解析 `show vlan` 命令输出的有效规格文件示例。


```yaml
---
vars:
  vlan:
    vlan_id: "{{ item.vlan_id }}"
    name: "{{ item.name }}"
    enabled: "{{ item.state != 'act/lshut' }}"
    state: "{{ item.state }}"

keys:
  vlans:
    value: "{{ vlan }}"
    items: "^(?P<vlan_id>\\d+)\\s+(?P<name>\\w+)\\s+(?P<state>active|act/lshut|suspended)"
  state_static:
    value: present
```

上面这个规格文件，将返回一个包含已解析 VLAN 信息哈希值列表的 JSON 数据结构。

使用 `key` 和 `values` 指令，同样的命令也可以解析为哈希值。下面是使用同样的 `show vlan` 命令，将输出解析为哈希值的示例。

```yaml
---
vars:
  vlan:
    key: "{{ item.vlan_id }}"
    values:
      vlan_id: "{{ item.vlan_id }}"
      name: "{{ item.name }}"
      enabled: "{{ item.state != 'act/lshut' }}"
      state: "{{ item.state }}"

keys:
  vlans:
    value: "{{ vlan }}"
    items: "^(?P<vlan_id>\\d+)\\s+(?P<name>\\w+)\\s+(?P<state>active|act/lshut|suspended)"
  state_static:
    value: present
```

解析 CLI 命令的另一个常见用例，是将大型命令分解成可以解析的块。使用 `start_block` 和 `end_block` 指令，就可以将命令分解成可解析的块。


```yaml
---
vars:
  interface:
    name: "{{ item[0].match[0] }}"
    state: "{{ item[1].state }}"
    mode: "{{ item[2].match[0] }}"

keys:
  interfaces:
    value: "{{ interface }}"
    start_block: "^Ethernet.*$"
    end_block: "^$"
    items:
      - "^(?P<name>Ethernet\\d\\/\\d*)"
      - "admin state is (?P<state>.+),"
      - "Port mode is (.+)"
```


上面的示例，将把 `show interface` 的输出解析为一个哈希值列表。

网络过滤器还支持使用 [TextFSM 库](https://github.com/google/textfsm)，解析 CLI 命令的输出。要使用 TextFSM 解析 CLI 输出，请使用以下过滤器：

```yaml
{{ output.stdout[0] | ansible.netcommon.parse_cli_textfsm('path/to/fsm') }}
```

使用 TextFSM 过滤器需要安装 TextFSM 库。

> **译注**：使用命令 `python -m pip install textfsm` 安装 TextFSM 库。


### 网络 XML 过滤器


*版本 2.5 中新引入*。


要将网络设备命令的 XML 输出，转换为结构化的 JSON 输出，请使用 [`ansible.netcommon.parse_xml`](https://docs.ansible.com/ansible/latest/collections/ansible/netcommon/parse_xml_filter.html#ansible-collections-ansible-netcommon-parse-xml-filter) 过滤器：


```yaml
{{ output | ansible.netcommon.parse_xml('path/to/spec') }}
```

`ansible.netcommon.parse_xml` 过滤器将加载所指定的规格文件，并以 JSON 格式传递命令输出。


规格文件应是有效的 YAML 格式。他定义了如何解析 XML 输出并返回 JSON 数据。


下面是个解析 `show vlan | display xml` 命令输出的有效规格文件示例。


```yaml
---
vars:
  vlan:
    vlan_id: "{{ item.vlan_id }}"
    name: "{{ item.name }}"
    desc: "{{ item.desc }}"
    enabled: "{{ item.state.get('inactive') != 'inactive' }}"
    state: "{% if item.state.get('inactive') == 'inactive'%} inactive {% else %} active {% endif %}"

keys:
  vlans:
    value: "{{ vlan }}"
    top: configuration/vlans/vlan
    items:
      vlan_id: vlan-id
      name: name
      desc: description
      state: ".[@inactive='inactive']"
```

上面的规范文件将返回一个，带有所解析 VLAN 信息哈希列表的 JSON 数据结构。

使用 `key` 和 `values` 指令，也可将同一命令解析为哈希值。下面是使用相同的 `show vlan | display xml` 命令，将输出解析为哈希值的示例。

```yaml
---
vars:
  vlan:
    key: "{{ item.vlan_id }}"
    values:
        vlan_id: "{{ item.vlan_id }}"
        name: "{{ item.name }}"
        desc: "{{ item.desc }}"
        enabled: "{{ item.state.get('inactive') != 'inactive' }}"
        state: "{% if item.state.get('inactive') == 'inactive'%} inactive {% else %} active {% endif %}"

keys:
  vlans:
    value: "{{ vlan }}"
    top: configuration/vlans/vlan
    items:
      vlan_id: vlan-id
      name: name
      desc: description
      state: ".[@inactive='inactive']"
```

其中 `top` 的值，是相对于 XML 根节点的 XPath 值。在下面给出的 XML 输出示例中，`top` 的值便是 `configuration/vlans/vlan`，这是个相对于根节点（`<rpc-reply>`）的 XPath 表达式。`top` 值中的 `configuration`，是最外层容器节点，`vlan` 则为最内层容器节点。


`items` 是个将用户定义的名称，映射到选择元素的 XPath 表达式的键值对字典。其中 Xpath 表达式是与 `top` 中所包含的 XPath 值相对的。例如，规格文件中的 `vlan_id`，是个用户定义的名称，其值 `vlan-id` 是相对于 `top` 中 XPath 值而言的。


使用 XPath 表达式，就可以提取出 XML 标记的属性。规格中 `state` 的值，是个用于获取输出 XML 中 `vlan` 标记属性的 XPath 表达式：

```xml
<rpc-reply>
  <configuration>
    <vlans>
      <vlan inactive="inactive">
       <name>vlan-1</name>
       <vlan-id>200</vlan-id>
       <description>This is vlan-1</description>
      </vlan>
    </vlans>
  </configuration>
</rpc-reply>
```

> **译注**：以下是解析上面所给出示例 XML 输出数据的 playbook YAML 文件。

```yaml
---
- name: Test filters
  hosts: nginx
  gather_facts: False
  vars:
    demo_xml: "{{ lookup('file', '../demo_output.xml') }}"

  tasks:
    - name: Gen random MAC addresses
      ansible.builtin.debug:
        msg: "{{ demo_xml | ansible.netcommon.parse_xml('/home/hector/ansible-tutorial/src/usage/playbook/demo_spec.yaml') }}"
```

> 运行后的输出为：

```json
ok: [debian_199] => {
    "msg": {
        "vlans": [
            {
                "desc": "This is vlan-1",
                "enabled": false,
                "name": "vlan-1",
                "state": " inactive ",
                "vlan_id": 200
            }
        ]
    }
}
```

> **注意**：有关所支持的 XPath 表达式更多信息，请参阅 [XPath 支持](https://docs.python.org/3/library/xml.etree.elementtree.html#xpath-support)。
>
> **译注**：
>
> - playbook 中设置变量可使用相对路径。可从文件加载字符串，赋值给 playbook 变量；
>
> - 所指定的规格文件，是在控制节点上，但需要使用绝对路径；
>
> - 下一步需要运用 GNS3，建立虚拟网络设备，才能实验 Ansible 对网络设备的控制。


### 网络 VLAN 过滤器


*版本 2.8 中新引入*。

使用 `ansible.netcommon.vlan_parser` 过滤器，可根据类似思科 IOS 的 VLAN 列表规则，将未排序的 VLAN 整数编号列表，转换为排序的整数字符串列表。该列表具有以下属性：

- Vlans 会按升序列出；
- 三个以上的连续 VLAN，会用破折号列出；
- 列表第一行的长度，可以是 `first_line_len` 个字符；
- 后续列表行可以是 `other_line_len` 个字符。


要排序某个 VLAN 列表：


```yaml
{{ [3003, 3004, 3005, 100, 1688, 3002, 3999] | ansible.netcommon.vlan_parser }}
```

此示例会渲染出以下排序后的列表：

```console
['100,1688,3002-3005,3999']
```

另一个 Jinja 模板示例：


```yaml
{% set parsed_vlans = vlans | ansible.netcommon.vlan_parser %}
switchport trunk allowed vlan {{ parsed_vlans[0] }}
{% for i in range (1, parsed_vlans | count) %}
switchport trunk allowed vlan add {{ parsed_vlans[i] }}
{% endfor %}
```

> **译注**：这个模板存在问题，应修改为下面这样才能如预期工作。

```yaml
{% set tmp = vlans | ansible.netcommon.vlan_parser %}
{% set parsed_vlans = tmp[0] | split(',') %}
switchport trunk allowed vlan {{ parsed_vlans[0] }}
{% for i in range (1, parsed_vlans | count) %}
switchport trunk allowed vlan add {{ parsed_vlans[i] }}
{% endfor %}
```

这样就可以动态生成某个 Cisco IOS 标记接口的 VLAN 列表。咱们可以保存某个接口所需的确切 VLAN 详尽原始列表，然后将其与配置所实际生成的 IOS 输出，解析出的列表进行比较。


## 字符串与口令的哈希计算与加密


*版本 1.9 中新引入*。


要获得某个字符串的 `sha1` 哈希值：


```yaml
{{ 'test1' | hash('sha1') }}
# => "b444ac06613fc8d63795be9ad0beaf55011936ac"
```


要获得某个字符串的 `md5` 哈希值：


```yaml
{{ 'test1' | hash('md5') }}
# => "5a105e8b9d40e1329780d62ea2265d8a"
```

获取某个字符串的校验和：

```yaml
{{ 'test2' | checksum }}
# => "109f4b3c50d7b0df729d299bc6f8e9ef9066971f"
```

其他哈希值（取决于平台）：


```yaml
{{ 'test2' | hash('blowfish') }}
```


> **译注**：在 Debian 上会报出如下错误：

```console
fatal: [debian_199]: FAILED! => {"msg": "unsupported hash type blowfish"}
```

> 在安装了 `passlib` 后即可支持 `blowfish` 哈希类型了。

要获取一个 `sha512` 的口令哈希值（随机盐化）：


```yaml
{{ 'passwordsaresecret' | password_hash('sha512') }}
# => "$6$UIv3676O/ilZzWEE$ktEfFF19NQPF2zyxqxGkAceTnbEgpEKuGBtk6MlU4v2ZorWaVQUMyurgmHCh2Fr4wpmQ/Y.AlXMJkRnIS4RfH/"
```


> **译注**：需要安装 `passlib` （`python -m pip install passlib`），否则会报出错误：

```console
fatal: [debian_199]: FAILED! => {"msg": "Unable to encrypt nor hash, passlib must be installed. No module named 'passlib'. Unable to encrypt nor hash, passlib must be installed. No module named 'passlib'"}
```

> 有意思的是，`passlib` 是在控制节点上安装的，但托管节点上也具备了此能力。


获取带有特定盐值的 `sha256` 口令哈希值：


```yaml
{{ 'secretpassword' | password_hash('sha256', 'mysecretsalt') }}
# => "$5$mysecretsalt$ReKNyDYjkKNqRVwouShhsEqZ3VOE8eoVO4exihOfvG4"
```

> **译注**：`sha256` 口令哈希的盐值，长度不大于 16，否则会报出错误：

```console
fatal: [debian_199]: FAILED! => {"msg": "Could not hash the secret.. salt too large (sha256_crypt requires <= 16 chars). Could not hash the secret.. salt too large (sha256_crypt requires <= 16 chars)"}
```

> 且指定盐值后的口令哈希值，是幂等的。


为每个系统生成唯一哈希值的一种幂等方法，是使用在历次运行过程中保持一致的盐值：


```yaml
{{ 'secretpassword' | password_hash('sha512', 65534 | random(seed=inventory_hostname) | string) }}
# => "$6$43927$lQxPKz2M2X.NWO.gK.t7phLwOKQMcSq72XxDZQ0XzYV6DlL1OD72h417aj16OnHTGxNzhftXJQBcjbunLEepM0"
```

可用的哈希类型，取决于运行 Ansible 的控制系统，[`ansible.builtin.hash`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/hash_filter.html#ansible-collections-ansible-builtin-hash-filter) 依赖于 [`hashlib`](https://docs.python.org/3.8/library/hashlib.html)，[`ansible.builtin.password_hash`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/password_hash_filter.html#ansible-collections-ansible-builtin-password-hash-filter) 依赖于 [`passlib`](https://passlib.readthedocs.io/en/stable/lib/passlib.hash.html)。如果没有安装 `passlib`，则会使用 [`crypt`](https://docs.python.org/3.8/library/crypt.html) 作为备用。



*版本 2.7 中新引入*。


某些哈希类型，允许提供轮数参数，a rounds parameter：

```yaml
{{ 'secretpassword' | password_hash('sha256', 'mysecretsalt', rounds=10000) }}
# => "$5$rounds=10000$mysecretsalt$Tkm80llAxD4YHll6AgNIztKn0vzAACsuuEfYeGP7tm7"
```

过滤器 `password_hash` 会根据是否安装了 `passlib`，而产生不同的结果。

为确保幂等性，请将 `rounds` 指定为既不是 `crypt` 的也不是 `passlib` 的默认值，其中 `crypt` 的默认值为 `5000`，`passlib` 的是个可变值（`sha256` 为 `535000`，`sha512` 为 `656000`）：

```yaml
{{ 'secretpassword' | password_hash('sha256', 'mysecretsalt', rounds=5001) }}
# => "$5$rounds=5001$mysecretsalt$wXcTWWXbfcR8er5IVf7NuquLvnUA6s8/qdtOhAZ.xN."
```

哈希类型 `blowfish`(BCrypt) 提供了指定 BCrypt 算法版本的设施。


```yaml
{{ 'secretpassword' | password_hash('blowfish', '1234567890123456789012', ident='2b') }}
# => "$2b$12$123456789012345678901uuJ4qFdej6xnWjOQT.FStqfdoY8dYUPC"
```

> **注意**：该参数仅适用于 [`blowfish` (BCrypt)](https://passlib.readthedocs.io/en/stable/lib/passlib.hash.bcrypt.html#passlib.hash.bcrypt)。其他哈希类型将忽略此参数。该参数的有效值为 `['2', '2a', '2y', '2b']`。


*版本 2.122 中新引入*。


咱们还可以使用 Ansible 的 [`ansible.builtin.vault`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/vault_filter.html#ansible-collections-ansible-builtin-vault-filter) 过滤器，来加密数据：

```yaml
# simply encrypt my key in a vault
vars:
  myvaultedkey: "{{ keyrawdata|vault(passphrase) }}"

- name: save templated vaulted data
  template: src=dump_template_data.j2 dest=/some/key/vault.txt
  vars:
    mysalt: '{{ 2**256|random(seed=inventory_hostname) }}'
    template_data: '{{ secretdata|vault(vaultsecret, salt=mysalt) }}'
```


然后使用 `unvault` 过滤器，将其解密：


```yaml
# simply decrypt my key from a vault
vars:
  mykey: "{{ myvaultedkey|unvault(passphrase) }}"

- name: save templated unvaulted data
  template: src=dump_template_data.j2 dest=/some/key/clear.txt
  vars:
    template_data: '{{ secretdata|unvault(vaultsecret) }}'
```

## 操作文本


有几种过滤器可处理文本，包括 URL、文件名和路径名。

### 往文件添加注释


`ansible.builtin.comment` 过滤器允许咱们根据某个模板中的文本，在某个文件中创建具有多种注释样式的注释。默认情况下，Ansible 使用 `#` 开始注释行，并在注释文本的上方和下方添加空白注释行。例如以下内容：

```yaml
{{ "Plain style (default)" | comment }}
```

会产生这样的输出：


```yaml
#
# Plain style (default)
#
```

Ansible 提供了 C (`//...`)、C 块 (`/*...*/`)、Erlang (`%...`) 和 XML (`<!--...-->`) 样式的注释：


```yaml
{{ "C style" | comment('c') }}
{{ "C block style" | comment('cblock') }}
{{ "Erlang style" | comment('erlang') }}
{{ "XML style" | comment('xml') }}
```


咱们可以自定义注释字符。下面这个过滤器：

```yaml
{{ "My Special Case" | comment(decoration="! ") }}
```


会产生：


```yaml
!
! My Special Case
!
```

咱们可以整个地定制注释样式：

```yaml
{{ "Custom style" | comment('plain', prefix='#######\n#', postfix='#\n#######\n   ###\n    #') }}
```


这将创建出下面的输出：


```yaml
#######
#
# Custom style
#
#######
   ###
    #
```


该过滤器还可以应用到任何的 Ansible 变量。例如，为了让 `ansible_managed` 变量的输出更易读，我们可以将 `ansible.cfg` 文件中的该定义，改为这样：

```yaml
[defaults]

ansible_managed = This file is managed by Ansible.%n
  template: {file}
  date: %Y-%m-%d %H:%M:%S
  user: {uid}
  host: {host}
```

然后将变量与 `comment` 过滤器一起使用：


```yaml
{{ ansible_managed | comment }}
```


这将产生下面的输出：


```yaml
#
# This file is managed by Ansible.
#
# template: /home/ansible/env/dev/ansible_managed/roles/role1/templates/test.j2
# date: 2015-09-10 11:02:58
# user: ansible
# host: myhost
#
```


### 将变量编码为 URL


`urlencode` 过滤器使用 UTF-8，将数据转换为在 URL 路径或查询中使用的格式：


```yaml
{{ 'Trollhättan' | urlencode }}
# => 'Trollh%C3%A4ttan'
```


### 切分 URL

*版本 2.3 中新引入*。

`ansible.builtin.urlsplit` 过滤器会从某个 URL 中，提取出片段、主机名、`netloc`<sup>1</sup>、口令、路径、端口、查询字串、所用协议方案及用户名等。如果没有参数，则返回包含所有这些字段的字典：

> **译注**：`netloc` 是指 URL 中的网络位置。
>
> 参考：[What does netloc mean?](https://stackoverflow.com/a/53993037)


```yaml
{{ "http://user:password@www.acme.com:9000/dir/index.html?query=term#fragment" | urlsplit('hostname') }}
# => 'www.acme.com'

{{ "http://user:password@www.acme.com:9000/dir/index.html?query=term#fragment" | urlsplit('netloc') }}
# => 'user:password@www.acme.com:9000'

{{ "http://user:password@www.acme.com:9000/dir/index.html?query=term#fragment" | urlsplit('username') }}
# => 'user'

{{ "http://user:password@www.acme.com:9000/dir/index.html?query=term#fragment" | urlsplit('password') }}
# => 'password'

{{ "http://user:password@www.acme.com:9000/dir/index.html?query=term#fragment" | urlsplit('path') }}
# => '/dir/index.html'

{{ "http://user:password@www.acme.com:9000/dir/index.html?query=term#fragment" | urlsplit('port') }}
# => '9000'

{{ "http://user:password@www.acme.com:9000/dir/index.html?query=term#fragment" | urlsplit('scheme') }}
# => 'http'

{{ "http://user:password@www.acme.com:9000/dir/index.html?query=term#fragment" | urlsplit('query') }}
# => 'query=term'

{{ "http://user:password@www.acme.com:9000/dir/index.html?query=term#fragment" | urlsplit('fragment') }}
# => 'fragment'

{{ "http://user:password@www.acme.com:9000/dir/index.html?query=term#fragment" | urlsplit }}
# =>
#   {
#       "fragment": "fragment",
#       "hostname": "www.acme.com",
#       "netloc": "user:password@www.acme.com:9000",
#       "password": "password",
#       "path": "/dir/index.html",
#       "port": 9000,
#       "query": "query=term",
#       "scheme": "http",
#       "username": "user"
#   }
```


### 使用正则表达式检索字符串

要使用正则表达式，在字符串中检索，或提取字符串的部分内容，请使用 `ansible.builtin.regex_search` 过滤器：


```yaml
# 从某个字符串提取出数据库名
{{ 'server1/database42' | regex_search('database[0-9]+') }}
# => 'database42'

# 多行模式下不区分大小写的检索示例
{{ 'foo\nBAR' | regex_search('^bar', multiline=True, ignorecase=True) }}
# => 'BAR'

# 使用内联 regex 开关，在多行模式下进行大小写不敏感检索的示例
{{ 'foo\nBAR' | regex_search('(?im)^bar') }}
# => 'BAR'

# 从某个字符串提取出服务器和数据库 ID 的示例
{{ 'server1/database42' | regex_search('server([0-9]+)/database([0-9]+)', '\\1', '\\2') }}
# => ['1', '42']

# 从某个除法表达式提取出除数和被除数的示例
{{ '21/42' | regex_search('(?P<dividend>[0-9]+)/(?P<divisor>[0-9]+)', '\\g<dividend>', '\\g<divisor>') }}
# => ['21', '42']
```


如果找不到匹配项，` ansible.builtin.regex_search` 过滤器就会返回空字符串：

```yaml
{{ 'ansible' | regex_search('foobar') }}
# => ''
```


> **注意**：在 Jinja 表达式中使用时（例如与运算符、其他过滤器等结合使用时），`ansible.builtin.regex_search` 过滤器会返回 None。请参阅下面两个示例。

```yaml
{{ 'ansible' | regex_search('foobar') == '' }}
# => False
{{ 'ansible' | regex_search('foobar') is none }}
# => True
```


> 这是由于历史原因，以及在 Ansible 中一些 Jinja 内部结构的定制重新实现。如果希望 `ansible.builtin.regex_search` 过滤器，在无法找到匹配时始终返回 `None`，就要启用 `jinja2_native` 设置。详情请参阅 [为什么 `regex_search` 过滤器返回 `None` 而不是空字符串？](https://docs.ansible.com/ansible/latest/reference_appendices/faq.html#jinja2-faqs)


要提取出某个字符串中，所有 regex 匹配项，请使用 [`ansible.builtin.regex_findall`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/regex_findall_filter.html#ansible-collections-ansible-builtin-regex-findall-filter) 过滤器：


```yaml
# 返回某个字符串中全部 IPV4 地址的清单
{{ 'Some DNS servers are 8.8.8.8 and 8.8.4.4' | regex_findall('\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b') }}
# => ['8.8.8.8', '8.8.4.4']

# 返回全部以 "ar" 结束的行
{{ 'CAR\ntar\nfoo\nbar\n' | regex_findall('^.ar$', multiline=True, ignorecase=True) }}
# => ['CAR', 'tar', 'bar']

# 使用多行和忽略大小写的内联正则表达式开关，返回以 “ar” 结尾的所有行
{{ 'CAR\ntar\nfoo\nbar\n' | regex_findall('(?im)^.ar$') }}
# => ['CAR', 'tar', 'bar']
```

要使用正则表达式替换某个字符串中的文本，请使用 [`ansible.builtin.regex_replace`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/regex_replace_filter.html#ansible-collections-ansible-builtin-regex-replace-filter) 过滤器：

```yaml
# 将 "ansible" 转化为 "able"
{{ 'ansible' | regex_replace('^a.*i(.*)$', 'a\\1') }}
# => 'able'

# 将 "foobar" 转化为 "bar"
{{ 'foobar' | regex_replace('^f.*o(.*)$', '\\1') }}
# => 'bar'

# 使用命名分组，将 “localhost:80” 转换为 "localhost, 80"
{{ 'localhost:80' | regex_replace('^(?P<host>.+):(?P<port>\\d+)$', '\\g<host>, \\g<port>') }}
# => 'localhost, 80'

# 将 "localhost:80" 转化为 "localhost"
{{ 'localhost:80' | regex_replace(':80') }}
# => 'localhost'

# 注释掉全部以 "ar" 结束的行
{{ 'CAR\ntar\nfoo\nbar\n' | regex_replace('^(.ar)$', '#\\1', multiline=True, ignorecase=True) }}
# => '#CAR\n#tar\nfoo\n#bar\n'

# 使用多行和忽略大小写的内联 regex 开关，注释掉所有以 “ar ”结尾的行
{{ 'CAR\ntar\nfoo\nbar\n' | regex_replace('(?im)^(.ar)$', '#\\1') }}
# => '#CAR\n#tar\nfoo\n#bar\n'
```

> **注意**：如果咱们打算匹配整个字符串，且使用了 `*`，那么就要确保咱们的正则表达式，始终要有开始/结束锚点。例如，`^(.*)$` 将始终只匹配一个结果，而 `(.*)` 在某些 Python 版本中，将匹配整个字符串和结尾的空字符串，这意味着他将进行两次替换：

```yaml
# 将 "https://" 前缀，添加到某个列表全部条目
GOOD:
{{ hosts | map('regex_replace', '^(.*)$', 'https://\\1') | list }}
{{ hosts | map('regex_replace', '(.+)', 'https://\\1') | list }}
{{ hosts | map('regex_replace', '^', 'https://') | list }}

BAD:
{{ hosts | map('regex_replace', '(.*)', 'https://\\1') | list }}

# 将 ':80' 追加到某个列表的全部条目
GOOD:
{{ hosts | map('regex_replace', '^(.*)$', '\\1:80') | list }}
{{ hosts | map('regex_replace', '(.+)', '\\1:80') | list }}
{{ hosts | map('regex_replace', '$', ':80') | list }}

BAD:
{{ hosts | map('regex_replace', '(.*)', '\\1:80') | list }}
```

> **注意**：在 Ansible 2.0 前，如果 `ansible.builtin.regex_replace` 过滤器用于 YAML 参数内部的变量（而不是更简单的 `'key=value'` 参数），则需要用 4 个反斜线 (`\\\\`) 而不是 2 个 (`\\`) ，来转义反向引用，backreferences（例如，`\\1`）。



*版本 2.0 中新引入*。

要转义某个标准 Python 正则表达式中的特殊字符，请使用 `ansible.builtin.regex_escape` 过滤器（使用默认的 `re_type='python'` 选项）：


```yaml
# 将 '^f.*o(.*)$' 转换为 '\^f\.\*o\(\.\*\)\$'
{{ '^f.*o(.*)$' | regex_escape() }}
```


*版本 2.8 中新引入*。


要转义某个 POSIX 基本正则表达式中的特殊字符，请使用带 `re_type='posix_basic'` 选项的 `ansible.builtin.regex_escape` 过滤器：

```yaml
# 将 '^f.*o(.*)$' 转化为 '\^f\.\*o(\.\*)\$'
{{ '^f.*o(.*)$' | regex_escape('posix_basic') }}
```


### 管理文件名与路径名


要获取某个文件路径最后的名字，例如 `"/etc/asdf/foo.txt"` 中的 `"foo.txt"`：


```yaml
{{ path | basename }}
```


获取 Windows 风格文件路径中最后的名字（2.0 版新增）：


```yaml
{{ path | win_basename }}
```

将 Windows 驱动器号与文件路径的其他部分分离（2.0 版新增）：

```yaml
{{ path | win_splitdrive}}
```

只获取 Windows 驱动器代号：


```yaml
{{ path | win_splitdrive | first }}
```

要获得不含驱动器代号的路径其余部分：

```yaml
{{ path | win_splitdrive | last }}
```

从某个路径获取目录：

```yaml
{{ path | dirname }}
```


获取某个 Windows 路径的目录（版本 2.0 新增）：


```yaml
{{ path | win_dirname }}
```


展开某个包含波形符 (`~`) 字符的路径（1.5 版新增）：

```yaml
{{ path | expanduser }}
```

展开某个包含环境变量的路径：


```yaml
{{ path | expandvars }}
```

> **注意**：`expandvars` 展开的是本地变量；在远程路径上使用会导致错误。


*版本 2.6 中新引入*。

获取某个（软）链接的真实路径（1.8 版新增）：

```yaml
{{ path | realpath }}
```

要获取某个链接的相对路径，从某个起点开始（1.7 版中的新功能）：

```yaml
{{ path | relpath('/etc') }}
```


获取某个路径或文件名的根及扩展名（2.0 版新增）：


```yaml
# with path == 'nginx.conf' the return would be ('nginx', '.conf')
{{ path | splitext }}
```

`ansible.builtin.splitext` 过滤器会始终返回一对字符串。可以使用 `first` 和 `last` 过滤器，访问单个组件：

```yaml
# with path == 'nginx.conf' the return would be 'nginx'
{{ path | splitext | first }}

# with path == 'nginx.conf' the return would be '.conf'
{{ path | splitext | last }}
```


连接一或多个路径组件：


```yaml
{{ ('/etc', path, 'subdir', file) | path_join }}
```

> **译注**：若 `path='/nginx'`，`file='nginx.conf'`，上面的表达式结果为：

```console
"/nginx/subdir/nginx.conf"
```

> 若 `path='nginx/'`，`file='nginx.conf'`，上面的表达式结果为：

```console
"/etc/nginx/subdir/nginx.conf"
```

> 说明 `path_join` 过滤器，在连接组成路径时，有特别之处。


*版本 2.3 中新引入*。

## 操作字符串


为 shell 用途添加引号：

```yaml
- name: Run a shell command
  ansible.builtin.shell: echo {{ string_value | quote }}
```


（文档：[`ansible.builtin.quote`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/quote_filter.html#ansible-collections-ansible-builtin-quote-filter)）


将某个列表连接成一个字符串：

```yaml
{{ list | join(' ') }}
```

将某个字符串切分为一个列表：

```yaml
{{ csv_string | split(',') }}
```


*版本 2.3 中新引入*。

处理 Base64 编码的字符串：

```yaml
{{ encoded | b64decode }}
{{ decoded | string | b64encode }}
```

（文档：[`ansible.builtin.b64encode`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/b64encode_filter.html#ansible-collections-ansible-builtin-b64encode-filter)）

从 2.6 版开始，咱们可以定义要使用的编码类型，默认为 `utf-8`：


```yaml
{{ encoded | b64decode(encoding='utf-16-le') }}
{{ decoded | string | b64encode(encoding='utf-16-le') }}
```

（文档：[`ansible.builtin.b64decode`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/b64decode_filter.html#ansible-collections-ansible-builtin-b64decode-filter)）


> **注意**：只有 Python 2 才需要 `string` 过滤器，他可以确保要编码文本是 unicode 字符串。如果在 `b64encode` 之前没有使用该过滤器，就会编码出错误的值。

> **注意**：`b64decode` 的返回值是个字符串。如果咱们使用 `b64decode`，对某个二进制文件解密，然后尝试使用他（例如使用 [`copy` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html#copy-module) 将其写入某个文件），则很可能会发现该二进制文件已损坏。如果咱们需要将 `base64` 编码的二进制文件写入磁盘，最好通过 [`shell` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html#shell-module)，使用系统的 `base64` 命令，并使用 `stdin` 参数，经由管线输入编码的数据。例如： `shell: cmd="base64 --decode > myfile.binr" stdin="{{ encoded }}"`。



*版本 2.3 中新引入*。


## 管理 UUID


要创建一个带命名空间的 UUIDv5：

```yaml
{{ string | to_uuid(namespace='11111111-2222-3333-4444-555555555555') }}
```

> **译注**：上面示例中的 `namespace` 参数必须满足这样的格式，否则会报出如下错误。

```console
fatal: [debian_199]: FAILED! => {"msg": "Invalid value '11111111-2222-3333-4444-55555555555' for 'namespace': badly formed hexadecimal UUID string"}
```


*版本 2.10 中新引入*。

使用默认的 Ansible 命名空间 `"361E6D51-FAEC-444A-9079-341386DA8E2E"`，创建一个带命名空间的 UUIDv5：


```yaml
{{ string | to_uuid }}
```


*版本 1.9 中新引入*。


要利用某个复杂变量列表中，每个条目的一项属性，请使用 [Jinja2 的 `map` 过滤器](https://jinja.palletsprojects.com/en/stable/templates/#jinja-filters.map)：


```yaml
# 获取某台主机上以逗号分隔的挂载点（例如 `"/,/mnt/stuff"）列表
{{ ansible_mounts | map(attribute='mount') | join(',') }}
```
<a name="ansible_mounts"></a>
> **译注**：`ansible_mounts` 这个变量，在执行 `ansible.builtin.setup` 的 `gather_subset` 任务后可用。


```yaml
    - name: Gathering mounts
      setup:
        gather_subset:
          - mounts

    - name: Get a comma-separated list of the mount points
      debug:
        msg: "{{ ansible_mounts | map(attribute='mount') | join(',') }}"
```

> 同时 `gather_subset` 还可以收集托管机器的其他信息，如 `distribution` -> `ansible_distribution`。


## 处理日期及时间


要从某个字符串，获取到一个日期对象，请使用 `to_datetime` 过滤器：


```yaml
# 获取两个日期之间的总秒数。默认日期格式为 `%Y-%m-%d %H:%M:%S`，但咱们也可以传递自己的格式
{{ (("2016-08-14 20:00:12" | to_datetime) - ("2015-12-25" | to_datetime('%Y-%m-%d'))).total_seconds()  }}

# 获取已计算了 delta 后的剩余秒数。注意：这不会将年、日、小时等转换为秒。为此，请使用 `total_seconds()`
{{ (("2016-08-14 20:00:12" | to_datetime) - ("2016-08-14 18:00:00" | to_datetime)).seconds  }}
# 此表达式会得出 "12" 而不是 "132"。其中 Delta 为两小时 12 秒

# 获取两个日期之间的天数。这只会返回天数，而丢弃剩余的小时、分钟和秒。
{{ (("2016-08-14 20:00:12" | to_datetime) - ("2015-12-25" | to_datetime('%Y-%m-%d'))).days  }}
```

> **注意**：有关处理 Python 日期格式字符串的格式代码的完整列表，请参阅 [Python `datetime` 文档](https://docs.python.org/3/library/datetime.html#strftime-and-strptime-behavior)。


*版本 2.3 中新引入*。

要使用字符串对某个日期进行格式化（如使用 shell 的 `date` 命令那样），请使用 `strftime` 过滤器：


```yaml
# 显示 年-月-日
{{ '%Y-%m-%d' | strftime }}
# => "2021-03-19"

# 显示 时:分:秒
{{ '%H:%M:%S' | strftime }}
# => "21:51:04"

# 使用 ansible_date_time.epoch 这个事实
{{ '%Y-%m-%d %H:%M:%S' | strftime(ansible_date_time.epoch) }}
# => "2021-03-19 21:54:09"

# Use arbitrary epoch value
# 使用任意的纪元值
{{ '%Y-%m-%d' | strftime(0) }}          # => 1970-01-01
{{ '%Y-%m-%d' | strftime(1441357287) }} # => 2015-09-04
```


*版本 2.13 中新引入*。

`strftime` 回取个可选的 `utc` 参数，默认为 `False`，表示时间使用的是本地时区：

```yaml
{{ '%H:%M:%S' | strftime }}           # time now in local timezone
{{ '%H:%M:%S' | strftime(utc=True) }} # time now in UTC
```

> **注意**：要获悉所有字符串的可能性，请查看 https://docs.python.org/3/library/time.html#time.strftime


## 获取 K8s 的资源名字

> **注意**：这些过滤器已迁移到 [`kubernetes.core` 专辑](https://galaxy.ansible.com/kubernetes/core)。请按照安装说明安装该专辑（`ansible-galaxy collection install kubernetes.core`）。

使用 `k8s_config_resource_name` 过滤器，获取某个 K8s `ConfigMap` 或 `Secret` 的名称，包括其哈希值：


```yaml
{{ configmap_resource_definition | kubernetes.core.k8s_config_resource_name }}
```

这样就可用于引用 Pod 规范中的那些哈希值了：


```yaml
my_secret:
  kind: Secret
  metadata:
    name: my_secret_name

deployment_resource:
  kind: Deployment
  spec:
    template:
      spec:
        containers:
        - envFrom:
            - secretRef:
                name: {{ my_secret | kubernetes.core.k8s_config_resource_name }}
```

*版本 2.8 中新引入*。
