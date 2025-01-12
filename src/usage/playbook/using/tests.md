# 测试判断

Jinja 中的 [测试](https://jinja.palletsprojects.com/en/latest/templates/#tests)，是种对模板表达式求值，并返回 `True` 或 `False` 的方法。Jinja 提供了许多这样的测试。请参阅 Jinja 模板官方文档中的 [内置测试](https://jinja.palletsprojects.com/en/latest/templates/#builtin-tests)。

测试与过滤器的主要区别在于，Jinja 的测试用于比较，而过滤器则用于数据处理，两者在 Jinja 中有着不同的应用。测试也可用于列表处理过滤器，如 `map()` 和 `select()`，就可以选取列表中的条目。

与所有模板一样，测试总是在 Ansible 控制节点上执行，而非在任务的目标上，因为他们测试的是本地数据。


除了这些 Jinja2 测试外，Ansible 还提供了少量别的测试，同时用户也可以轻松创建自己的测试。


## 测试语法

测试语法不同于过滤器语法（`variable | filter`）。Ansible 一直将测试同时注册为 jinja 测试和 jinja 过滤器，允许使用过滤器语法引用他们。

从 Ansible 2.5 起，将某个 jinja 测试作为过滤器使用，会产生一条弃用警告消息。从 Ansible 2.9 起，就必须使用 jinja 测试语法了。


使用 jinja 测试的语法如下：

```yaml
variable is test_name
```

比如：

```yaml
result is failed
```


## 测试字符串

要将字符串与某个子字符串，或某个正则表达式进行匹配，请使用 `match`、`search` 或 `regex` 测试。

```yaml
vars:
  url: "https://example.com/users/foo/resources/bar"

tasks:
    - debug:
        msg: "matched pattern 1"
      when: url is match("https://example.com/users/.*/resources")

    - debug:
        msg: "matched pattern 2"
      when: url is search("users/.*/resources/.*")

    - debug:
        msg: "matched pattern 3"
      when: url is search("users")

    - debug:
        msg: "matched pattern 4"
      when: url is regex("example\.com/\w+/foo")
```

如果在字符串的开头找到所指定的模式，则 `match` 就会成功；而如果在字符串的任何位置找到了所指定的模式，则 `search` 就会成功。默认情况下，`regex` 的工作方式与 `search` 类似，但通过传递 `match_type` 关键字参数，`regex` 也可以配置为执行其他测试。其中，`match_type` 决定了用于执行搜索的 `re` 方式。`re` 方式的完整列表，可以在 [这里](https://docs.python.org/3/library/re.html#regular-expression-objects) 的相关 Python 文档中找到。

所有字符串测试，还可取得 `ignorecase` 和 `multiline` 两个参数。这两个参数分别对应 Python `re` 库中的 `re.I` 和 `re.M`。

## 保险库

*版本 2.10 中的新特性*。

使用 `vault_encrypted` 测试，咱们可以测试某个变量是否为内联的单一保险库加密值。

```yaml
vars:
  variable: !vault |
    $ANSIBLE_VAULT;1.2;AES256;dev
    61323931353866666336306139373937316366366138656131323863373866376666353364373761
    3539633234313836346435323766306164626134376564330a373530313635343535343133316133
    36643666306434616266376434363239346433643238336464643566386135356334303736353136
    6565633133366366360a326566323363363936613664616364623437336130623133343530333739
    3039

tasks:
  - debug:
      msg: '{{ (variable is vault_encrypted) | ternary("Vault encrypted", "Not vault encrypted") }}'
```

> **译注**： 此例中用到了 playbook YAML 文件中多行文本的写法。

## 测试真伪


*版本 2.10 中的新特性*。


从 Ansible 2.10 起，咱们现在可以执行类似 Python 的 `truthy` 与 `falsy` 检查。

```yaml
    - debug:
        msg: "Truthy"
      when: value is truthy
      vars:
        value: "some string"

    - debug:
        msg: "Falsy"
      when: value is falsy
      vars:
        value: ""
```

此外，`truthy` 和 `falsy` 测试还接受一个名为 `convert_bool` 的可选参数，将尝试将布尔的指示符，转换为实际布尔值。

```yaml
    - debug:
        msg: "Truthy"
      when: value is truthy(convert_bool=True)
      vars:
        value: "yes"

    - debug:
        msg: "Falsy"
      when: value is falsy(convert_bool=True)
      vars:
        value: "off"
```

## 版本比较


*版本 1.6 中的新特性*。

> **注意**：在版本 2.5 中，`version_compare` 被更名为了 `version`


要比较某个版本号，例如检查 `ansible_facts['distribution_version']` 的版本号，是否大于或等于 `'12.04'`，咱们可以使用 `version` 测试。

`version` 测试也可用于对 `ansible_facts['distribution_version']` 求值。

```yaml
{{ ansible_facts['distribution_version'] is version('12.04', '>=') }}
```

如果 `ansible_facts['distribution_version']` 大于或等于 `12.04`，此测试就会返回 `True`，否则返回 `False`。

> **译注**：类似于上一小节中的 [`ansible_mounts`](filters.md#ansible_mounts)，这里的 `ansible_facts['distribution_version']` 也可以通过 `gather_subset` 动作获取到（已设置 `gather_facts: False`）。如下所示。

```yaml
    - setup:
        gather_subset:
          - distribution_version
    - debug:
        msg: "{{ ansible_facts['distribution_version'] is version('12.04', '>=') }}"
```

> 因此也可以将 `ansible_facts[`distribution_version`]` 写作 `ansible_distribution_version`。


`version` 测试接受以下操作符：

```yaml
<, lt, <=, le, >, gt, >=, ge, ==, =, eq, !=, <>, ne
```

此测试还接受第三个参数：`strict`，用于定义是否使用由 `ansible.module_utils.compat.version.StrictVersion`，所定义的严格版本解析。默认值为 `False`（使用 `ansible.module_utils.compat.version.LooseVersion`），`True` 则会启用严格的版本解析。

```yaml
{{ sample_version_var is version('1.0', operator='lt', strict=True) }}
```

> **译注**：在 `sample_version_var: '1.0.1a'` 时，若 `strict=True` 开启严格版本解析，则会报出错误：

```console
fatal: [debian_199]: FAILED! => {"msg": "Version comparison failed: invalid version number '1.0.1a'"}
```

> 关闭严格版本解析，或以符合严格版本解析模式的版本号测试（见下文，如：`'1.0.0a0'`），则版本测试正常。


从 Ansible 2.11 开始，`version` 测试接受一个 `version_type` 参数，该参数与 `strict` 互斥，并接受以下值：

```yaml
loose, strict, semver, semantic, pep440
```

- `loose`
此类型对应于 Python 的 `distutils.version.LooseVersion` 类。所有版本格式对于这种该类型都是有效的。比较规则简单且可预测，但不一定总能得到预期的结果。

- `strict`
这种类型对应于 Python 的 `distutils.version.StrictVersion` 类。版本号由两个或三个以点分隔的数字组成，最后有个可选的 `"pre-release"` 标签。预发布标签由一个字母 `'a'` 或 `'b'`，及一个数字组成。如果两个版本号的数字部分相等，则有预发布标签的版本号，总是比没有预发布标签的版本号早（小）。

- `semver`/`semantic`
这种类型会将 [语义版本方案](https://semver.org/) 用于版本比较。

- `pep440`
该类型会将 Python [PEP-440 版本编号规则](https://peps.python.org/pep-0440/) 用于版本比较。是在 2.14 版中加入的。

使用 `version_type` 比较语义版本，可以向下面这样完成：

```yaml
{{ '2.14.0rc1' is version('2.14.0', 'lt', version_type='pep440') }}
```

当在某个 playbook 或角色中使用 `version` 测试时，如 [常见问题] 中所讲的那样，请勿使用 `{{ }}`。


```yaml
vars:
    my_version: 1.2.3

tasks:
    - debug:
        msg: "my_version is higher than 1.0.0"
      when: my_version is version('1.0.0', '>')
```


## 集合论的测试


*版本 2.1 中的新特性*。


> **注意**：从版本 2.5 开始，`issubset` 和 `issuperset` 两个测试，被更名为了 `subset` 和 `superset`。

要看出某个列表是否包含另一列表，或被包含于另一列表，咱们可以使用 `subset` 和 `superset` 测试。

```yaml
    vars:
        a: [1,2,3,4,5]
        b: [2,3]
    tasks:
        - debug:
            msg: "A includes B"
          when: a is superset(b)

        - debug:
            msg: "B is included in A"
          when: b is subset(a)
```

## 测试列表是否保护某个值


*版本 2.8 中的新特性*。


Ansible 包含一个 `contains` 测试，其操作类似于 Jinja2 提供的 `in` 测试，但与之相反。`contains` 测试设计用于与 `select`、`reject`、`selectattr` 和 `rejectattr` 等过滤器配合使用。


```yaml
  vars:
    lacp_groups:
      - master: lacp0
        network: 10.65.100.0/24
        gateway: 10.65.100.1
        dns4:
          - 10.65.100.10
          - 10.65.100.11
        interfaces:
          - em1
          - em2

      - master: lacp1
        network: 10.65.120.0/24
        gateway: 10.65.120.1
        dns4:
          - 10.65.100.10
          - 10.65.100.11
        interfaces:
            - em3
            - em4

  tasks:
    - debug:
        msg: "{{ (lacp_groups|selectattr('interfaces', 'contains', 'em1')|last).master }}"
```


## 测试某个列表值是否为 `True`


*版本 2.10 中的新特性*。


咱们可以使用 `any` 和 `all` 测试，检查列表中的任何或所有元素是否为真。

```yaml
  vars:
    mylist:
        - 1
        - "{{ 3 == 3 }}"
        - True
    myotherlist:
        - False
        - True
  tasks:

    - debug:
        msg: "all are true!"
      when: mylist is all

    - debug:
        msg: "at least one is true"
      when: myotherlist is any
```

## 测试路径

> **注意**：从版本 2.5 开始，以下测试都被重新命了名，去掉了 `is_` 前缀。

以下测试可提供控制节点上某个路径的信息。


```yaml
  vars:
    mypath: '/home/hector/ansible-tutorial/src/usage/playbook/about.md'
    path2: '/home/hector/playbook/about.md'

  tasks:
    - debug:
        msg: "path is a directory"
      when: mypath is directory

    - debug:
        msg: "path is a file"
      when: mypath is file

    - debug:
        msg: "path is a symlink"
      when: mypath is link

    - debug:
        msg: "path already exists"
      when: mypath is exists

    - debug:
        msg: "path is {{ (mypath is abs)|ternary('absolute','relative')}}"

    - debug:
        msg: "path is the same file as path2"
      when: mypath is same_file(path2)

    - debug:
        msg: "path is a mount"
      when: mypath is mount

    - debug:
        msg: "path is a directory"
      when: mypath is directory
      vars:
         mypath: /home/hector/Pictures

    - debug:
        msg: "path is a file"
      when: "'/my/path' is file"
```

> **译注**：在倒数第二个测试中，若 `mypath` 是个控制节点上不存在的目录，那么测试结果为 `False`。


## 测试大小格式

`human_readable` 和 `human_to_bytes` 两个函数，允许咱们测试咱们的 playbook，确保咱们在任务中使用了正确的大小格式，进而确保咱们向计算机提供了字节格式，向人类提供了人类可读格式。


### 人类可读

就给定字符串是否可读作出断言。

比如

```yaml
    - name: "Human Readable"
      assert:
        that:
          - '"1.00 Bytes" == 1|human_readable'
          - '"1.00 bits" == 1|human_readable(isbits=True)'
          - '"10.00 KB" == 10240|human_readable'
          - '"97.66 MB" == 102400000|human_readable'
          - '"0.10 GB" == 102400000|human_readable(unit="G")'
          - '"0.10 Gb" == 102400000|human_readable(isbits=True, unit="G")'
```

这将得出：

```yaml
{ "changed": false, "msg": "All assertions passed" }
```

> **译注**：若修改其中一项，比如修改最后一条加以修改（删掉一个 `0`）：

```yaml
          - '"0.10 Gb" == 10240000|human_readable(isbits=True, unit="G")'
```

> 则会有下面的输出：

```json
fatal: [debian_199]: FAILED! => {
    "assertion": "\"0.10 Gb\" == 10240000|human_readable(isbits=True, unit=\"G\")",
    "changed": false,
    "evaluated_to": false,
    "msg": "Assertion failed"
}
```

> 输出不仅显示出示例中的断言失败，还给出了因具体哪个条目失败，该条目的求值结果。


### 人类可读到字节

以字节格式，返回给定字符串。

比如

```yaml
    - name: "Human to Bytes"
      assert:
        that:
          - "{{'0'|human_to_bytes}}        == 0"
          - "{{'0.1'|human_to_bytes}}      == 0"
          - "{{'0.9'|human_to_bytes}}      == 1"
          - "{{'1'|human_to_bytes}}        == 1"
          - "{{'10.00 KB'|human_to_bytes}} == 10240"
          - "{{   '11 MB'|human_to_bytes}} == 11534336"
          - "{{  '1.1 GB'|human_to_bytes}} == 1181116006"
          - "{{'10.00 Kb'|human_to_bytes(isbits=True)}} == 10240"
```

这将得出

```yaml
{ "changed": false, "msg": "All assertions passed" }
```


## 测试任务结果


以下任务，是对旨在检查任务状态测试的说明。

```yaml
  tasks:

    - shell: /usr/bin/foo
      register: result
      ignore_errors: True

    - debug:
        msg: "it failed"
      when: result is failed

    # in most cases you'll want a handler, but if you want to do something right now, this is nice
    # 在大多数情况下，咱们会需要个处理程序，但如果咱们打算现在就做一些事情，这是个很好的时机
    - debug:
        msg: "it changed"
      when: result is changed

    - debug:
        msg: "it succeeded in Ansible >= 2.1"
      when: result is succeeded

    - debug:
        msg: "it succeeded"
      when: result is success

    - debug:
        msg: "it was skipped"
      when: result is skipped
```


> **注意**：从版本 2.1 开始，咱们还可以使用 `success`、`failure`、`change` 和 `skip`，用于上面这些语法匹配，满足对语法要求严格的人的需要。
>
> **译注**：由于 `/usr/bin/foo` 并不存在，因此第一项任务会失败，且目标主机状态会改变。故该 playbook 的执行结果如下。

```console
TASK [shell] ********************************************************************************************************
fatal: [debian_199]: FAILED! => {"ansible_facts": {"discovered_interpreter_python": "/usr/bin/python3.11"}, "changed": true, "cmd": "/usr/bin/foo", "delta": "0:00:00.003051", "end": "2025-01-11 17:12:04.559226", "msg": "non-zero return code", "rc": 127, "start": "2025-01-11 17:12:04.556175", "stderr": "/bin/sh: 1: /usr/bin/foo: not found", "stderr_lines": ["/bin/sh: 1: /usr/bin/foo: not found"], "stdout": "", "stdout_lines": []}
...ignoring

TASK [debug] ********************************************************************************************************
ok: [debian_199] => {
    "msg": "it failed"
}

TASK [debug] ********************************************************************************************************
ok: [debian_199] => {
    "msg": "it changed"
}

TASK [debug] ********************************************************************************************************
skipping: [debian_199]

TASK [debug] ********************************************************************************************************
skipping: [debian_199]

TASK [debug] ********************************************************************************************************
skipping: [debian_199]

PLAY RECAP **********************************************************************************************************
debian_199                 : ok=3    changed=1    unreachable=0    failed=0    skipped=3    rescued=0    ignored=1
```


## 类型测试

在确定类型时，使用 `type_debug` 过滤器，并将其与该类型的字符串名称进行比较，这可能很有吸引力，但咱们应使用类型测试比较法，例如：

```yaml
  tasks:
    - name: "字符串的解释，string interpretation"
      vars:
        a_string: "A string"
        a_dictionary: {"a": "dictionary"}
        a_list: ["a", "list"]
      assert:
        that:
        # 请注意字符串也被归类为 “可迭代” 及 “序列” 类型，但不是 “映射” 类型。
        - a_string is string and a_string is iterable and a_string is sequence and a_string is not mapping

        # 请注意字典不被归类为 “字符串” 类型，但是 “可迭代”、“序列” 及 “映射” 类型。
        - a_dictionary is not string and a_dictionary is iterable and a_dictionary is mapping

        # 请注意列表不被归类为 “字符串” 或 “映射” 类型，但却是 “可迭代” 及 “序列” 类型。
        - a_list is not string and a_list is not mapping and a_list is iterable

    - name: "数字的解释，number interpretation"
      vars:
        a_float: 1.01
        a_float_as_string: "1.01"
        an_integer: 1
        an_integer_as_string: "1"
      assert:
        that:
        # `a_float` 与 `an_integer` 都是 “数字”，但他们又都有自己的类型
        - a_float is number and a_float is float
        - an_integer is number and an_integer is integer

        # `a_float_as_string` 与 `an_integer_as_string` 均不是数字，他们是字符串
        - a_float_as_string is not number and a_float_as_string is string
        - an_integer_as_string is not number and a_float_as_string is string

        # 在将 `a_float` 与 `a_float_as_string` 强制转换为浮点数，然后又强制转换为字符串时，应与直接转换字符串为相同值
        - a_float | float | string == a_float | string
        - a_float_as_string | float | string == a_float_as_string | string

        # 同样，在将 `an_integer` 与 `an_integer_as_string` 强制转换为浮点数，然后又强制转换为字符串时，应与直接转换字符串为相同值
        - an_integer | int | string == an_integer | string
        - an_integer_as_string | int | string == an_integer_as_string | string

        # 但是，先将 `a_float` 或 `a_float_as_string` 转换为整数，然后再转换为字符串，就不再与直接转换为字符串的同样值匹配了
        - a_float | int | string != a_float | string
        - a_float_as_string | int | string != a_float_as_string | string

        # 再一次同样的，先将 `an_integer` 或 `an_integer_as_string` 转换为浮点数，然后再转换为字符串，也不再与直接转换为字符串的同样值匹配
        - an_integer | float | string != an_integer | string
        - an_integer_as_string | float | string != an_integer_as_string | string

    - name: "原生布尔值的解释，native Boolean interpretation"
      loop:
      - yes
      - true
      - True
      - TRUE
      - no
      - No
      - NO
      - false
      - False
      - FALSE
      assert:
        that:
        # 请注意，虽然其他值可能会转换为布尔值，但只有这些是本身被视为布尔值的值
        # 还要注意，`'yes'` 是这些值中，唯一区分大小写的变种
        - item is boolean

```


（End）



