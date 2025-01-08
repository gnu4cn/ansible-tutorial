# 使用过滤器来操作数据

过滤器可让咱们将 JSON 数据转换为 YAML 数据、切分 URL 来提取主机名、获取字符串的 SHA1 哈希值、对整数进行加法或乘法运算，等等。咱们可以使用这里所记录的特定于 Ansible 的过滤器，来处理数据，也可以使用 Jinja2 提供的任何标准过滤器 -- 请参阅 Jinja2 官方模板文档中的 [内置过滤器](https://jinja.palletsprojects.com/en/stable/templates/#builtin-filters) 列表。咱们也可以使用 [Python 的方法](https://jinja.palletsprojects.com/en/stable/templates/#python-methods) 来转换数据。咱们可以插件方式，[创建自定义的 Ansible 过滤器](../../dev_guide/plugins.md)，不过我们通常欢迎将新的过滤器，放到 `ansible-core` 的源码仓库中，以便每个人都能使用他们。


由于模板化发生在 Ansible 控制节点上，而非目标主机上，因此过滤器是在控制节点上执行，并在本地转换数据。


## 处理未定义的变量

通过提供默认值或使某些变量成为可选，过滤器可以帮助咱们管理缺失或未定义的变量。如果咱们将 Ansible 配置为了忽略大多数未定义变量，则可以使用 `mandatory` 过滤器，将某些变量标记为必需值。


### 提供默认值

使用 Jinja2 的 `default` 过滤器，咱们就可以直接在模板中为变量提供默认值。与在因某个变量为定义而失败相比，这是种更好的方案：

```jinja
{{ some_variable | default(5) }}
```

在上面的示例中，如果变量 `some_variable` 未被定义，那么 Ansible 会使用默认值 `5`，而不是抛出 `undefined variable` 错误并导致失败。如果咱们在某个角色中工作，也可以添加一些为咱们角色中变量，定义默认值的角色默认值。要了解有关角色默认值的更多信息，请参阅 [角色目录结构](../roles.md)。


从 2.8 版开始，在 Jinja 中尝试访问某个未定义值的属性时，将返回另一未定义值，而不是立即抛出错误。这意味着在咱们不知道中间值是否已定义的情况下，现在可以在某个嵌套数据结构中，简单地使用默认值了（也即是 `{{ foo.bar.baz | default('DEFAULT') }}`）。

若咱们打算在变量求值为 `false` 或空字符串时使用默认值，则必须将第二个参数设置为 `true`：


```jinja
{{ lookup('env', 'MY_USER') | default('admin', true) }}
```

### 将变量标记为可选


默认情况下，Ansible 需要模板表达式中所有变量的值。不过，咱们可以将特定的模组变量，设置为可选。例如，咱们可能想对某些项目使用系统默认值，并控制其他项目的值。要使某个模组变量成为可选，就要将默认值，设置为特殊变量 `omit`：

```jinja
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


```jinja
{{ variable | mandatory }}
```

变量值将按原样使用，但如果其未被定义，那么模板的求值将抛出一个错误。

要求某个变量被覆盖的一种便捷方法，是使用 `undef()` 函数为其赋予一个未定义的值。


```jinja
galaxy_url: "https://galaxy.ansible.com"
galaxy_api_key: "{{ undef(hint='You must specify your Galaxy API key') }}"
```


## 为 `true`/`false`/`null` 定义不同值（`ternary`）


咱们可以创建个测试，然后定义一个在该测试返回 `true` 时使用的值，另一个在返回 `false` 时使用（1.9 版新增）：


```jinja
{{ (status == 'needs_restart') | ternary('restart', 'continue') }}
```

此外，咱们还可以定义一个在 `true` 时使用的值，一个在 `false` 时使用的值，以及第三个在 `null` 时使用的值（2.8 版新增）：


```jinja
{{ enabled | ternary('no shutdown', 'shutdown', omit) }}
```


## 管理数据类型

咱们可能需要了解、修改或设置某个变量的数据类型。例如，当咱们的下一任务需要某个列表时，某个注册变量却可能包含著一个字典；当咱们的 playbook 需要一个布尔值时，用户 [输入提示符](prompts.md) 却可能返回个字符串。请使用 [`ansible.builtin.type_debug`](../../../collections/ansible_builtin.md)、[`ansible.builtin.dict2items`](../../../collections/ansible_builtin.md) 以及 [`ansible.builtin.items2dict`](../../../collections/ansible_builtin.md) 过滤器，管理数据类型。咱们也可以使用数据类型本身，将某个值转换为指定数据类型。


### 发现数据类型


*版本 2.3 中新引入*。

若咱们不确定某个变量的地层 Python 类型，可以使用 `ansible.builtin.type_debug` 过滤器来将其显示出来。这对咱们需要某个特定类型变量时的调试很有用：

```jinja
{{ myvar | type_debug }}
```

需要注意的是，虽然这看起来像是个，可以用来检查某个变量中的数据类型是否正确的有用过滤器，但咱们通常更喜欢 [类型测试](tests.md)，他允许咱们测试出特定数据类型。

### 将字符串转换为列表

使用 [`ansible.builtin.split`](../../../collections/ansible_builtin.md) 过滤器，将字符/字符串分隔的字符串，转换为适合 [循环](loops.md) 的项目列表。例如，如果咱们打算切分一个以逗号分隔的字符串变量 `fruits`，就可以使用：

```jinja
{{ fruits | split(',') }}
```

字符串数据（在应用 `ansible.builtin.split` 过滤器前）：

```jinja
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

```jinja
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


```jinja
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


```jinja
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


```jinja
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
