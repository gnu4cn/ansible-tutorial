# 关于标签

若咱们有某个大型 playbook，那么只运行其中某个特定部分，而不是运行整个 playbook 可能会很有用。这可通过 Ansible 标签实现。使用标签执行或跳过选定任务，需要两个步骤：

1. 为任务添加标签，既可单独添加，也可从区块、play、角色或导入继承标签；
2. 运行咱们的 playbook 时，选取或跳过标签。


> **注意**：`tags` 关键字是对 playbook 进行 “预处理” 的一部分，在确定哪些任务视为可执行时，具有很高的优先级。


## 使用 `tags` 关键字添加标签

咱们可以为单个任务，或某次包含添加标记。咱们还可通过在区块、play、角色或导入级别定义标签，为多个任务添加标签。关键字 `tags` 解决了所有这些用例。`tags` 关键字只会定义标签，并将其添加到任务中；而不会选取或跳过任务的执行。只有在运行某个 play 时，咱们才会根据命令行中的标签，选取或跳过任务。更多详情，请参阅 [运行 playbook 时选择或跳过标记](#运行-playbook-时选择或跳过标记)。


### 给单个任务添加标签

在极简级别，咱们可对某单个任务，应用一或多个标签。咱们可以在 playbook、任务文件，或角色中为任务添加标签。下面是个用不同标签，标记两个任务的示例：


```yaml
  tasks:
    - name: Install the servers
      ansible.builtin.yum:
        name:
        - nginx
        - memcached
        state: present
      tags:
      - packages
      - webservers

    - name: Configure the service
      ansible.builtin.template:
        src: templates/src.j2
        dest: /etc/foo.conf
      tags:
      - configuration
```

咱们可将同一标记，应用于多个任务。下面这个示例，就用同一个标签 `"ntp"` 标记了多个任务：


```yaml
---
# file: roles/common/tasks/main.yml

- name: Install ntp
  ansible.builtin.yum:
    name: ntp
    state: present
  tags: ntp

- name: Configure ntp
  ansible.builtin.template:
    src: ntp.conf.j2
    dest: /etc/ntp.conf
  notify:
  - restart ntpd
  tags: ntp

- name: Enable and run ntpd
  ansible.builtin.service:
    name: ntpd
    state: started
    enabled: true
  tags: ntp

- name: Install NFS utils
  ansible.builtin.yum:
    name:
    - nfs-utils
    - nfs-util-lib
    state: present
  tags: filesharing
```

若咱们以 `--tags ntp` 运行某个 playbook 中的这四个任务，Ansible 就会运行其中三个以 `ntp` 标记了的任务，而跳过那个没有该标记的任务。

### 给处理程序添加标签

处理程序属于只有在被通知时，才执行的任务的一种特例，因此他们会忽略所有标记，而不能被选中，也不能被选为针对，they ignore all tags and cannot be selected for nor against。

### 给区块添加标签

若咱们打算给咱们的 play 的多个任务，但并非全部任务上，应用某个标记，就要使用一个区块，并在该层级定义标记。例如，咱们可以上面给出的 NTP 示例，编辑为使用一个区块：


```yaml
# myrole/tasks/main.yml
- name: ntp tasks
  tags: ntp
  block:
  - name: Install ntp
    ansible.builtin.yum:
      name: ntp
      state: present

  - name: Configure ntp
    ansible.builtin.template:
      src: ntp.conf.j2
      dest: /etc/ntp.conf
    notify:
    - restart ntpd

  - name: Enable and run ntpd
    ansible.builtin.service:
      name: ntpd
      state: started
      enabled: true

- name: Install NFS utils
  ansible.builtin.yum:
    name:
    - nfs-utils
    - nfs-util-lib
    state: present
  tags: filesharing
```

要当心 `tag` 选取会取代大多数其他逻辑，包括 `block` 的错误处理。如果在区块中的某个任务上设置了标签，却没有在 `rescue` 或 `always` 小节设置，在咱们的标签没有覆盖到这些小节中的任务时，将阻止触发这些任务。


```yaml
    - block:
        - debug:
            msg: "run with tag, but always fail"
          failed_when: true
          tags: example

      rescue:
        - debug:
            msg: "I always run because the block always fails, except if you select to only run 'example' tag"

      always:
        - debug:
            msg: "I always run, except if you select to only run 'example' tag"
```

若不指定 `--tags example`，该示例将运行所有 3 个任务，但如果咱们使用 `--tags example` 运行，则只会运行第一个任务。

### 给 play 添加标签

若某个 play 中的所有任务，都要使用同一个标记，咱们可在 play 级别上添加标记。例如，如果咱们有个只有 NTP 任务的 play，那么咱们就可以给整个 play 打上标记：


```yaml
---
- name: Tags demo
  hosts: all
  tags: ntp
  gather_facts: no

  tasks:
    - name: Install ntp
      ansible.builtin.package:
        name: chrony
        state: present

    - name: Configure ntp
      ansible.builtin.template:
        src: templates/chrony.conf.j2
        dest: /etc/chrony.conf
      notify:
      - restart ntpd

    - name: Enable and run ntpd
      ansible.builtin.service:
        name: chronyd
        state: started
        enabled: true
  handlers:
    - name: restart ntpd
      ansible.builtin.service:
        name: chronyd
        state: restarted

- hosts: fileservers
  gather_facts: no
  tags: filesharing

  tasks:
    - name: Install NFS utils
      ansible.builtin.apt:
        name:
        - nfs-utils
        - nfs-util-lib
        state: present
```

> **注意**：被标记的任务将包含 play 中的所有隐含任务（如事实收集等），包括通过角色添加的那些任务。


### 给角色添加标签

给角色添加标签的方法有三：

1. 通过在 `roles` 下设置标签，给角色中的所有任务，添加相同的一或多个标签。请参阅本小节中的示例；
2. 通过在 playbook 中的静态 `import_role` 上设置标签，为角色中的所有任务，添加相同的一个或多个标签。请参阅 [给导入添加标签](#给导入添加标签) 中的示例；
3. 为角色内的单个任务或区块，添加一或多个标签。这是咱们可以选择或跳过，角色内某些任务的唯一方法。要选择或跳过角色内的任务，必须在单个任务或区块上设置标签，在咱们的 playbook 中使用动态的 `include_role`，并在该包含中添加相同的一或多个标签。当咱们使用这种方法，然后用 `--tags foo` 运行咱们的 playbook 时，Ansible 会运行这个包含本身，以及角色中任何同样有着 `foo` 标签的任务。详情请参阅 [给包含添加标签](#给包含添加标签)。

当咱们使用 `roles` 关键字，静态地在咱们的 playbook 中加入某个角色时，Ansible 会将咱们定义的标签，添加到该角色中的所有任务。例如：

```yaml
  roles:
    - role: webserver
      vars:
        port: 5000
      tags: [ web, foo ]
```

或者：

```yaml
---
- hosts: webservers
  roles:
    - role: foo
      tags:
        - bar
        - baz
    # using YAML shorthand, this is equivalent to:
    # - { role: foo, tags: ["bar", "baz"] }
```

> **注意**：在角色层级添加标记时，不仅所有任务都会被标记，角色的依赖项也会被标记。详见 [标签继承](#标签继承给多个任务添加标签) 小节。

### 给包含添加标签

咱们可将标签，应用于 playbook 中的动态包含。与单个任务上的标签一样，`include_*` 任务上的标签，只适用于该包含本身，而不适用于包含文件中，或角色中的任何任务。若咱们把 `mytag` 添加到某个动态的包含，然后使用 `--tags mytag` 运行该 playbook，则 Ansible 会运行该包含本身，运行所包含文件或角色中，任何以 `mytag` 标记了的任务，并跳过包含文件或角色中，不带那个标签的任务。有关详细信息，请参阅 [选择性地运行可重用文件中标记的任务](#选择性地运行可重用文件中标记的任务)。

咱们以给其他任务添加标签的相同方法，给包含添加标签：


```yaml
---
# file: roles/common/tasks/main.yml

- name: Dynamic reuse of database tasks
  include_tasks: db.yml
  tags: db
```

> **译注**：其中 `roles/common/tasks/db.yml` 内容如下：

```yaml
- debug:
    msg: "{{ port }}"
  tags: db
```

> 若 `debug` 任务没有 `tags: db`，也不会有相应输出。这与上文中，运行动态包含中带有同一标签的任务，及下面提到的包含标签不会应用到角色中的任务是一致的。

咱们只能将标签，添加到某个角色的动态包含。在本例中，`foo` 标签将 *不会* 应用到 `bar` 角色内的任务：

```yaml
---
- hosts: webservers
  tasks:
    - name: Include the bar role
      include_role:
        name: bar
      tags:
        - foo
```

### 给导入添加标签


咱们还可将一或多个标签，应用到通过静态 `import_role` 和 `import_tasks` 语句，导入的所有任务：


```yaml
---
- name: Tags demo
  hosts: webservers
  gather_facts: no

  tasks:
    - name: Import the common role
      import_role:
        name: common
      vars:
        port: 5000
      tags:
        - bar
        - baz

    - name: Import tasks from foo.yml
      import_tasks: foo.yml
      vars:
        port: 5000
      tags: [ web, foo ]
```

> **译注**：静态导入与动态包含相比，就无需在导入的任务中，添加标签了。


### 包含下的标签继承：区块与 `apply` 关键字

默认情况下，Ansible 不会将标签继承，应用于以 `include_role` 和 `include_tasks` 的动态重用。若咱们把标签添加到某个包含，他们只会应用到该包含本身，而不会应用到所包含的文件或角色中的任何任务。这样，咱们就可以执行在角色或任务文件中，选定的任务，请参阅在运行咱们的 playbook 时，[选择性地运行可重用文件中标记的任务](#选择性地运行可重用文件中标记的任务)。


若咱们需要标签继承，则可能需要使用导入（而非包含）。然而，在某个 playbook 中同时使用包含和导入，可能会导致难以诊断的 bug。因此，若咱们的 playbook 使用了 `include_*` 来重用角色或任务，而咱们又需要在某个包含上的标签继承，Ansible 提供了两种变通方法。咱们可使用 `apply` 关键字：


```yaml
- name: Dynamic reuse of database tasks
  include_tasks:
    file: db.yml
    # 将标签 'db' 添加到 db.yml 内的任务
    apply:
      tags: db
  # 将标签 'db' 添加到这个 ‘include_tasks’ 任务本身
  tags: db
  vars:
    port: 5000
```

或者咱们可以使用区块：


```yml
---
# file: roles/common/tasks/main.yml

- block:
  - name: Include tasks from db.yml
    include_tasks: db.yml

  tags: db
  vars:
    port: 5000
```

## 特殊标签

Ansible 为一些特殊行为，保留了几个标签名称：`always`、`never`、`tagged`、`untagged` 和 `all`。`always` 和 `never` 主要用于标记任务本身，其他三个在选择要运行或跳过哪些标记时会用到。

### `always` 与 `never`

Ansible 为一些特别行为，保留了几个标签名，其中两个是 `always` 和 `never`。若咱们将 `always` 标签指派被给某个任务或 play，那么除非咱们特别跳过（`--skip-tags always`），或跳过定义在该任务上的其他标签时，Ansible 将始终运行该任务或 play。

比如：


```yaml
  tasks:
  - name: Print a message
    ansible.builtin.debug:
      msg: "Always runs"
    tags:
    - always

  - name: Print a message
    ansible.builtin.debug:
      msg: "runs when you use specify tag1, all(default) or tagged"
    tags:
    - tag1

  - name: Print a message
    ansible.builtin.debug:
      msg: "always runs unless you explicitly skip, like if you use ``--skip-tags tag2``"
    tags:
       - always
       - tag2
```

> **警告**：内部的事实收集任务，默认被标记为了 `'always'`。但若咱们将某个标签应用到 play，并直接跳过了他（`--skip-tags`），或间接使用 `--tags` 且省略了他，则可以跳过。

> **警告**：角色参数规格验证任务，默认被标记为了 `'always'`。若咱们使用了 `--skip-tags always`，该验证将被跳过。


*版本 2.5 中的新特性*。


若咱们把 `never` 标签指派给了某个任务或 play，那么除非咱们特别要求（`--tags never`），或为该任务定义了另一标签，Ansible 会跳过该任务或 play。

比如：


```yaml
  tasks:
    - name: Run the rarely-used debug task, either with ``--tags debug`` or ``--tags never``
      ansible.builtin.debug:
        msg: '{{ showmevar }}'
      tags: [ never, debug ]
      vars:
        showmevar: 50
```

上面示例中很少使用的调试任务，只有在咱们特别要求 `debug` 或 `never` 标签时，才会运行。

## 运行 playbook 时选择或跳过标记

在咱们已把标签添加到任务、包含、区块、play、角色和导入后，咱们就可以在运行 `ansible-playbook` 时，可以根据他们的标签，选择性地执行或跳过任务了。Ansible 会运行或跳过，所有与咱们在命令行中所传递标签相匹配的任务。如果咱们在区块或 play 级别，以 `roles` 或以导入添加了某个标签，那么该标签会应用到该区块、play、角色，或所导入角色或文件中的每个任务。若咱们的角色有多个标签，而咱们又想在不同时间，调用该角色的子集，就要么 [使用动态包含](#选择性地运行可重用文件中标记的任务)，要么将该角色拆分为多个角色。

[`ansible-playbook`](../../../usage/cli/ansible-playbook.md) 提供五个与标签有关的命令行选项：

- `--tags all`，运行所有任务，无论有无标签，除非被标记为 `never`（这是默认行为）；
- `--tags tag1,tag2`，只运行有着 `tag1` 或 `tag2` 标签的任务（还包括标记为 `always` 的）；
- `--skip-tags tag3,tag4`，运行除了有着 `tag3` 或 `tag4` 或 `never` 标签外的所有任务；
- `--tags tagged`，只运行至少有一个标签的任务（ `never` 会覆盖 <sup>1</sup>）；
- `--tags untagged`，只运行无标记的任务（`always` 会覆盖 <sup>2</sup>）。

> **译注**：
>
> 1. 这里所说的 “`never` 覆盖”，是指在以 `--tags tagged` 运行 `ansible-playbook` 时，不会运行那些标记为 `never` 标签的任务。
>
> 2. 这里所说的 “`always` 覆盖”，是指在以 `--tags untagged` 运行 `ansible-playbook` 时，会始终运行那些标记为 `always` 标签的任务。

例如，要运行某个很长 playbook 中，那些仅标记为 `configuration` 或 `packages` 的任务和区块：

```console
ansible-playbook example.yml --tags "configuration,packages"
```

要运行除被标记为 `packages` 外的所有任务：

```console
ansible-playbook example.yml --skip-tags "packages"
```

要运行所有任务，即使是那些因被标记为 `never` 而排除的：

```console
ansible-playbook example.yml --tags "all,never"
```

运行带有 `tag1` 和 `tag3` 标签的任务，但要跳过那些同时有着 `tag4` 的任务：

```console
ansible-playbook example.yml --tags "tag1,tag3" --skip-tags "tag4"
```

### 标签优先级

在显式标签上，跳过总是占据优先，例如，若咱们同时指定了 `--tags` 和 `--skip-tags`，则后者优先。例如，`--tags tag1,tag3,tag4 --skip-tags tag3`，就只会运行那些标记为 `tag1` 或 `tag4` 的任务，而不运行标记为 `tag3` 的任务，即使任务有其他标签之一。


### 预览使用标签的结果

在咱们运行某个角色或 playbook 时，咱们可能不清楚或不记得，哪些任务有哪些标签，或者根本不知道有哪些标签存在。Ansible 提供了两个帮助咱们管理有标签 playbook 的，[`ansible-playbook`](../../../usage/cli/ansible-playbook.md) 的两个命令行开关：

- `--list-tags`，产生出一个可用标签的列表；
- `--list-tasks`，在与 `--tags tagname` 或 `--skip-tags tagname` 一起使用时，产生出一个被标记任务的列表。


例如，若咱们不知道在某个 playbook、角色或任务文件中，配置任务的标记是 `config` 还是 `conf`，咱们就可以在不运行任何任务的情况下，显示所有可用标记：

```console
ansible-playbook example.yml --list-tags
```

若咱们不知道哪些任务带有 `configuration` 和 `packages` 标签，那么可传递这些标签，并加上 `--list-tasks`。Ansible 会列出这些任务，而不执行任何任务。

```console
ansible-playbook example.yml --tags "configuration,packages" --list-tasks
```

这些命令行开关有个局限：他们无法给出动态包含文件或角色中的标签或任务。有关静态导入和动态包含之间差异的更多信息，请参阅 [比较包含和导入：动态和静态的重用](../using/reuse.md#比较包含和导入动态和静态重用)。


### 选择性地运行可重用文件中标记的任务

若咱们有个定义在任务或区块级别，带有标签的角色或任务文件，那么在咱们使用动态包含而不是静态导入时，就可以在 playbook 中，有选择地运行或跳过这些标记任务。咱们必须在所包含任务上，与包含语句本身，使用相同标记。例如，咱们可创建一个有着标记与为标记任务的文件：


```yaml
# mixed.yml
- name: Run the task with no tags
  ansible.builtin.debug:
    msg: this task has no tags

- name: Run the tagged task
  ansible.builtin.debug:
    msg: this task is tagged with mytag
  tags: mytag

- block:
  - name: Run the first block task with mytag
    debug:
      msg: First task in the block

  - name: Run the second block task with mytag
    debug:
      msg: Second task in the block

  tags:
  - mytag
```

而咱们可能在某个 playbook 中包含上面这个任务文件：

```yaml
  tasks:
    - name: Run tasks from mixed.yml
      include_tasks: mixed.yml
      tags: mytag
```

当咱们以 `ansible-playbook -i hosts myplaybook.yml --tags “mytag”` 运行这个 playbook 时，Ansible 就会跳过那个没有标签的任务，运行那些标记的单个任务，并运行那个区块中的两个任务。此外，他还会运行事实收集（隐含任务），因为他被标记为了 `always`。


### 标签继承：给多个任务添加标签

若咱们打算在无需将 `tags` 行，添加到每个任务下，把同一标签或同样的一些标签，应用到多个任务，咱们可在 play 或区块级别上定义标签，或者在添加角色或导入文件时定义标签。Ansible 会将标签沿依赖链应用到所有子任务。对于角色和导入，Ansible 会将 `roles` 小节或导入语句设置的标签，追加到角色或导入文件中，单个任务或区块上已设置的标签。这就是所谓的标签继承。标签继承很方便，因为咱们不必给每个任务都打上标签。同时，这些标签仍适用于各个任务。


对于 play、区块、`role` 关键字与静态导入，Ansible 均会应用标签继承，将咱们定义的标签添加到 play、区块、角色或导入文件中的每个任务。然而，标签继承 *不* 适用于 `include_role` 和 `include_tasks` 的动态重用。对于动态重用（即包含），咱们定义的标记只会适用于该包含本身。若咱们需要标签继承，就要使用静态的导入。如果由于咱们 playbook 的其余部分使用了包含，而无法使用导入，请参阅 [包含下的标记继承：区块和 `apply` 关键字](#包含下的标签继承区块与-apply-关键字)，了解解决这一问题的方法。


咱们可将标签应用到 playbook 中的动态包含。与单个任务上的标签一样，`include_*` 任务上的标签，只会适用于该包含本身，而不会应用到所包含文件或角色中的任何任务。若咱们把 `mytag` 添加到某个动态包含，然后使用 `--tags mytag` 运行该 playbook，Ansible 会运行该包含本身，运行所包含文件或角色中，任何以 `mytag` 标记了的任务，并跳过所包含文件或角色中，任何不带该标记的任务。有关详细信息，请参阅 [有选择地运行可重用文件中标记的任务](##选择性地运行可重用文件中标记的任务)。


### 全局性地配置标签


如果咱们要默认运行或跳过某些标记，则可使用 Ansible 配置中的 [`'TAGS_RUN'`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#tags-run) 和 [`'TAGS_SKIP'`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#tags-skip) 选项，设置这些默认值。


（End）


