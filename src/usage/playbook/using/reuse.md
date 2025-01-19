# 重用 Ansible 工件

咱们可能会在某个非常大的文件中，编写一个简单 playbook，大多数用户都会首先了解这种单文件方法。然而，将咱们自动化工作，分解成更小的文件，是组织复杂任务集，以及重用他们的绝佳方法。更小、更分散的工件，可以让咱们在多个游戏本中，重用相同变量、任务和 play，以解决不同用例。咱们可在多个父 playbook 中，使用分布式工件，甚至在一个 playbook 中多次使用这些分布式工件。例如，咱们可能打算将其作为多个不同 playbook 部分，更新咱们的客户数据库。如果咱们将与更新数据库相关的所有任务，放在某个任务文件或角色中，就可以在多个 playbook 中，重用这些任务，而只需在一处维护他们。


## 创建可重用的文件或角色

Ansible 提供了四种分散的、可重用工件：变量文件、任务文件、playbook 和角色。

- 变量文件只包含变量；
- 任务文件只包含任务；
- Playbook 包含至少一个 play，还可能包含变量、任务及别的内容。咱们可以重用目标极为明确的 playbook，但只能静态重用，不能动态重用；
- 角色包含一组有关联的任务、变量、默认值、处理程序，甚至模组或定义在文件树中的其他插件。与变量文件、任务文件或 playbook 不同，角色可以通过 Ansible Galaxy 轻松上传和共享。有关创建和使用角色的详细信息，请参阅 [角色](roles.md)。

*版本 2.4 中的新特性*。

## 重用 playbook


咱们可将多个 playbook，合并到一个 playbook 中。不过，咱们只能使用导入，来重用游戏本。例如

```yaml
- import_playbook: webservers.yml
- import_playbook: databases.yml
```

这样的导入，会静态地将 playbook 合并到其他 playbook 中。 Ansible 会按照列出顺序，运行每个导入 playbook 中的 play 和任务，就像直接在主 playbook 中定义了他们一样。

通过以某个变量定义咱们所导入的 playbook 文件名，然后用 `--extra-vars` 或 `vars` 关键字传递该变量，咱们就可以在运行时，选择要导入 playbook。例如

```yaml
- import_playbook: "/path/to/{{ import_from_extra_var }}"
- import_playbook: "{{ import_from_vars }}"
  vars:
    import_from_vars: /path/to/one_playbook.yml
```

若咱们使用 `ansible-playbook my_playbook -e import_from_extra_var=other_playbook.yml` 运行此 playbook，Ansible 就会同时导入 `one_playbook.yml` 和 `other_playbook.yml`。

## 何时要把 playbook 转化为角色

对于某些用例，简单的 playbook 效果很好。然而，当复杂度达到一定程度时，角色的效果要比 playbook 更好。通过角色，咱们可以将默认值、处理程序、变量和任务等，分别存储在单独目录中，而不在是单个长文档中。角色很容易在 Ansible Galaxy 上共享。对于复杂用例，大多数用户都会发现，角色比一体化的 playbook 更容易阅读、理解和维护。

## 重用文件与角色

Ansible 提供了两种于 playbook 中，重用文件和角色的方式：动态的和静态的。

