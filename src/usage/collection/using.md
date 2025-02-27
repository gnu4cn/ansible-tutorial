# 在 playbook 中使用专辑

某个专辑被安装后，咱们就可以其完全合格的专辑名称（FQCN），来该专辑的内容：


```yaml
- name: Reference a collection content using its FQCN
  hosts: all
  tasks:

    - name: Call a module using FQCN
      my_namespace.my_collection.my_module:
        option1: value
```

这适用于在该专辑中分发的角色，或任何类型的插件：


```yaml
- name: Reference collections contents using their FQCNs
  hosts: all
  tasks:

    - name: Import a role
      ansible.builtin.import_role:
        name: my_namespace.my_collection.role1

    - name: Call a module
      my_namespace.mycollection.my_module:
        option1: value

    - name: Call a debug task
      ansible.builtin.debug:
        msg: '{{ lookup("my_namespace.my_collection.lookup1", "param1") | my_namespace.my_collection.filter1 }}'
```


## 使用 `collections` 关键字简化模组名字

通过 `collections` 关键字，咱们可以定义出一个，咱们角色或 playbook 应检索的一些不合格模组与操作名字的专辑列表。若此咱们便可使用 `collections` 关键字，然后在整个角色或 playbook 中，以模组和动作插件的简短名字，引用他们。


> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> 如果咱们的 playbook 同时使用了 `collections` 关键字，以及一或多个角色，则这些角色不会继承由该 playbook 设置的集合。这也是我们（作者）建议咱们始终使用 FQCN 的原因之一。有关角色的详细信息，请参阅下文。


## 在角色中使用 `collections` 关键字


在某个角色中，咱们可以使用该角色的 `meta/main.yml` 中的 `collections` 关键字，控制 Ansible 为该角色内的任务，要检索哪些专辑。即使调用该角色 playbook，在某个单独的 `collections` 关键字条目中定义了别的专辑，Ansible 也会使用该角色内部定义的那个专辑列表。在某个专辑中定义的角色，总是会首先隐式地检索其自己的专辑，因此咱们无需使用 `collections` 关键字，访问位于同一专辑中的模组、操作或其他角色。


```yaml
# myrole/meta/main.yml
collections:
  - my_namespace.first_collection
  - my_namespace.second_collection
  - other_namespace.other_collection
```

## 在 playbook 中使用 `collections` 关键字

在某个 playbook 中，咱们可以控制那些 Ansible 检索要执行的模组与动作插件的专辑。不过，咱们在咱们 playbook 中调用的任何角色，都会定义他们自己的专辑检索顺序；他们不会继承调用 playbook 的设置。即使角色没有定义自己的 `collections` 关键字，情况也是如此。


```yaml
- name: Run a play using the collections keyword
  hosts: all
  collections:
    - my_namespace.my_collection

  tasks:

    - name: Import a role
      ansible.builtin.import_role:
        name: role1

    - name: Run a module not specifying FQCN
      my_module:
        option1: value

    - name: Run a debug task
      ansible.builtin.debug:
        msg: '{{ lookup("my_namespace.my_collection.lookup1", "param1")| my_namespace.my_collection.filter1 }}'
```


其中的 `collections` 关键字只是为一些非命名空间的插件与角色引用，创建了个有序的 “检索路径”。他不会安装内容，也不会改变 Ansible 加载插件或角色的行为。请注意，一些非动作或模组插件（例如查找、过滤器和测试等），仍然需要 FQCN。


在使用了 `collections` 关键字时，无需在检索列表中添加 `ansible.builtin`。如果将其省略，默认情况下以下内容是可用的：

1. 由 `ansible-base` / `ansible-core` 提供的那些标准 ansible 模组与插件；
2. 旧有的第三方插件路径支持，support for older 3rd parth plugin paths。


一般来说，最好使用模组或插件的 FQCN，而不是 `collections` 关键字。


## 使用某个专辑中的 playbook


*版本 2.11 中的新特性*。


咱们还可以在咱们的专辑中，分发一些 playbook，并使用与咱们用于插件相同的语义，调用他们：


```console
ansible-playbook my_namespace.my_collection.playbook1 -i ./myinventory
```

从某个 playbook 中调用：


```yaml
- name: Import a playbook
  ansible.builtin.import_playbook: my_namespace.my_collection.playbookX
```


在创建此类随咱们专辑分发的 playbook 时，有几条建议，`hosts:` 应该是通用的，或者至少有个变量输入。


```yaml
- hosts: all  # Use --limit or customized inventory to restrict hosts targeted

- hosts: localhost  # For things you want to restrict to the control node

- hosts: '{{target|default("webservers")}}'  # Assumes inventory provides a 'webservers' group, but can also use ``-e 'target=host1,host2'``
```

与角色一样，在 `my_namespace.my_collection` 的 `collections:` 关键字中，将会有个隐式的条目。


> **注意**：
>
> - 与其他专辑的资源一样，playbook 的名字也有着受限的有效字符集。名字只能包含小写字母数字字符，以及 `_`，并且必须以字母字符开头。破折号 `'-'` 字符不适用于专辑中的 playbook 名字。名字中包含无效字符的 playbook 无法被寻址到：这是因为用于加载专辑资源的 Python 导入器的局限性；
>
> - 专辑中的 playbook，不支持 “相邻” 插件，所有插件都必须位于特定于该专辑的那些目录中。


（End）

