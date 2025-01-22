# 角色

角色让咱们，可以根据已知文件结构，自动加载相关变量、文件、任务、处理程序和其他 Ansible 工件。在咱们将咱们的内容，分组到角色后，咱们就可以轻松地重用他们，并与其他用户共享。

## 角色目录结构

Ansible 角色有个定义好的目录结构，有 7 个主要标准目录。在每个角色中，咱们必须至少包含其中一个目录。咱们可以省略角色未用到的所有目录。例如：

```console
# playbooks
site.yml
webservers.yml
fooservers.yml
```

```console
roles/
    common/               # 这个层次结构，表示某个 “角色”
        tasks/            #
            main.yml      # <-- 如有必要，任务文件可包含一些较小文件
        handlers/         #
            main.yml      #  <-- 处理程序文件
        templates/        #  <-- 用于使用模板资源的文件
            ntp.conf.j2   #  <------- 以 .j2 结尾的模板
        files/            #
            bar.txt       #  <-- 用于 copy 模组资源的文件
            foo.sh        #  <-- 用于 script 模组资源的脚本文件
        vars/             #
            main.yml      #  <-- 与本角色相关的变量
        defaults/         #
            main.yml      #  <-- 本角色的默认较低优先级变量
        meta/             #
            main.yml      #  <-- 角色依赖项
        library/          # 角色也可以包含定制模组
        module_utils/     # 角色也可以包含定制的 module_utils
        lookup_plugins/   # 或其他插件类型，比如这种情形下的查找

    webtier/              # 如同上面 "common" 这种同类型的结构，用于 webtier 角色
    monitoring/           # ""
    fooapp/               # ""
```

默认情况下，Ansible 会在大多数角色目录中，查找 `main.yml` 文件以获取相关内容（也包括 `main.yaml` 和 `main`）：

- `tasks/main.yml` - 角色提供给 play 用于执行的任务列表；
- `handlers/main.yml` - 导入到父 play 中，供该角色，或 play 中的其他角色及任务使用的处理程序；
- `defaults/main.yml` - 该角色提供的变量的低优先级值（更多信息请参阅 [“使用变量”](vars.md)）。角色自身的默认值，将优先于其他角色的默认值，但任何/所有其他变量来源，都将优先于此；
- `vars/main.yml` - 角色提供给 play 的高优先级变量（更多信息请参阅 [“使用变量”](vars.md)）；
- `files/stuff.txt` - 对角色及其子角色可用的一或多个文件；
- `templates/something.j2` - 在角色或子角色中使用的模板；
- `meta/main.yml` - 角色的元数据，包括角色的依赖项及可选的 Galaxy 元数据，如支持的平台等。对于以独立角色上传到 Galaxy，这是必须的，但在咱们的 play 中使用角色时，则不需要。


