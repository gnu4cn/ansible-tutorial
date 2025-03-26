# YAML 语法

本页提供了正确 YAML 语法的一个基本概述，这是 Ansible playbooks（我们的配置管理语言）表达的方式。


我们使用 YAML，因为他比 XML 或 JSON 等其他常见数据格式，更易于人类读写。此外，大多数编程语言都有处理 YAML 的库。


咱们可能还希望同时阅读 [使用 playbook](../usage/playbooks.md)，了解在实践中是 YAML 语法如何使用的。



## YAML 基础

对于 Ansible 来说，几乎每个 YAML 文件都以一个列表开始。列表中的每个项目，都是一些键/值对的列表，他们通常称为 “哈希值” 或 “字典”。因此，我们需要知道编写 YAML 中的列表与字典。


YAML 还有个小怪癖，another small quirk。所有 YAML 文件（无论是否与 Ansible 相关），都可以可选地以 `---` 开头，以 `....` 结尾。这是 YAML 格式的一部分，表示文档的开始和结束。


某个列表中的所有成员，都是以 `- `（一个破折号和一个空格）开头，位处同一缩进级别的一些行：


```yaml
---
# A list of tasty fruits
- Apple
- Orange
- Strawberry
- Mango
...
```

字典是以简单的 `key: value` 形式表示（冒号后必须跟有一个空格）：


```yaml
# An employee record
martin:
  name: Martin D'vloper
  job: Developer
  skill: Elite
```


更复杂的一些数据结构是可行的，比如字典的列表、值为列表的字典，或二者的混合结构：


```yaml
# Employee records
- martin:
    name: Martin D'vloper
    job: Developer
    skills:
      - python
      - perl
      - pascal
- tabitha:
    name: Tabitha Bitumen
    job: Developer
    skills:
      - lisp
      - fortran
      - erlang
```


如果咱们确实打算这么做，那么字典和列表也可以用以一种简短形式表示：


```yaml
---
martin: {name: Martin D'vloper, job: Developer, skill: Elite}
fruits: ['Apple', 'Orange', 'Strawberry', 'Mango']
```

这些被称为 “流式集合, Flow Collections”。


