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

### 被区块添加标签

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


## 运行 playbook 时选择或跳过标记