> **注意**：
>
> - 对于某个角色来说，上述任何文件都不是必需的。例如，咱们可以只提供 `files/something.txt` 或 `vars/for_import.yml`，其仍然是个有效的角色；
>
> - 在独立角色中，咱们也可以包含自定义模组和/或插件，例如 `library/my_module.py`，这些模组和/或插件可在该角色中使用（更多信息，请参阅 [在角色中嵌入模组和插件](#在角色中嵌入模组和插件)）；
>
> - 所谓 “独立” 角色，指的是不属于某个专辑，而是作为可单独安装内容的角色；
>
> - `vars/` 和 `defaults/` 中的变量，会被导入到 play 的作用域中，除非咱们通过 `import_role`/`include_role` 中的 `public` 选项禁用他。

咱们可以在某些目录中，添加其他的 YAML 文件，但默认情况下他们不会被用到。这些文件可以直接包含/导入，也可以在使用 `include_role/import_role` 时指定。例如，咱们可将特定平台的任务，放在单独文件中，并在 `tasks/main.yml` 文件中引用他们：


```yaml
# roles/example/tasks/main.yml
- name: Install the correct web server for RHEL
  import_tasks: redhat.yml
  when: ansible_facts['os_family']|lower == 'redhat'

- name: Install the correct web server for Debian
  import_tasks: debian.yml
  when: ansible_facts['os_family']|lower == 'debian'
```

```yaml
# roles/example/tasks/redhat.yml
- name: Install web server
  ansible.builtin.yum:
    name: "httpd"
    state: present
```

```yaml
# roles/example/tasks/debian.yml
- name: Install web server
  ansible.builtin.apt:
    name: "apache2"
    state: present
```

或者在加载该角色时，直接调用这些任务，这会绕过 `main.yml` 文件：


```yaml
- name: include apt tasks
  include_role:
      name: package_manager_bootstrap
      tasks_from: apt.yml
  when: ansible_facts['os_family'] == 'Debian'
```

目录 `defaults` 和 `vars`，也可能包括 *嵌套目录*。如果咱们的变量文件是个目录，Ansible 会按字母顺序，读取里面的全部变量文件和目录。如果某个嵌套目录，包含变量文件及目录，Ansible 会先读取那些目录。下面是个 `vars/main` 目录的示例：

```console
roles/
    common/          # this hierarchy represents a "role"
    common/          # 此层次结构表示一个 “角色”
        vars/
            main/    #  <-- 与此角色有关的变量
                first_nested_directory/
                    first_variables_file.yml
                second_nested_directory/
                    second_variables_file.yml
                third_variables_file.yml
```


## 存储与发现角色


默认情况下，Ansible 会在以下这些位置查找角色：

- 正在使用的专辑中；
- 在相对于 playbook 文件的 `roles/` 目录中；
- 在所配置的 `roles_path`。默认搜索路径为：`~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles`；
- 在 playbook 文件所在的目录中。


若咱们将角色存储在了别的位置，就要设置 `roles_path` 这个配置选项，以便 Ansible 能找到咱们的角色。将共享角色从代码仓库签入到单个位置，会使他们更容易在多个 playbook 中使用。有关管理 `ansible.cfg` 中设置的详情，请参阅 [配置 Ansible](../../../configuring.md)。

或者，咱们也可以使用某个完全限定路径，调用角色：

```yaml
---
- hosts: webservers
  roles:
    - role: '/path/to/my/roles/common'
```


## 使用角色

咱们可以以下方式使用角色：


- Play 级别的 `roles` 选项： 这是在 play 中使用角色的经典方法；
- 任务级别的 `include_role`： 使用 `include_role`，咱们可以在某个 play 的任务小节任意位置，动态重用角色；
- 任务级别的 `import_role`： 使用 `import_role`，咱们可在某个 play 的任务部分任意位置，静态重用角色；
- 作为另一角色的依赖项（参见本页 `meta/main.yml` 中的 [`dependencies` 关键字](#使用角色依赖项)）。

### 在 play 级别使用角色

使用角色的经典（最初）方式，是使用某个给定 play 的 `roles` 选项：

```yaml
---
- hosts: webservers
  roles:
    - common
    - webservers
```

当咱们在 play 级别，使用了 `roles` 选项时，每个角色 “x” 都会在以下目录中，查找 `main.yml`（也包括 `main.yaml` 和 `main`）：

- `roles/x/tasks/`
- `roles/x/handlers/`
- `roles/x/vars/`
- `roles/x/defaults/`
- `roles/x/meta/`
- 该角色中的任何 `copy`、`script`、`template` 或 `include_*` 任务，都可以引用 `roles/x/{files,templates,tasks}/` （取决于任务）中的文件，而无需相对或绝对路径。

> **注意**：`vars` 和 `defaults` 也可以匹配到同名目录，Ansible 将处理该目录中包含的所有文件。更多详情，请参阅 [角色目录结构](#角色目录结构)。

> **注意**：若咱们使用 `include_role`/`import_role`，则可以指定不同于 `main` 的自定义文件名。`meta` 目录是个例外，因为他不允许定制。


当咱们在 play 级别使用 `roles` 选项时，Ansible 会将那些角色视为静态的导入，并在 playbook 解析期间对这些角色进行处理。Ansible 会按以下顺序，执行各个 play：


- 定义在该 play 中全部的 `pre_tasks`；
- 由 `pre_tasks` 触发的全部处理程序；
- `roles:` 中列出的每个角色，按照列出顺序。角色的 `meta/main.yml` 中定义的任何角色依赖项都会首先执行，受标签过滤与条件限制。详情请参阅 [使用角色依赖项](#使用角色依赖项)；
- 定义在该 play 中的全部 `tasks`；
- 由 `roles` 或 `tasks` 触发的全部处理程序；
- 定义在该 play 中的全部 `post_tasks`；
- 由 `post_tasks` 所触发的全部处理程序。

> **注意**：若在角色中的与任务一起使用了标签，就要务必同时标记 `pre_tasks`、`post_tasks` 与角色依赖项，并将这些标签一并传递，尤其是在 `pre_tasks` / `post_tasks` 和角色依赖项用于监控（服务）中断（时间）窗口控制，或负载均衡的情况下。有关添加和使用标签的详细信息，请参阅 [标签](../executing/tags.md)。

咱们可传递一些别的关键字给 `roles` 选项：


```yaml
---
- hosts: webservers
  roles:
    - common
    - role: foo_app_instance
      vars:
        dir: '/opt/a'
        app_port: 5000
      tags: typeA
    - role: foo_app_instance
      vars:
        dir: '/opt/b'
        app_port: 5001
      tags: typeB
```


当咱们把某个标签，添加到 `role` 选项时，Ansible 会将这个标签，应用于该角色中的所有任务。


> **注意**：在 `ansible-core` 2.15 前，某个 playbook 的 `roles:` 小节中的 `vars:`，会被添加到 play 的变量中，从而使这些变量对该角色之前与之后的所有任务都可用。这一行为可通过设置项 [`DEFAULT_PRIVATE_ROLE_VARS`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-private-role-vars) 更改。而在较新的版本中，`vars:` 就不在会泄漏到 play 的变量作用域中了。


### 包含角色：动态的重用

咱们可以使用 `include_role`，在某个 play 的 `tasks` 小节中任意位置，动态重用角色。而在 `roles` 小节添加的角色，会先于 play 中全部其他任务运行，所包含的角色会按照他们被定义的顺序运行。但若在 `include_role` 任务前还有其他任务，则其他任务将首先运行。


要包含某个角色：

```yaml
---
- hosts: webservers
  tasks:
    - name: Print a message
      ansible.builtin.debug:
        msg: "this task runs before the example role"

    - name: Include the example role
      include_role:
        name: example

    - name: Print a message
      ansible.builtin.debug:
        msg: "this task runs after the example role"
```

在包含角色时，咱们还可传递别的一些关键字，包括变量和标记：

```yaml
---
- hosts: webservers
  tasks:
    - name: Include the foo_app_instance role
      include_role:
        name: foo_app_instance
      vars:
        dir: '/opt/a'
        app_port: 5000
      tags: typeA
  ...
```

当咱们把某个标签，添加到一项 `include_role` 任务时，Ansible **只** 会把这个标签，应用该包含本身。这意味着咱们可传递 `--tags` 命令行参数，而只运行角色中所选取的任务，前提是这些任务本身有着与包含语句同样的标记。有关详情，请参阅 [有选择地运行可重用文件中的标记任务](../executing/tags.md)。


咱们可以有条件地包含某个角色：


```yaml
---
- hosts: webservers
  tasks:
    - name: Include the some_role role
      include_role:
        name: some_role
      when: "ansible_facts['os_family'] == 'RedHat'"
```

咱们可以有条件地包含某个角色：


```yaml
---
- hosts: webservers
  tasks:
    - name: Include the some_role role
      include_role:
        name: some_role
      when: "ansible_facts['os_family'] == 'RedHat'"
```


### 导入角色：静态重用

使用 `import_role`，咱们可在某个 play 的 `tasks` 小节任意位置，静态地重用角色。其行为与使用 `roles` 关键字相同。例如：


```yaml
---
- hosts: webservers
  tasks:
    - name: Print a message
      ansible.builtin.debug:
        msg: "before we run our role"

    - name: Import the example role
      import_role:
        name: example

    - name: Print a message
      ansible.builtin.debug:
        msg: "after we ran our role"
```

导入角色时，咱们可传递其他一些关键字，包括变量和标记：

```yaml
---
- hosts: webservers
  tasks:
    - name: Import the foo_app_instance role
      import_role:
        name: foo_app_instance
      vars:
        dir: '/opt/a'
        app_port: 5000
  ...
```

当咱们将某个标签，添加到一个 `import_role` 语句时，Ansible 会将该标签，应用到所导入角色中的 **所有** 任务。详情请参阅 [标签继承：添加标签到多个任务](../executing/tags.md)。


## 角色参数的验证


从版本 2.11 开始，咱们可以选择启用，依据某种参数规格的角色参数验证。规格定义在 `meta/argument_specs.yml` 文件（或扩展名为 `.yaml` 的文件）中。在参数规格定义了时，一个将根据规格验证为该角色所提供参数的任务，就会与在角色执行开始处被插入。如果这些参数未通过验证，那么角色将无法执行。

> **注意**：Ansible 还支持在角色的 `meta/main.yml` 文件中，定义的参数规格。不过，任何在该文件中定义规格的角色，在 2.11 以下的版本中都将无法运行。因此，我们建议使用 `meta/argument_specs.yml` 文件，保持向后兼容性。

> **注意**：当角色参数验证应用于某个定义了 [依赖项](#运用角色依赖项) 的角色时，即使受依赖角色参数验证会失败，这些依赖项的验证，也会先于该角色运行。

> **注意**：Ansible 已使用 [`always`](../executing/tags.md) 标记了插入的角色参数验证任务。如果角色是静态导入的，那么除非使用 `--skip-tags` 命令行开关，否则该任务就会运行。

### 参数规格格式

角色参数规格，必须在该角色的 `meta/argument_specs.yml` 文件中，顶层的 `argument_specs` 区块中定义。所有字段均为小写。

+ `entry-point-name`
    - 角色入口名字；
    - 在未指定入口的情形下，这应是 `main`;
    - 这将是要执行的任务文件的基本名称，不带 `.yml` 或 `.yaml` 文件扩展名。
    + `short_description`
        - 入口的简短、单行描述。最好是个短语，而非一个句子；
        - 这个 `short_description` 会由 `ansible-doc -t role -l` 显示出来；
        - 他也会成为文档中该角色页面标题的一部分；
        - 简短说明应始终为字符串，而不应是列表，并且不应以句点结束。
    + `description`
        - 可包含多行的较长描述；
        - **这可以是单个字符串或字符串列表。如果这是个字符串列表，则每个列表元素都是个新的段落**。
    + `version_added`
        - 该入口被添加时，角色的版本；
        - 这是个字符串而非浮点数，比如 `version_added: '2.1'`；
        - 在专辑中，这必须是该入口被添加时专辑的版本。比如 `version_added: '1.0.0'`。
    + `author`
        - 该入口作者的名字；
        - 这可以是单个字符串，或者字符串列表。每名作者使用一个列表条目。如果只有一位作者，则使用字符串或单元素的列表。
    + `options`
        - 这些选项通常被称为 “parameters” 或 “arguments”。这个小节定义了这些选项；
        - 对于每个角色选项（参数），咱们可以包含：
        - `option-name`：该选项/参数的名字；
        + `description`
            - 该选项作用的详细说明。应以完整句子编写；
            - 这可以是个字符串，或字符串列表。如果这是个字符串列表，则每个列表元素都是个新的段落。
        + `version_added`
            - 只有当该选项是在初始的角色/入口点发布后，才添加的时才需要。换句话说，这会大于顶层的 `version_added` 字段；
            - 这是个字符串而非浮点数，比如 `version_added: '2.1'`；
            - 在专辑中，这必须是该入口被添加时专辑的版本。比如 `version_added: '1.0.0'`。
        + `type`
            - 该选项的数据类型。有关 `type` 的允许值，请参见 [参数规范](https://docs.ansible.com/ansible/latest/dev_guide/developing_program_flow_modules.html#argument-spec)。默认类型为 `str`；
            - 若某个选项为 `list` 类型，则要指定 `elements`。
        + `required`
            - 只有 `true` 时才需要；
            - 若缺失，则该选项是非必需的。
        + `default`
            - 若 `required` 为 `false`/缺失，则 `default` 就可能会指定（会在本参数规格缺失时假定 `null`）；
            - 请确保文档中的默认值，与代码中的默认值相匹配。角色变量的实际默认值，将始终来自角色的默认值（如 [角色目录结构](#角色目录结构) 中所定义）；
            - 除非需要额外信息或条件，否则 `default` 字段不得作为 `description` 的一部分列出；
            - 如果选项是个布尔值，则应使用 `true`/`false`，以便与 `ansible-lint` 兼容。
        + `choices`
            - 选项值的列表；
            - 在选项为空时应不存在该字段。
        - `elements`：在选项类型为 `list` 是，指定出列表元素的数据类型。
        - `options`：若该选项会取个字典，或字典列表，则咱们可在此处定义其数据结构。


### 示例参数规格

```yaml
# roles/myapp/meta/argument_specs.yml
---
argument_specs:
  # roles/myapp/tasks/main.yml entry point
  main:
    short_description: Main entry point for the myapp role
    description:
      - This is the main entrypoint for the C(myapp) role.
      - Here we can describe what this entrypoint does in lengthy words.
      - Every new list item is a new paragraph. You can have multiple sentences
        per paragraph.
    author:
      - Daniel Ziegenberg
    options:
      myapp_int:
        type: "int"
        required: false
        default: 42
        description:
          - "The integer value, defaulting to 42."
          - "This is a second paragraph."

      myapp_str:
        type: "str"
        required: true
        description: "The string value"

      myapp_list:
        type: "list"
        elements: "str"
        required: true
        description: "A list of string values."
        version_added: 1.3.0

      myapp_list_with_dicts:
        type: "list"
        elements: "dict"
        required: false
        default:
          - myapp_food_kind: "meat"
            myapp_food_boiling_required: true
            myapp_food_preparation_time: 60
          - myapp_food_kind: "fruits"
            myapp_food_preparation_time: 5
        description: "A list of dicts with a defined structure and with default a value."
        options:
          myapp_food_kind:
            type: "str"
            choices:
              - "vegetables"
              - "fruits"
              - "grains"
              - "meat"
            required: false
            description: "A string value with a limited list of allowed choices."

          myapp_food_boiling_required:
            type: "bool"
            required: false
            default: false
            description: "Whether the kind of food requires boiling before consumption."

          myapp_food_preparation_time:
            type: int
            required: true
            description: "Time to prepare a dish in minutes."

      myapp_dict_with_suboptions:
        type: "dict"
        required: false
        default:
          myapp_host: "bar.foo"
          myapp_exclude_host: true
          myapp_path: "/etc/myapp"
        description: "A dict with a defined structure and default values."
        options:
          myapp_host:
            type: "str"
            choices:
              - "foo.bar"
              - "bar.foo"
              - "ansible.foo.bar"
            required: true
            description: "A string value with a limited list of allowed choices."

          myapp_exclude_host:
            type: "bool"
            required: true
            description: "A boolean value."

          myapp_path:
            type: "path"
            required: true
            description: "A path value."

          original_name:
            type: list
            elements: "str"
            required: false
            description: "An optional list of string values."

  # roles/myapp/tasks/alternate.yml entry point
  alternate:
    short_description: Alternate entry point for the myapp role
    description:
      - This is the alternate entrypoint for the C(myapp) role.
    version_added: 1.2.0
    options:
      myapp_int:
        type: "int"
        required: false
        default: 1024
        description: "The integer value, defaulting to 1024."
```


## 在一个 play 中多次运行某个角色


在一个 play 中，即使咱们定义了多次，Ansible 对每个角色都只执行一次，除非每次在角色上定义的参数都不同。例如，Ansible 在像是下面的某个 play 中，就只会执行一次角色 `foo`：


```yaml
---
- hosts: webservers
  roles:
    - foo
    - bar
    - foo
```

咱们有两个选项，强制 Ansible 多次运行某个角色。

### 传递不同参数


若咱们在每个角色定义中传递了不同参数，Ansible 就会多次运行该角色。提供不同的变量值，不同于传递不同角色参数。由于 `import_role` 和 `include_role` 都不接受角色参数，因此咱们必须使用 `roles` 关键字才能实现此行为。

下面这个 play 会运行角色 `foo` 两次：


```yaml
---
- hosts: webservers
  roles:
    - { role: foo, message: "first" }
    - { role: foo, message: "second" }
```

下面这种语法，也会运行两次角色 `foo`：


```yaml
---
- hosts: webservers
  roles:
    - role: foo
      message: "first"
    - role: foo
      message: "second"
```


这两个示例中，Ansible 都运行了两次 `foo`，因为每个角色定义都有着不同参数。


### 使用 `allow_duplicates: true`


将 `allow_duplicates: true` 添加到该角色的 `meta/main.yml` 文件：


```yaml
# playbook.yml
---
- hosts: webservers
  roles:
    - foo
    - foo
```

```yaml
# roles/foo/meta/main.yml
---
allow_duplicates: true
```

在此示例中，Ansible 会运行两次 `foo`，因为我们显式地启用了他这么做。


## 运用角色依赖项


角色依赖项，可让咱们在使用某个角色时，自动拉入其他角色。

角色依赖项是先决条件，而非真正的依赖关系。这些角色之间没有父/子关系。Ansible 会加载所有列出的角色，首先运行 `dependencies` 下列出的角色，然后再运行列出这些角色的角色。其中 play 对象是所有角色的父对象，包括由 `dependencies` 列表调用的角色。

角色依赖项存储在角色目录下的 `meta/main.yml` 文件中。该文件应包含一个角色列表，以及在指定角色前要插入的参数。例如：


```yaml
# roles/myapp/meta/main.yml
---
dependencies:
  - role: common
    vars:
      some_parameter: 3
  - role: apache
    vars:
      apache_port: 80
  - role: postgres
    vars:
      dbname: blarg
      other_parameter: 12
```


Ansible 始终会先执行 `dependencies` 中列出的角色，然后再执行列出他们的角色。当咱们使用 `roles` 关键字时，Ansible 会递归执行这种模式。例如，如果咱们在 `roles:` 下列出了角色 `foo`，而角色 `foo` 在其 `meta/main.yml` 文件的 `dependencies` 中列出了角色 `bar`，角色 `bar` 又在其 `meta/main.yml` 文件的 `dependencies` 中列出了角色 `baz`，那么 Ansible 会首先执行 `baz`，然后执行 `bar`，最后执行 `foo`。


### 在一个 play 中多次运行角色依赖项


Ansible 处理重复角色依赖项的方式，就像处理 `roles:` 下列出的重复角色一样： Ansible 只会执行一次角色依赖项，即使定义了多次，除非每次在该角色上每次定义的角色参数、标记或 `when` 子句都不同。如果某个 play 的两个角色，都将某第三个角色列为了依赖项，那么 Ansible 只会执行该角色依赖项一次，除非咱们传递了不同的参数、标记、`when` 子句，或在咱们要多次执行的角色中，使用了 `allow_duplicates:true`。更多详情，请参阅 [ Galaxy 角色依赖项](../../../galaxy_user_guide.md)。

> **注意**：
>
> 角色取重，不会参考父角色的调用签名，the invocation signature of parent roles。此外，当使用 `vars:` 而非角色参数时，还有了改变变量作用域的副作用。使用 `vars:` 会导致这些变量，在 play 层级的范围界定。在下面的例子中，使用 `vars:` 会导致变量 `n` 在整个 play 中被定义为 `4`，包括在他之前被调用的角色中。
>
> 除上述情况外，使用者还应注意，角色去重发生于变量求值前。这意味着 [Lazy Evaluation](https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html#term-Lazy-Evaluation)，可能会使看似不同的角色调用变得等同，从而阻止角色多次运行。

比如，某个名为 `car` 的角色，依赖于某个名为 `wheel` 的角色，如下：

```yaml
---
dependencies:
  - role: wheel
    n: 1
  - role: wheel
    n: 2
  - role: wheel
    n: 3
  - role: wheel
    n: 4
```

而角色 `wheel` 依赖于两个角色：`tire` 与 `brake`。`wheel` 的 `meta/main.yml` 此时将包含如下内容：

```yaml
---
dependencies:
  - role: tire
  - role: brake
```

而 `tire` 与 `brake` 的 `meta/main.yml` 将包含如下内容：


```yaml
---
allow_duplicates: true
```


那么得到的执行顺序，将如下所示：


```yaml
tire(n=1)
brake(n=1)
wheel(n=1)
tire(n=2)
brake(n=2)
wheel(n=2)
...
car
```

要在角色依赖项这种情形下使用 `allow_duplicates:true`，咱们必须对 `dependencies` 中列出的角色指定他，而不是对列出依赖项的角色指定他。在上面的例子中，`allow_duplicates: true` 出现在角色 `tire` 和 `brake` 的 `meta/main.yml` 中。角色 `wheel` 不需要 `allow_duplicates:true`，因为由 `car` 定义的每个实例，都使用了不同参数值。


> **注意**：有关 Ansible 如何在定义于不同地方的变量值间选取（变量继承和作用域）的详情，请参阅 [“使用变量”](vars.md)。此外，去重 *只* 发生在 play 级别，因此同一 playbook 中的多个 play，就可能会重新运行这些角色。


## 在角色中嵌入模组及插件

> **注意**：这仅适用于独立角色。专辑中的角色不支持插件嵌入；他们必须使用专辑的 `plugins` 结构来分发插件（译注：即使用 FQCN 命名空间）。


如果咱们编写了个自定义模组（参见 [是否应该开发模组](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules.html#developing-modules)）或插件（参见 [开发插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-plugins)），那么咱们可能希望将其作为角色的一部分发布。例如，如果咱们编写了个帮助配置公司内部软件的模组，咱们希望组织中的其他人，也能使用这个模组，但又不想告诉每个人如何配置他们的 Ansible 库路径，那么咱们可以在咱们的角色 `internal_config` 中，包含这个模组。

要为某个角色添加一个模组或插件： 在某个角色的 `tasks` 和 `handlers` 结构旁边，添加一个名为 `library` 的目录，然后将模组直接包含在 `library` 目录中。


假设咱们有下面这样的结构：

```console
roles/
    my_custom_modules/
        library/
            module1
            module2
```

这些模组将在该角色本身中可用，同时在该角色 *后* 调用的任何角色中都可用，如下所示：

```yaml
---
- hosts: webservers
  roles:
    - my_custom_modules
    - some_other_role_using_my_custom_modules
    - yet_another_role_using_my_custom_modules
```

如有必要，咱们还可以在角色中，嵌入某个修改 Ansible 核心发布中模组的模组。例如，通过复制某个特定模组的开发版本并将其嵌入角色，咱们可以在生产版本发布前，就使用上了这个特定模组的开发版本。由于核心组件中的 API 签名可能会发生变化，因此要谨慎使用这种方法，而且这种变通方法也不保证有效。

这种同样机制，可用于在角色中嵌入和分发插件，并使用相同模式。例如，对于某种过滤器插件：


```console
roles/
    my_custom_filter/
        filter_plugins
            filter1
            filter2
```


然后，这些过滤器就可以在那些于 `my_custom_filter` 之后，调用的角色里的 Jinja 模板中了。


## 分享角色：Ansible Galaxy


Ansible Galaxy 是个用于查找、下载、打分与评价社区开发的各种 Ansible 角色的社区网站，是启动咱们自动化项目的好路子。

客户端 `ansible-galaxy` 包含在 Ansible 中。这个 Galaxy 客户端允许咱们从 Ansible Galaxy 下载角色，并提供了一个出色的默认框架，用于创建咱们自己的角色。


阅读 [Ansible Galaxy 文档](https://ansible.readthedocs.io/projects/galaxy-ng/en/latest/) 页面了解更多信息。


（End）
