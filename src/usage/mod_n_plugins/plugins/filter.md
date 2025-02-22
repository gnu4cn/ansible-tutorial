# 过滤器插件


过滤器插件操纵数据。在正确过滤器下，咱们可以提取某特定值、转换数据类型与格式、执行数学计算、拆分和连接字符串、插入日期与时间等。Ansible 使用了 Jinja2 提供的标准过滤器，并增加了一些专门过滤器插件。咱们可以 [创建定制 Ansible 过滤器插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-filter-plugins)。


## 启用过滤器插件

通过将其放入咱们 play 旁边的 `filter_plugins` 目录、在某个角色内，或放入 [`ansible.cfg`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 中配置的过滤器插件目录来源中，咱们就可以添加定制过滤器插件。


## 使用过滤器插件

在 Ansible 中咱们可使用模板的任何地方，咱们都可以使用这些过滤器：在 play 中、在变量文件中，或 [`template`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html#template-module) 模组的 Jinja2 模板中。有关使用过滤器插件的更多信息，请参阅 [使用过滤器操作数据](../../playbook/using/filters.md)。过滤器可返回任何类型的数据，但如果咱们想要返回布尔值（即 `true` 或 `false`），则应看看某种测试。


```yaml
vars:
   yaml_string: "{{ some_variable|to_yaml }}"
```

过滤器是 Ansible 中处理数据的首选方式，因为过滤器前面通常以 `|` 作为先导，以其表达式作为该过滤器的第一个输入，故咱们可以此识别出他。与大多数编程函数一样，咱们可能会向过滤器本身，传递一些额外参数。这些参数既可以是 `positional`（即按顺序传递），也可以是 `named`（以 `key=value` 对的形式传递）。在同时传递这两种类型的参数时，按位置的参数应放在前面。


```yaml
passing_positional: {{ (x == 32) | ternary('x is 32', 'x is not 32') }}
passing_extra_named_parameters: {{ some_variable | to_yaml(indent=8, width=1337) }}
passing_both: {{ some_variable| ternary('true value', 'false value', none_val='NULL') }}
```

在文档中，过滤器总是有个与 `c(|)` 左边表达式相对应的 `C(_input)` 选项。文档中的 `C(positional:)` 字段将显示哪些选项是位置选项，以及他们所要求的顺序。


## 插件列表


咱们可使用 `ansible-doc -t filter -l` 命令查看可用插件的列表。使用 `ansible-doc -t filter <plugin name>` 命令查看特定插件的文档与示例。

（End）

