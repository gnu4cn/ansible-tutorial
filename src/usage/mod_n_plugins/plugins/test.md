# 测试插件

测试插件会对模板表达式求值，并返回 `True` 或 `False`。使用测试插件，咱们就可以创建出，实现咱们任务、区块、play、playbook 及角色等中逻辑的那些条件。Ansible 使用了作为 Jinja 一部分所提供的一些标准测试，并添加了一些专门的测试插件。咱们可 [创建定制的 Ansible 测试插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-test-plugins)。


## 启用测试插件

Ansible 中可以使用模板化的任何地方，咱们都可以使用测试：在 play、变量文件或 [`template`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html#template-module) 模组的 Jinja2 模板中。有关使用测试插件的更多信息，请参阅 [测试](../../playbook/using/tests.md)。

测试总是会返回 `True` 或 `False`，他们始终是个布尔类型，若咱们需要别的返回类型，则应使用过滤器。


通过模板中的 `is` 语句的运用，咱们便可识别出测试插件，测试插件也可以作为 `select` 系列过滤器的一部分。

```yaml
  vars:
    is_ready: '{{ task_result is success }}'

  tasks:
    - name: conditionals are always in 'template' context
      action: dostuff
      when: task_result is failed
```

测试将始终有个 `_input`，且这通常位于 `is` 的左侧。与大多数编程函数一样，测试同样会接受一些额外参数。这些参数既可以是 `positional`（按顺序传递），也可以是 `named`（以 `key=value` 对的形式传递）。在同时传递这两种类型参数时，位置参数应放在前面。


```yaml
  tasks:
    - name: pass a positional parameter to match test
      action: dostuff
      when: myurl is match("https://example.com/users/.*/resources")

    - name: pass named parameter to truthy test
      action: dostuff
      when: myvariable is truthy(convert_bool=True)

    - name: pass both types to 'version' test
      action: dostuff
      when: sample_semver_var is version('2.0.0-rc.1+build.123', 'lt', version_type='semver')
```

### 对列表使用测试插件

正如上面提到的那样，使用测试的一种方法，是与 `select` 系列过滤器一起使用（`select`、`reject`、`selectattr`、`rejectattr`）。

> **译注**：前面提到 `select` 系列过滤器的地方有：
>
> - [操作数据：列表与循环综合](../../playbook/man_data.md#循环与列表综合)
>
> - [测试判断：测试列表是否保护某个值](../../playbook/using/tests.md#测试列表是否保护某个值)


```yaml
    # give me only defined variables from a list of variables, using 'defined' test
    good_vars: "{{ all_vars|select('defined') }}"

    # this uses the 'equalto' test to filter out non 'fixed' type of addresses from a list
    only_fixed_addresses:  "{{ all_addresses|selectattr('type', 'equalto', 'fixed') }}"

    # this does the opposite of the previous one
    only_dynamic_addresses:  "{{ all_addresses|rejectattr('type', 'equalto', 'fixed') }}"
```

## 插件列表

咱们可使用 `ansible-doc -t test -l` 命令查看可用插件的列表。使用 `ansible-doc -t test <plugin name>` 查看特定插件的文档与示例。


（End）

