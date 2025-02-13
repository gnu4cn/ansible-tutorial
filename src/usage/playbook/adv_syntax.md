# 高级 playbook 语法

本页中的高级 YAML 语法示例，可让咱们对 Ansible 使用的 YAML 文件中的数据有更多控制。咱们可在 [`PyYAML` 官方文档](https://pyyaml.org/wiki/PyYAMLDocumentation#YAMLtagsandPythontypes) 中，找到有关特定于 Python 的 YAML 的更多信息。


## `unsafe` 或 `raw` 字符串

在处理由查找插件返回的值时，Ansible 会使用一种被称为 `unsafe` 的数据类型，来阻止模板化。将数据标记为不安全，可防止恶意用户滥用 Jinja2 模板，在目标机器上执行任意代码。这种 Ansible 实现确保了那些不安全值，永远不会被模板化。相比用 `{% raw %} ... {% endraw %}` 标签对 Jinja2 进行转义，其更为全面。


咱们可在咱们定义的变量中，使用这同样的 `unsafe` 数据类型，防止模板化错误及信息泄露。咱们可将 [`vars_prompts`](./using/prompts.md#允许-vars_prompt-值中的特殊字符) 提供的值，标记为不安全。咱们还也可以在 playbook 中使用 `unsafe`。最常见的用例包括，那些允许使用 `{` 或 `%` 等特殊字符的密码，以及看起来像模板但不应被模板化的一些 JSON 参数。例如：


```yaml
---
mypassword: !unsafe 234%234{435lkj{{lkjsdf
```


在某个 playbook 中：


```yaml
---
hosts: all
vars:
  my_unsafe_variable: !unsafe 'unsafe % value'
tasks:
    ...
```


对于哈希值或数组等复杂变量，要在单个元素上使用 `!unsafe`：

```yaml
---
my_unsafe_array:
  - !unsafe 'unsafe element'
  - 'safe element'

my_unsafe_hash:
  unsafe_key: !unsafe 'unsafe value'
```

## YAML 锚点与别名：共用变量值

YAML 锚点和别名可帮助咱们定义、维护和灵活使用一些共用的变量值。咱们可以 `&` 定义某个锚点，然后用以 `*` 表示的别名引用他。下面的示例使用一个锚点设置了三个值，以一个别名使用了其中两个，并覆盖了第三个值：


```yaml
---
- hosts: webservers
  gather_facts: no

  vars:
    app1:
      jvm: &jvm_opts
        opts: '-Xms1G -Xmx2G'
        port: 1000
        path: /usr/lib/app1
    app2:
      jvm:
        <<: *jvm_opts
        path: /usr/lib/app2
```

在这里，`app1` 和 `app2` 使用锚点 `&jvm_opts` 和别名 `*jvm_opts`，共用了 `opts` 和 `port` 的值。路径的值由 `<<` 或 [合并操作符](https://yaml.org/type/merge.html) 合并。


锚点和别名，还能让咱们共用变量值的复杂集合，包括嵌套变量。若咱们有个包含了另一变量值的变量，可以分别定义他们：

```yaml
  vars:
    webapp_version: 1.0
    webapp_custom_name: ToDo_App-1.0
```

这不仅效率低下，而且在大规模使用时，还意味着更多维护工作。要在名称字段中包含版本值，咱们可以在 `app_version` 字段中使用一个锚点，并在 `custom_name` 字段中使用一个别名：

```yaml
  vars:
    webapp:
      version: &my_version 1.0
      custom_name:
        - "ToDo_App"
        - *my_version
```

现在，咱们就可以在 `custom_name` 字段的值中，重用 `app_version` 字段的值，并在某个模板中使用输出：


```yaml
---
- name: Using values nested inside dictionary
  hosts: localhost

  vars:
    webapp:
      version: &my_version 1.0
      custom_name:
        - "ToDo_App"
        - *my_version

  tasks:
  - name: Using Anchor value
    ansible.builtin.debug:
      msg: My app is called "{{ webapp.custom_name | join('-') }}".
```

咱们已使用 `&my_version` 这个锚点，锚定了 `version` 字段的值，并用 `*my_version` 这个别名重用了他。锚点和别名，允许咱们访问字典中的嵌套值。


（End）

