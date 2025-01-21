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
