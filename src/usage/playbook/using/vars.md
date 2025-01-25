# 使用变量

Ansible 使用变量，来管理不同系统之间的差异。使用 Ansible，咱们只需一条命令，就能在多个不同系统上执行任务和 playbook。要表示这些不同系统之间的差异，咱们可以使用标准 YAML 语法，创建出包括列表和字典等的变量。咱们可在 playbook、[仓库](../../inventories_building.md)、可重用 [文件](reuse.md) 或 [角色](roles.md) 中，或者在命令行中，定义这些变量。咱们还可以通过将任务的返回值，或任务中的值，注册为新变量，而在 playbook 运行期间创建出变量。

通过在文件中定义变量、在命令行中传递变量，或将任务的返回值、任务中的值注册为新变量等方式，咱们创建出变量后，就可以在模组参数、[条件 `when` 语句](conditionals.md)、[模板](templating.md) 和 [循环](loops.md) 中，使用这些变量。


一旦咱们掌握了本页的概念和示例后，就要阅读关于从远程系统获取到的那些变量， [Ansible facts](facts_and_magic_vars.md) 。


## 创建有效的变量名

并非所有字符串，都是有效的 Ansible 变量名。变量名只能包含字母、数字和下划线。[Python 关键字](https://docs.python.org/3/reference/lexical_analysis.html#keywords) 或 [playbook 关键字](https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html#playbook-keywords)，均不是有效的变量名。变量名不能以数字开头。


变量名可以下划线（`_`）开头。在许多编程语言中，以下划线开头的变量，都是私有的。但在 Ansible 中并非如此。以下划线开头的变量，与其他变量的处理方式完全相同。请勿为隐私或安全，而依赖此约定。


下面这张表，给出了一些有效和无效变量名的示例：


| 有效变量名 | 无效 |
| :-- | :-- |
| `foo` | `*foo`，诸如 `async` 及 `lambda` 等 [Python 关键字](https://docs.python.org/3/reference/lexical_analysis.html#keywords) |
| `foo_env` | 诸如 `environment` 等 [playbook 关键字](https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html#playbook-keywords) |
| `foo_port` | `foo-port`、`foo port`、`foo.port` 等 |
| `foo5`、`_foo` | `5foo`、`12` |

> **注意**：一些 [变量](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html#special-variables) 是内部定义的，用户无法定义他们。

> **注意**：咱们可能希望，避免使用会覆盖 [使用 playbook](../using.md) 中，列出的一些 Jinja2 全局函数的变量名，例如 [`lookup`](lookups.md#lookup-函数)、[`query`](lookups.md#queryq-函数)、[`q`](lookups.md#queryq-函数)、[`now`](now_func.md) 和 [`undef`](undef_func.md) 等。


## 简单变量

所谓简单变量，将变量名和单个值结合在一起。咱们可在很多地方，使用这种语法（列表与字典语法会在下面给出）。有关在仓库、playbook、可重用文件、角色或命令行中，设置变量的详情，请参阅 [于何处设置变量](#于何处设置变量)。


### 定义简单变量

咱们可使用标准 YAML 语法，定义出某个简单变量。例如

```yaml
remote_install_path: /opt/my_app_config
```

### 引用简单变量


在咱们定义了某个变量后，就要使用 Jinja2 语法，引用该变量。Jinja2 变量会用到双花括符（`{{  }}`）。例如，表达式 `My amp goes to {{ max_amp_value }}` 演示了变量替换的最基本形式。咱们可在 playbook 中，使用 Jinja2 语法。例如

```yaml
    ansible.builtin.template:
      src: foo.cfg.j2
      dest: '{{ remote_install_path }}/foo.cfg'
```

在此示例中，其中的变量定义了可因不同系统，而不同的某个文件位置。


> **注意**：Ansible 允许 [模板](templating.md) 中的 Jinja2 循环和条件，但不允许在 playbook 中使用他们。咱们无法创建出任务循环。Ansible playbook 都是纯机器可解析的 YAML。


## 何时要把变量括起来（YAML 陷阱）

若咱们以 `{{ foo }}` 开始某个值，则必须用引号将整个表达式括起来，才能创建出有效的 YAML 语法。如果咱们不把整个表达式用括起来，YAML 解析器就无法解释这种语法 -- 他可能是个变量，也可能是某个 YAML 字典的开头。有关编写 YAML 的指导，请参阅 [YAML 语法](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html#yaml-syntax) 文档。

如果咱们在不带引号下使用某个变量，就像下面这样：

```yaml
- hosts: app_servers
  vars:
    app_path: {{ base_path }}/22
```

咱们将看到：`Syntax Error while loading YAML.`。如果加上引号，Ansible 就能正常工作：

```yaml
- hosts: app_servers
  vars:
    app_path: "{{ base_path }}/22"
```


## 布尔值


Ansible 接受多种布尔变量值：`true`/`false`、`1`/`0`、`yes`/`no`、`True`/`False` 等。有效字符串的匹配不区分大小写。尽管为了与 `ansible-lint` 默认设置兼容，文档示例主要使用了 `true`/`false`，但咱们也可使用以下任何一种：


| 有效值 | 描述 |
| :-- | :-- |
| `True`、`true`、`t`、`yes`、`y`、`on`、`'1'`、`1`、`1.0` | 真值 |
| `False`、`false`、`f`、`no`、`n`、`off`、`'0'`、`0`、`0.0` | 假值 |


## 列表变量

列表变量将变量名与多个值组合。这多个值可被存储为一个逐项列表，或是在方括号 `[]` 中，以逗号分隔。


### 将变量定义为列表

使用 YAML 的列表语法，咱们就可定义出具有多个值的变量。例如：

```yaml
region:
  - northeast
  - southeast
  - midwest
```

### 引用列表变量


当咱们使用定义为列表（也称为数组）的变量时，咱们可以使用该列表中的单个、特定字段。列表中的第一个条目是 0 号条目，第二个条目是1 号条目。例如：


```yaml
region: "{{ region[0] }}"
```

这个表达式的值将是 `"northeast"`。


## 字典变量

字典以键值对形式存储数据。通常，字典用于存储有关联的数据，诸如某种 ID 或用户配置文件中包含的信息。


### 将变量定义为 `key:value` 的字典


使用 YAML 的字典语法，咱们就可定义出更为复杂的变量。YAML 字典会将键映射到值。例如：

```yaml
foo:
  field1: one
  field2: two
```

### 引用 `key:value` 的字典变量

当咱们使用被定义为 `key:value` 字典（也称为哈希字典）的变量时，咱们可使用方括号表示法（`[]`）或点表示法（`.`），使用字典中的某个单独、特定字段：


```yaml
foo['field1']
foo.field1
```

这两个示例都引用了同一个值（`"one"`）。方括号表示法始终有效。句号表示法则可能会引起问题，因为某些键与 python 字典的属性和方法相冲突。如果咱们使用了以两个下划线开头和结尾的键值（这在 python 中有特殊含义而被保留），或任何下面这些熟知的公共属性，那么就要使用方括号表示法：

`add`、`append`、`as_integer_ratio`、`bit_length`、`captialize`、`center`、`clear`、`conjugate`、`copy`、`count`、`decode`、`denominator`、`difference_update`、`discard`、`encode`、`endswith`、`expandtabs`、`extend`、`find`、`format`、`fromhex`、`fromkeys`、`get`、`has_key`、`hex`、`imag`、`index`、`insert`、`intersection`、`intersection_update`、`isalnum`、`isalpha`、`isdecimal`、`isdigit`、`isdisjoint`、`is_integer`、`islower`、`isnumeric`、`isspace`、`issubset`、`issuperset`、`istitle`、`isupper`、`items`、`iteritems`、`iterkeys`、`itervalues`、`join`、`keys`、`ljust`、`lower`、`lstrip`、`numerator`、`partition`、`pop`、`popitem`、`real`、`remove`、`replace`、`reverse`、`rfind`、`rindex`、`rjust`、`rpartition`、`rsplit`、`rstrip`、`setdefault`、`sort`、`split`、`splitlines`、`startswith`、`strip`、`swapcase`、`symmetric_difference`、`symmetric_difference_update`、`title`、`translate`、`union`、`update`、`upper`、`values`、`viewitems`、`viewkeys`、`viewvalue`、`zfill`


## 组合变量

要合并包含列表或字典的变量，可以使用以下方法。


### 组合列表变量


咱们可以使用 `set_fact` 模组，将一些列表合并为一个新的 `merged_list`，如下所示：


```yaml
  vars:
    list1:
    - apple
    - banana
    - fig

    list2:
    - peach
    - plum
    - pear

  tasks:
    - name: Combine list1 and list2 into a merged_list var
      ansible.builtin.set_fact:
        merged_list: "{{ list1 + list2 }}"
```


> **译注**：`merged_list` 将为：

```yaml
  merged_list:
    - apple
    - banana
    - fig
    - peach
    - plum
    - pear
```

### 组合字典变量


要合并一些字典，就要运用 `combine` 过滤器，例如：


```yaml
  vars:
    dict1:
      name: Leeroy Jenkins
      age: 25
      occupation: Astronaut

    dict2:
      location: Galway
      country: Ireland
      postcode: H71 1234

    dict3:
      planet: Earth

  tasks:
    - name: Combine dict1 and dict2 into a merged_dict var
      ansible.builtin.set_fact:
        merged_dict: "{{ dict1 | ansible.builtin.combine(dict2, dict3) }}"
```

更多详情，请参见 [ansible.builtin.combine](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/combine_filter.html#ansible-collections-ansible-builtin-combine-filter) 。

> **译注**：可以看出 `combine` 过滤器可接受多个字典。合并得到的 `merged_dict` 为：

```yaml
  merged_dict:
    age: 25
    country: Ireland
    location: Galway
    name: Leeroy Jenkins
    occupation: Astronaut
    planet: Earth
    postcode: H71 1234
```

### 使用 `merge_variables` 查找插件


要合并与给定前缀、后缀或正则表达式匹配的变量，咱们可使用 `community.general.merge_variables` 查找插件：

```yaml
  tasks:
    - debug:
        merged_variable: "{{ lookup('community.general.merge_variables', '__my_pattern', pattern_type='suffix') }}"
```

有关详细信息和使用示例，请参阅 [community.general.merge_variables](https://docs.ansible.com/ansible/latest/collections/community/general/merge_variables_lookup.html) 查找插件的文档。

> **译注**：若像下面这样写 `debug` 任务，会报出错误：`"Unsupported parameters for (debug) module: merged_variable. Supported parameters include: msg, var, verbosity."`。说明 `debug` 任务对其后的变量名有约束。

```yaml
  tasks:
    - debug:
        merged_variable: "{{ lookup('community.general.merge_variables', '__my_pattern', pattern_type='suffix') }}"
```

## 注册变量


使用任务的关键字 `register`，咱们可从某个 Ansible 任务输出，创建出变量。咱们可在咱们 play 稍后任务中，使用这些注册的变量。例如：


```yaml
  tasks:
     - name: Run a shell command and register its output as a variable
       ansible.builtin.shell: /usr/bin/foo
       register: foo_result
       ignore_errors: true

     - name: Run a shell command using output of the previous task
       ansible.builtin.shell: /usr/bin/bar
       when: foo_result.rc == 5
```

有关在稍后任务的条件中使用注册变量的更多示例，请参阅 [条件](conditionals.md)。注册的变量可以是简单变量、列表变量、字典变量，抑或复杂的嵌套数据结构。每个模组的文档，都包含了个描述了该模组返回值的 `RETURN` 小节。要查看某个特定任务的返回值，请使用 `-v` 运行咱们的 playbook。

注册变量存储于内存中。咱们无法为今后的 playbook 运行，缓存注册的变量。注册的变量仅在 playbook 运行的主机上，对当前运行 playbook 的其余部分有效，包括同一次 playbook 运行中的后续 play。

注册的变量是主机级别的变量。当咱们在带有循环的某个任务中，注册了某个变量时，那么对循环中的每个条目，这个注册的变量都会包含一个值。在循环过程中，放入到该变量中的数据结构将包含一个 `results` 属性，及该模组所有响应的一个列表。有关更深入的工作原理示例，请参阅有关在循环中使用变量注册的 [循环](./loops.md) 小节。

> **注意**：如果任务失败或被跳过，Ansible 仍会注册一个状态为 `failure` 或 `skipped` 的变量，除非该任务是依据标签跳过的。有关添加和使用标签的信息，请参阅 [标签](../executing/tags.md)。


## 引用嵌套变量

许多注册的变量（以及 [事实](./facts_and_magic_vars.md)），都是嵌套的 YAML 或 JSON 数据结构。咱们无法使用简单的 `{{ foo }}` 语法，访问到这些嵌套数据结构中的值。咱们必须使用方括号表示法或点表示法。例如，使用方括号表示法从咱们的事实中，引用某个 IP 地址：

```yaml
{{ ansible_facts['enp1s0']['ipv4']['address'] }}
```

而要使用点表示法引用咱们事实中的某个 IP 地址：

```yaml
{{ ansible_facts.enp1s0.ipv4.address }}
```


## 使用 Jinja2 过滤器转换变量


Jinja2 过滤器可让咱们在某个模板表达式中，转换变量的值。例如，`capitalize` 过滤器可将传递给他的任何值都大写；而 `to_yaml` 和 `to_json` 过滤器则可改变咱们变量值的格式。Jinja2 包含了许多 [内置过滤器](https://jinja.palletsprojects.com/templates/#builtin-filters)，且 Ansible 还提供了更多过滤器。要查找更多过滤器示例，请参阅 [使用过滤器处理数据](filters.md)。


## 于何处设置变量


咱们可在不同地方定义变量，比如在仓库中、在 playbook 中、在可重用文件中、在角色中以及在命令行下。Ansible 会加载他发现的所有可能的变量，然后根据 [变量优先级规则](#变量优先级我该把变量放在哪里)， 选取要应用的变量。


### 在仓库中定义变量

咱们可以为每台主机单独定义不同变量，或者为仓库中的一组主机，设置共享变量。例如，如果 `[Boston]` 组中的所有机器，都使用 `'boston.ntp.example.com'` 作为 NTP 服务器，则咱们可以设置个组变量。[如何建立仓库](../../inventories_building.md) 页面，提供了有关在仓库中设置 [主机变量](../../inventories_building.md#将变量分配给一台机器主机变量) 和 [组变量](../../inventories_building.md#将一个变量分配给多台机器组变量) 的详细信息。


### 在某个 play 中定义变量

咱们可直接在某个 playbook 的 play 中定义变量：


```yaml
- hosts: webservers
  vars:
    http_port: 80
```

当咱们在某个 play 中定义了变量时，那么就只有在该 play 中执行的任务，才能看到他们。


### 在包含的文件及角色中定义变量


咱们可在可重用变量文件，和/或可重用角色中定义变量。当咱们在可重用的变量文件中定义变量时，一些敏感变量就从 playbook 中分离了出来。通过这种分离，咱们可在某种源代码控制软件中存储 playbook，甚至共享 playbook，而不会有暴露密码或其他敏感及个人数据的风险。有关创建可重用文件与角色的信息，请参阅 [重用 Ansible 工件](reuse.md)。

下面这个示例，展示了如何包含定义在某个外部文件中的变量：


```yaml
---

- hosts: all
  remote_user: root
  vars:
    favcolor: blue
  vars_files:
    - /vars/external_vars.yml

  tasks:

    - name: This is just a placeholder
      ansible.builtin.command: /bin/echo foo
```

每个变量文件的内容，都是个简单的 YAML 字典。例如：

```yaml
---
# in the above example, this would be vars/external_vars.yml
somevar: somevalue
password: magic
```

> **注意**：咱们可以将每个主机和每个组的变量，保存在一些类似的文件中。要了解如何组织咱们变量，请参阅 [组织主机和组变量](../../inventories_building.md#组织主机和组变量)。


### 在运行时定义变量

在运行 playbook 时，咱们可使用 `--extra-vars`（或 `-e`）参数，通过在命令行中传递变量，来定义出变量。也可以使用 `vars_prompt`，请求用户输入（参见 [交互式输入：提示符](prompts.md)）。在命令行传递变量时，要使用引号括起来的，包含一或多个变量的单个字符串，以如下格式之一。

- **`key=value` 格式**

以使用 `key=value` 语法传递的值，会被解释为字符串。如果需要传递诸如布尔值、整数、浮点数、列表等非字符串值，就要使用 JSON 格式。

```console
ansible-playbook release.yml --extra-vars "version=1.23.45 other_variable=foo"
```

- JSON 字符串格式

```console
ansible-playbook release.yml --extra-vars '{"version":"1.23.45","other_variable":"foo"}'
ansible-playbook arcade.yml --extra-vars '{"pacman":"mrs","ghosts":["inky","pinky","clyde","sue"]}'
```

使用 `--extra-vars` 传递变量时，必须为咱们所使用的标记语法（如 JSON）和 shell，正确地转义引号和其他特殊字符：


```console
ansible-playbook arcade.yml --extra-vars "{\"name\":\"Conan O\'Brien\"}"
ansible-playbook arcade.yml --extra-vars '{"name":"Conan O'\\\''Brien"}'
ansible-playbook script.yml --extra-vars "{\"dialog\":\"He said \\\"I just can\'t get enough of those single and double-quotes"\!"\\\"\"}"
```

- **某个 JSON 或 YAML 文件中的变量**

若咱们有很多特殊字符，就要使用包含变量定义的 JSON 或 YAML 文件。要在 JSON 及 YAML 文件名前，加上 `@`。

```console
ansible-playbook release.yml --extra-vars "@some_file.json"
ansible-playbook release.yml --extra-vars "@some_file.yaml"
```


## 变量优先级：我该把变量放在哪里？
