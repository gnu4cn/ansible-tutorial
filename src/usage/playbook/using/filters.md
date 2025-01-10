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