+ 对于动态重用，要在某个 play 的任务小节，添加一个 `include_*` 任务：
    - [`include_role` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_role_module.html#include-role-module)
    - [`include_tasks` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_tasks_module.html#include-tasks-module)
    - [`include_vars` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_vars_module.html#include-vars-module)

+ 对于静态重用，要在某个 play 的任务小节，添加一个 `import_*` 任务：
    - [`import_role` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/import_role_module.html#import-role-module)
    - [`import_tasks` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/import_tasks_module.html#import-tasks-module)


任务的包含和导入语句，可在任意深度使用。

咱们仍然可以在 `play` 级别使用单独的 [`roles`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#roles-keyword) 关键字，静态地在 playbook 中加入角色。但是，曾用于包含任务文件和 playbook 级别包含的单独 `include` 关键字，现已被弃用。


### 包含：动态的重用

包含角色、任务或变量，会动态地将他们添加到 playbook 中。Ansible 会在 playbook 中出现所包含文件和角色处，处理这些包含的文件和角色，因此所包含的任务，会受到顶层 playbook 中，早期任务结果的影响。所包含的角色和任务，类似于处理程序 -- 他们可能运行，也可能不运行，这取决于顶层 playbook 中其他任务的结果。

使用 `include_*` 语句的主要优势，在于循环。当循环与某个包含一起使用时，所包含的任务或角色，将对循环中的每个条目执行一次。

在包含前，所包含角色、任务和变量的文件名就已模板化。

咱们可将变量，传递到所包含的内容中。有关变量继承和优先级的更多信息，请参阅 [变量优先级：我应该把变量放在何处？](vars.md)。


### 导入：静态的重用

导入角色、任务或 playbook，会将他们静态地添加到 playbook 中。在运行 playbook 中的任务前，Ansible 会先预处理所导入的文件和角色，因此导入的内容绝不会受到顶级 playbook 中，其他任务的影响。

导入的角色和任务文件名，支持模板化，但涉及的变量必须在 Ansible 预处理导入时可用。这可以通过 `vars` 关键字，或使用 `--extra-vars` 命令行选项实现。

咱们可以传递变量给导入项。若咱们要在某个 playbook 中，多次运行某个导入文件，就必须传递变量。例如：

```yaml
  tasks:
    - import_tasks: wordpress.yml
      vars:
        wp_user: timmy

    - import_tasks: wordpress.yml
      vars:
        wp_user: alice

    - import_tasks: wordpress.yml
      vars:
        wp_user: bob
```

有关变量继承和优先级的更多信息，请参阅 [变量优先级：我应该把变量放在何处？](vars.md)。


### 比较包含和导入：动态和静态重用


重用分布式 Ansible 工件的每种方法，都有优势和局限性。咱们可能会为某些 playbook 选择动态重用，而为其他 playbook 选择静态重用。虽然咱们可以在单个 playbook 中，同时运用动态和静态重用，但最好为每个 playbook 选择一种方法。混合使用静态和动态重用，可能会在 playbook 中引入难于诊断的错误。下面这个表格，总结了二者的主要区别，以便咱们可以为咱们创建的每个游戏本，选择最佳方法。


|  | `include_*` | `import_*` |
| :-- | :-- | :-- |
| 重用类型 | 动态 | 静态 |
| 何时处理（模板化） | 运行时，在遇到包含语句时 | 在 playbook 解析过程中被预处理 |
| 任务或 play | 所有包含项都属于任务 | `import_playbook` 不能是个任务 |
| 任务选项 | 仅应用到包含任务本身 | 应用到导入项的全部子任务 |
| 自循环调用 | 会对每个循环条目执行一次 | 无法在循环中使用 |
| 使用 `--list-tags` | 包含项内的标签不会被列出 | 在 `--list-tags` 命令行开关下全部标签都会出现 |
| 使用 `--list-tasks` | 包含项内的任务不会被列出 | 在 `--list-tasks` 命令行开关下全部任务都会出现 |
| 通知处理程序 | 包含项内无法触发处理程序 | 可以触发单个导入的处理程序 |
| 使用 `--start-at-task` | 无法于包含项内的任务处启动 | 可以在导入的任务处启动 |
| 使用仓库变量 | 可以执行 `include_*: {{ inventory_var }}` | 无法执行 `include_*: {{ inventory_var }}` |
| 处理 playbook | 没有 `include_playbook` | 可以导入完整的 playbook |
| 处理变量文件 | 可以包含变量文件 | 使用 `vars_files: ` 来导入变量 |

> **注意**：二者在资源消耗和性能方面也有很大差异，导入就相当精简和快速，而包括则需要大量的管理和审计。


## 将任务重用为处理程序

咱们也可以在 playbook 的 [处理程序](handlers.md) 小节中，使用包含和导入。例如，如果你想要定义如何重启 Apache，那么你只需为咱们全部 playbook 定义一次。咱们可以创建个 `restarts.yml` 文件，看起来像这样：

```yaml
# restarts.yml
- name: Restart nginx
  ansible.builtin.service:
    name: nginx
    state: restarted

- name: Restart mysql
  ansible.builtin.service:
    name: mysqld
    state: restarted
```

咱们即可通过导入，也可通过包含，触发处理程序，但两种重用方法的步骤不同。如果咱们包含的该文件，则必须通知包含本身，这会触发 `restarts.yml` 中的全部任务。如果咱们导入了该文件，则必须通知 `restarts.yml` 中的单个任务。在包含或导入的任务与处理程序下，咱们可以混用这些直接任务与处理程序。

### 触发包含（动态）处理程序

包含项是在运行时执行的，因此包含项的名称会存在于执行过程中，但在包含项本身被触发之前，所包含的任务并不存在。要以动态重用使用这个 `Restart apache` 任务，就要应用该包含项本身的名称。这种方法会触发包含文件中的所有任务。例如，使用上面给出的任务文件：

```yaml
- name: Trigger an included (dynamic) handler
  hosts: localhost
  handlers:
    - name: Restart services
      include_tasks: restarts.yml
  tasks:
    - command: "true"
      notify: Restart services
```


### 触发导入的（静态）处理程序

导入项是在 play 开始前处理的，因此在 play 执行期间，导入项的名称就不再存在了，但各个导入的任务的名称仍然存在。要以静态重用，使用这个 `Restart apache` 任务，就要引用所导入文件中，每个任务的名称。例如，使用上面给出的任务文件：


```yaml
- name: Trigger an imported (static) handler
  gather_facts: no
  hosts: app

  handlers:
    - name: Restart services
      import_tasks: restarts.yml

  tasks:
    - command: "true"
      notify: Restart nginx
    - command: "true"
      notify: Restart mysql
```


（End）



