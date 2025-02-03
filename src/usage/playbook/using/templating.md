# 模板化（Jinja2）

Ansible 使用 Jinja2 模板，实现动态表达式及对 [变量](vars.md) 和 [事实](facts_and_magic_vars.md) 的访问。咱们可通过 [模板模组](../../collections/ansible_builtin.md) 使用模板。例如，咱们可以为某个配置文件创建一个模板，然后将该配置文件部署到多种环境，并为每种环境提供正确数据（IP 地址、主机名、版本等）。咱们还可以通过将任务名称等模板化的方式，直接在 playbook 中使用模板。咱们可以使用 Jinja2 中包含的所有 [标准过滤器和测试](https://jinja.palletsprojects.com/en/stable/templates/#builtin-filters)。Ansible 还包含了用于选取和转换数据的附加专用过滤器、用于计算模板表达式的测试，以及用于在模板中，从文件、API 和数据库等外部来源检索数据的 [`Lookup` 插件](../../plugins/lookup.md)。


所有模板化操作，都是在将任务发送到目标计算机，并在目标计算机上执行 **之前**， 在 Ansible 控制节点上进行。这种方法最大限度地减少了目标机对软件包的需求（只有控制节点上才需要 `jinja2`）。模板化还减少了 Ansible 传递给目标机器的数据量。Ansible 在控制节点上解析模板，仅传递每个任务的所需信息给目标机器，而不是传递控制节点上的所有数据，以及在目标机上解析。

> **注意**：[模板模组](../../collections/ansible_builtin.md) 使用的文件和数据，必须使用 utf-8 编码。

> **译注**：在另一个广泛使用的，专为网络管理的自动化方案 [NetBox](https://github.com/netbox-community/netbox) 中，也用到了 Jinja2 模板。
>
> 参考：[Jinja2 Tutorial](https://ttl255.com/jinja2-tutorial-part-1-introduction-and-variable-substitution/)


## Jinja2 示例

在本例中，我们要将服务器主机名写入其 `/tmp/hostname` 文件。


咱们的目录看起来是这样的：

```console
├── hostname.yml
├── templates
    └── test.j2
```

咱们的 `hostname.yml`：

```yaml
{{#include ../j2_example/hostname.yml}}
```

`test.j2`：

```jinja
{{#include ../j2_example/templates/test.j2}}
```


（End）