> **译注**：上面是编写 YAML 的两种风格/样式，前一种称作序列样式，sequences style；后一种是更紧凑的流样式，flow style。
>
> 参考：
>
> - [Flow Style](https://www.yaml.info/learn/flowstyle.html)


虽然 Ansible 并不经常用到，但咱们也可以通过多种形式，指定某个布尔值（`true`/`false`）：


```yaml
create_key: true
needs_agent: false
knows_oop: True
likes_emacs: TRUE
uses_cvs: false
```

若咱们与默认的 `yamllint` 选项兼容，那么就要对字典中的布尔值，使用小写 `true` 或 `false`。


使用 `|` 或 `>` 就可以让值跨越多行。使用 “字面区块标量，Literal Block Scalar” `|` 的跨越多行，将包括换行符和全部的结尾空格。而使用 “折叠区块标量，Folded Block Scalar” `>`，则会将换行符折叠为空格，fold newlines to spaces；其被用于使本来很长的行，成为更容易阅读和编辑。不论使用 `|` 还是 `>`，缩进都将被忽略。例如：


```yaml
include_newlines: |
            exactly as you see
            will appear these three
            lines of poetry

fold_newlines: >
            this is really a
            single line of text
            despite appearances
```

尽管在上面的 `>` 示例中，所有换行符都会被折叠成空格，但有两种强制保留换行符的方法：


```yaml
fold_some_newlines: >
    a
    b

    c
    d
      e
    f
```

> **译注**：输出为 `"a b\nc d\n  e\nf\n"`。


或者，也可以通过加入换行符，强制保留换行符：

```yaml
fold_same_newlines: "a b\nc d\n  e\nf\n"
```


咱们把我们迄今所学到的知识，结合在一个任意的 YAML 示例中。这其实与 Ansible 无关，但可以让咱们感受一下这种格式：


```yaml
---
# An employee record
name: Martin D'vloper
job: Developer
skill: Elite
employed: True
foods:
  - Apple
  - Orange
  - Strawberry
  - Mango
languages:
  perl: Elite
  python: Elite
  pascal: Lame
education: |
  4 GCSEs
  3 A-Levels
  BSc in the Internet of Things
```


这就是开始编写 *Ansible* playbook，咱们需要知道的全部 YAML 知识了。


## 一些问题

**Gotchas**


虽然咱们可以把几乎任何东西，都放在一个在无引号的标量中，但也有一些例外。冒号后跟一个空格（或换行符）`": "`是一种映射的指示符。而空格后跟一个磅号 `" #"` 则表示注释。


由于这个原因，以下带脉将导致 YAML 的语法错误：

```yaml
foo: somebody said I should put a colon here: so I did

windows_drive: c:
```

...... 不过下面这个是可行的：


```yaml
foo: somebody said I should put a colon here:so I did
windows_path: c:\windows
```

> **译注：** 这将得到 `"c:\\windows"`。

对于那些用到了后跟空格，位处行末的冒号的哈希值，咱们会打算用单引号将其括起来：

```yaml
foo: 'somebody said I should put a colon here: so I did'

windows_drive: 'c:'
```

...... 这是其中的冒号就将被保留。

或者，咱们也可以使用双引号：


```yaml
foo: "somebody said I should put a colon here: so I did"

windows_drive: "c:"
```


单引号与双引号的区别在于，在双引号中咱们可以使用转义字符：


```yaml
foo: "a \t TAB and a \n NEWLINE"
```


允许使用的转义字符列表，可在 YAML 规范中的 [“转义序列”](https://yaml.org/spec/1.1/#escaping%20in%20double-quoted%20style/)（YAML 1.1）或 [“转义字符”](https://yaml.org/spec/1.2.2/#57-escaped-characters)（YAML 1.2）下找到。


以下是无效的 YAML：


```yaml
foo: "an escaped \' single quote"
```

此外，Ansible 会将 `"{{ var }}}"` 用于变量。如果冒号后的某个值以 `"{"` 开头，YAML 就会认为他是个字典，因此咱们必须像下面这样将其用双引号括起来：


```yaml
foo: "{{ variable }}"
```

如果咱们的值以单引号开头，则必须将整个值用双引号括起来，而不只是其中一部分。下面是一些如何正确地把值用双引号括起来的补充示例：

```yaml
foo: "{{ variable }}/additional/string/literal"
foo2: "{{ variable }}\\backslashes\\are\\also\\special\\characters"
foo3: "even if it is just a string literal it must all be quoted"
```


无效示例：


```yaml
foo: "E:\\path\\"rest\\of\\path
```


除 `'` 和 `"` 外，还有一些字符是特殊字符（或保留字符），而不能用作无引号标量的第一个字符： <code>[] {} > | * & ! % # ` @ ,</code>。


咱们还应当心 `? : -`。 在 YAML 中，如果他们后跟某个非空格字符，则允许在字符串开头使用这些字符，但 YAML 处理器的实现各不相同，因此最好使用引号（译注：单/双引号）。



在流式集合中，规则更为严格：


```yaml
a scalar in block mapping: this } is [ all , valid

flow mapping: { key: "you { should [ use , quotes here" }
```

布尔值的转换很有帮助，但在咱们想要的是字面意义上的 `"yes"`，或将别的布尔值作为字符串时，就会出现问题。在这种情况下，就要使用引号：


```yaml
non_boolean: "yes"
other_string: "False"
```


YAML 会将某些字符串转换为浮点数值，例如字符串 `1.0`。在咱们需要指定出版本号（例如在 `requirements.yml` 文件中）shi，如果该值看起来像个浮点数值，就要将该值用引号括起来：


```yaml
version: "1.10"
```


（End）


