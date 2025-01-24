# 使用变量

Ansible 使用变量，来管理不同系统之间的差异。使用 Ansible，咱们只需一条命令，就能在多个不同系统上执行任务和 playbook。要表示这些不同系统之间的差异，咱们可以使用标准 YAML 语法，创建出包括列表和字典等的变量。咱们可在 playbook、[仓库](../../inventories_building.md)、可重用 [文件](reuse.md) 或 [角色](roles.md) 中，或者在命令行中，定义这些变量。咱们还可以通过将任务的返回值，或任务中的值，注册为新变量，而在 playbook 运行期间创建出变量。

通过在文件中定义变量、在命令行中传递变量，或将任务的返回值、任务中的值注册为新变量等方式，咱们创建出变量后，就可以在模组参数、[条件 `when` 语句](conditionals.md)、[模板](templating.md) 和 [循环](loops.md) 中，使用这些变量。


一旦咱们掌握了本页的概念和示例后，就要阅读关于从远程系统获取到的那些变量， [Ansible facts](facts_and_magic_vars.md) 。


## 创建有效的变量名

并非所有字符串，都是有效的 Ansible 变量名。变量名只能包含字母、数字和下划线。[Python 关键字](https://docs.python.org/3/reference/lexical_analysis.html#keywords) 或 [playbook 关键字](https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html#playbook-keywords)，均不是有效的变量名。变量名不能以数字开头。


变量名可以下划线（`_`）开头。在许多编程语言中，以下划线开头的变量，都是私有的。但在 Ansible 中并非如此。以下划线开头的变量，与其他变量的处理方式完全相同。请勿为隐私或安全，而依赖此约定。


下面这张表，给出了一些有效和无效变量名的示例：


| 有效变量名 | 无效 |
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


