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

咱们可在多个不同位置，设置多个同名变量。当咱们这样做时，Ansible 会加载其找到的所有可能变量，然后根据变量优先级，选取要应用的变量。换句话说，不同变量将按一定顺序相互覆盖。


就变量定义准则（于何处定义特定类型变量）达成一致的团队及项目，通常就会避免一些变量优先级问题。我们（作者）建议在一处定义各个变量：定下来于何处定义某个变量，并保持简单。有关示例，请参阅 [于何处设置变量的一些建议](#于何处设置变量的一些建议)。

在变量中咱们可设置的一些行为参数，也可在 Ansible 配置中、作为命令行选项或使用 playbook 关键字来设置。例如，咱们可以把 Ansible 用于连接远端设备的用户，以 `ansible_user` 定义为一个变量，而在配置文件中定义为 `DEFAULT_REMOTE_USER`，在命令行选项中定义为 `-u`，以及使用 playbook 关键字的 `remote_user`。如果在变量中并通过其他方式，定义了同一参数，那么变量就会覆盖其他设置。这种方法允许特定于主机的设置，覆盖更一般的设置。有关这些不同设置优先级的示例和更多详情，请参阅 [控制 Ansible 的行为方式：优先级规则](https://docs.ansible.com/ansible/latest/reference_appendices/general_precedence.html#general-precedence-rules)。


### 掌握变量优先级

Ansible 确实应用了变量优先级，而咱们就可能会用到他。以下是由低到高的优先级顺序（最后列出的变量，会覆盖其他所有变量）：

1. 命令行的值（比如 `-u my_user`，这些不属于变量）；
2. 角色默认值（正如在 [角色目录结构](roles.md#角色目录结构) 中所定义的） [<sup>1</sup>](#f-1)；
3. 仓库文件或脚本的组 `vars` [<sup>2</sup>](#f-2)；
4. 仓库的 `group_vars`/`all` 变量 [<sup>3</sup>](#f-3)；
5. Playbook 的 `group_vars`/`all` 变量 [<sup>3</sup>](#f-3)；
6. 仓库的 `group_vars`/`*` 变量 [<sup>3</sup>](#f-3)；
7. Playbook 的 `group_vars`/`*` 变量 [<sup>3</sup>](#f-3)；
8. 仓库文件或脚本的主机 `vars` [<sup>2</sup>](#f-2)；
9. 仓库的 `host_vars`/`*` 变量 [<sup>3</sup>](#f-3)；
10. Playbook 的 `host_vars`/`*` 变量 [<sup>3</sup>](#f-3)；
11. 主机事实 / 缓存的 `set_facts` 变量 [<sup>4</sup>](#f-4)；
12. Play 的 `vars`；
13. Play 的 `vars_prompt`；
14. Play 的 `vars_files`；
15. 角色的 `vars`（正如在 [角色目录结构](roles.md#角色目录结构) 中所定义的）；
16. 区块的 `vars`（仅适用于区块中的任务）；
17. 任务的 `vars`（仅适用于该任务）；
18. `include_vars`；
19. `set_facts`/注册的 `vars`；
20. 角色（及 `include_role`）的参数；
21. 包含的参数；
22. `--extra-vars`（比如 `-e "user=my_user"`，总是在优先级上占上风）。


一般来说，Ansible 会给予最近定义的、更活跃的、更具明确范围的变量以更高优先级。角色默认值文件夹中的变量，就很容易被覆盖。而该角色 `vars` 目录中的任何变量，则会覆盖命名空间中该变量的先前版本。主机和/或仓库变量，会覆盖角色默认值，但显式包含的变量，如 `vars` 目录或某个 `include_vars` 任务，则会覆盖仓库变量。

Ansible 会合并在仓库中设置的不同变量，因此那些更具体的设置，会覆盖更宽泛的设置。例如，被指定为 `group_var` 的 `ansible_ssh_user`，就会被指定为 `host_var` 的 `ansible_user` 覆盖。有关在仓库中设置的变量优先级的详情，请参阅 [变量合并方式](../../inventories_building.md#变量合并方式)。

**脚注**

<a name="f-1">1</a> 1. 每个角色中的任务，都会看到其自己角色的默认值。在角色外定义的任务，会看到上一角色的那些默认值；
<a name="f-2">2</a> 2. 定义在仓库文件中，或由动态仓库所提供的变量；
<a name="f-3">3</a> 3. 包括由 “`vars` 插件” 添加的变量，以及由 Ansible 提供的默认 `vars` 插件添加的 `host_vars` 和 `group_vars`；
<a name="f-4">4</a> 4. 当变量是以 `set_facts` 的可缓存选项创建出时，他们在 play 中具有高优先级，但当变量来自缓存时，则与主机事实的优先级相同。

> **注意**：在任何小节中，重新定义某个变量，都会覆盖之前的实例。如果多个组有着同一变量，则以最后加载的变量为准。如果在某个 play 的 `vars:` 小节两次定义了某个变量，则第二个变量胜出。

> **注意**：前面描述的是默认配置 `hash_behaviour=replace`，切换到 `merge` 后就只会部分覆盖。


### 限制变量作用域

咱们可根据变量值的作用域，来决定于何处设置某个变量。Ansible 有三种主要作用域：

- 全局：由配置、环境变量和命令行设定；
- Play：每个 Play 和及所包含的结构、`vars` 条目（`vars`、`vars_files` 及 `vars_prompt` 等）、角色的默认值与 `vars`；
- 主机：直接关联到某个主机的变量，如仓库、`include_vars`、事实于注册的任务输出等。


在某个模板中，咱们可以自动访问到某个主机作用域内的所有变量，以及全部注册的变量、事实与魔法变量等。


### 于何处设置变量的一些建议

咱们应根据咱们想要对变量值有什么样的控制要求，来选择在何处定义变量。

要在仓库中，设置那些涉及地理或行为的变量。由于组别通常是一些将角色映射到主机的实体，因此咱们通常可以在组上，而不是在角色上定义变量。请记住：子组别优先于父组别，主机变量优先于组变量。有关设置主机和组变量的详情，请参阅 [在仓库中定义变量](#在仓库中定义变量)。

要在 `group_vars/all` 文件中，设置一些常用默认值。有关如何在咱们的仓库中，组织主机和组变量的详情，请参阅 [组织主机和组变量](../../inventories_building.md#组织主机和组变量)。组变量一般会与仓库文件放在一起，但也可以由动态仓库返回（参见 [使用动态仓库](../../dynamic_inventory.md)），或定义在 AWX 中，或在 [Red Hat Ansible Automation Platform](https://docs.ansible.com/ansible/latest/reference_appendices/tower.html#ansible-platform) 上，通过用户界面或 API 定义：

```yaml
---
# file: /etc/ansible/group_vars/all
# this is the site wide default
ntp_server: default-time.example.com
```

要在 `group_vars/my_location` 文件中，设置那些特定于地理位置的变量。所有组都是 `all` 组的子组，因此在 `group_vars/my_location` 处设置的变量，会覆盖（优先于） `group_vars/all` 中设置的变量：


```yaml
---
# file: /etc/ansible/group_vars/boston
ntp_server: boston-time.example.com
```

如果一台主机使用别的 NTP 服务器，则可以在某个 `host_vars` 文件中进行设置，这将覆盖组变量：

```yaml
---
# file: /etc/ansible/host_vars/xyz.boston.example.com
ntp_server: override.example.com
```

<a name="role-defaults"></a>
要设置角色中的默认值，以避免未定义变量错误。如果咱们共享了咱们的角色，别的用户就可以依赖咱们在 `roles/x/defaults/main.yml` 文件中，添加的那些合理默认值，他们也可以在仓库或命令行中，轻松地覆盖这些值。更多信息，请参阅 [角色](roles.md)。例如：

```yaml
---
# file: roles/x/defaults/main.yml
# if no other value is supplied in inventory or as a parameter, this value will be used
http_port: 80
```

要设置角色中的变量，以确保某个值在该角色被用到，而不会被仓库变量覆盖。如果咱们不与他人共享角色，那么咱们可以这种方式，在 `roles/x/vars/main.yml` 中，定义如端口这样的特定于应用的行为。如果咱们与他人共享了角色，此时把变量放在这里，会使其他人更难覆盖，尽管他们仍可通过向角色传递参数，或使用 `-e`（`--extra-vars`） 设置变量来覆盖：

```yaml
---
# file: roles/x/vars/main.yml
# this will absolutely be used in this role
http_port: 80
```

在调用角色时，要将变量作为参数传递，以获得最大的清晰度、灵活性和可见性。这种方法会覆盖存在于角色的任何默认值。例如：

```yaml
roles:
   - role: apache
     vars:
        http_port: 8080
```

当咱们阅读这个游戏手册时，很明显咱们已经选择了要设置某个变量，还是要覆盖默认值。咱们还可以传递多个值，这样就可以多次运行同一角色。详情请参阅 [在一个 play 中多次运行某个角色](roles.md#在一个-play-中多次运行某个角色)。例如：

```yaml
roles:
   - role: app_user
     vars:
        myname: Ian
   - role: app_user
     vars:
       myname: Terry
   - role: app_user
     vars:
       myname: Graham
   - role: app_user
     vars:
       myname: John
```


在一个角色中设置的变量，对稍后的角色是可用的。咱们可以在角色的 `vars` 目录（正如 [角色目录结构](roles.md#角色目录结构) 中所定义的）中设置变量，并将其用于其他角色，以及 playbook 中的其他地方：


```yaml
roles:
   - role: common_settings
   - role: something
     vars:
       foo: 12
   - role: something_else
```

> **注意**：为避免变量命名空间的需要，存在一些保护措施。在本例中，角色 `common_settings` 中定义的变量，对 `something` 和 `something_else` 的任务是可用的，但即使 `common_settings` 将 `foo` 设置为了 `20`，`something` 中的任务仍会有着设置为了 `12` 的 `foo`。


与其操心变量的优先级，我们（作者）鼓励咱们，在决定于何处设置变量时，考虑咱们想要的覆盖变量难易度或频率。如果咱们不确定还有哪些变量已经定义了，又需要某个特定的值，那么可以使用 `--extra-vars` (`-e`) 命令行选项，来覆盖所有其他变量。


## 使用高级变量语法

有关用于声明变量，以及对 Ansible 用到的 YAML 文件中数据，进行更多控制的高级 YAML 语法信息，请参阅 [高级 playbook 语法](../adv_syntax.md)。
