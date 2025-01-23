# 模组默认值

若咱们会频繁使用相同参数，调用同一模组，那么使用 `module_defaults` 关键字，为特定模组定义默认参数，就可能会很有用。

下面是个基本示例：


```yaml
- hosts: localhost
  module_defaults:
    ansible.builtin.file:
      owner: root
      group: root
      mode: 0755
  tasks:
    - name: Create file1
      ansible.builtin.file:
        state: touch
        path: /tmp/file1

    - name: Create file2
      ansible.builtin.file:
        state: touch
        path: /tmp/file2

    - name: Create file3
      ansible.builtin.file:
        state: touch
        path: /tmp/file3
```

`module_defaults` 关键字可用在 play、区块即任务级别。某个任务中明确指定出了的任何模组参数，都将覆盖该模组参数的任何既定默认值。


```yaml
    - block:
        - name: Print a message
          ansible.builtin.debug:
            msg: "Different message"

      module_defaults:
        ansible.builtin.debug:
          msg: "Default message"

```

> **译注**：区块的模组默认值，应写在最后？实验发现若把其中的 `module_defaults` 小节，移至任务前，将报出错误。


咱们可通过指定一个空的字典，移除先前为某个模组设置的默认值。

```yaml
    - name: Create file1
      ansible.builtin.file:
        state: touch
        path: /tmp/file1
      module_defaults:
        file: {}
```

> **注意**：在 play 级别（以及使用 `include_role` 或 `import_role` 时在块/任务级别），设置的任何模组默认值，都将应用于所用到的全部角色，这可能会导致角色中的未预期行为。


下面是该特性的一些更现实的用例。


与某个需要认证的 API 交互。

```yaml
- hosts: localhost

  module_defaults:
    ansible.builtin.uri:
      force_basic_auth: true
      user: some_user
      password: some_password

  tasks:
    - name: Interact with a web service
      ansible.builtin.uri:
        url: http://some.api.host/v1/whatever1

    - name: Interact with a web service
      ansible.builtin.uri:
        url: http://some.api.host/v1/whatever2

    - name: Interact with a web service
      ansible.builtin.uri:
        url: http://some.api.host/v1/whatever3
```

为一些特定 EC2 相关模组，设置默认 AWS 区域。

```yaml
- hosts: localhost
  vars:
    my_region: us-west-2
  module_defaults:
    amazon.aws.ec2:
      region: '{{ my_region }}'
    community.aws.ec2_instance_info:
      region: '{{ my_region }}'
    amazon.aws.ec2_vpc_net_info:
      region: '{{ my_region }}'
```

## 模组默认值的分组

模组的默认组别，允许为属于一组的模组，提供共用参数。专辑可在其 `meta/runtime.yml` 文件中定义一些这样的组别。

> **注意**：`module_defaults` 不会考虑 `collections` 关键字，因此在 `module_defaults` 中新建组时，必须使用完全限定的组名，the fully qualified group name，FQGN。


下面是专辑 `ns.coll` 的 `runtime.yml` 文件示例。该文件定义了个名为 `ns.coll.my_group` 的操作组，并放置了 `ns.coll` 中的 `sample_module` 和 `another.collection` 中的 `another_module`。


```yaml
# collections/ansible_collections/ns/coll/meta/runtime.yml
action_groups:
  my_group:
    - sample_module
    - another.collection.another_module
```

在某个 playbook 中，这个分组现在可以这样使用：

```yaml
- hosts: localhost
  module_defaults:
    group/ns.coll.my_group:
      option_name: option_value

  tasks:
    - ns.coll.sample_module:
    - another.collection.another_module:
```


出于历史原因和向后兼容性，有一些特殊组别：


| 组别 | 扩展出的模组分组 |
| :-- | :-- |
| `aws` | `amazon.aws.aws` 与 `community.aws.aws` |
| `azure` | `azure.azcollection.azure` |
| `gcp` | `google.cloud.gcp` |
| `k8s` | `community.kubernetes.k8s`、`community.general.k8s`、`community.kubevirt.k8s`、`community.okd.k8s` 与 `kubernetes.core.k8s` |
| `os` | `openstack.cloud.os` |
| `acme` | `community.crypto.acme` |
| `docker*` | `community.general.docker` 与 `community.docker.docker` |
| `ovirt` | `ovirt.ovirt.ovirt` 与 `community.general.ovirt` |
| `vmware` | `community.vmware.vmware` |

- 请查看该专辑的文档，或其 `meta/runtime.yml`，以了解该组中包含了哪些操作插件和模组。

要通过在组名称前添加 `group/` 前缀，与 `module_defaults` 使用这些组别 - 例如 `group/aws`。


在某个 playbook 中，咱们可以为整组的模组，设置一些模组默认值，例如设置一个共用的 AWS 区域。


```yaml
# example_play.yml
- hosts: localhost
  module_defaults:
    group/aws:
      region: us-west-2

  tasks:
  - name: Get info
    aws_s3_bucket_info:

  # now the region is shared between both info modules

  - name: Get info
    ec2_ami_info:
      filters:
        name: 'RHEL*7.5*'
```

有关 `meta/runtime.yml` 的更多信息，包括 `action_groups` 的完整格式，请参阅 [`runtime.yml`](https://docs.ansible.com/ansible/latest/dev_guide/developing_collections_structure.html#meta-runtime-yml)。


（End）


