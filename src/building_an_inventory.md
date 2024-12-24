# 建立仓库

仓库将托管节点，组织在为 Ansible 提供系统信息及网络位置的中心化文件中。使用仓库文件，Ansible 可以单个命令，管理大量主机。

要完成以下步骤，咱们需要至少一个主机系统的 IP 地址或完全限定域名 (FQDN)。出于演示目的，该主机可以在容器或虚拟机中本地运行。还必须确保咱们的 SSH 公钥，已添加到每台主机上的 `authorized_keys` 文件中。

> **译注**：译者在 [ArchLinux/Manjaro](https://manjaro.org/) 通过 [`virt-manager`](https://virt-manager.org/)/[Virt-manager](https://wiki.manjaro.org/index.php/Virt-manager)，建立了 4 个 [AlmaLinux 8](https://almalinux.org/) 的虚拟机实例，用于 Ansible 实验目的。

请继续 Anisble 的入门，并像下面这样建立一个仓库：

1. 在咱们在上一步中创建的 `ansible_quickstart` 目录中，创建一个名为 `inventory.ini` 的文件;

2. 把一个新的 `[myhosts]` 组，添加到 `inventory.ini` 文件，并指定出每个主机系统的 IP 地址或完全限定域名 (FQDN)；

```ini
{{#include ../ansible_quickstart/inventory.ini}}
```

3. 检查咱们的仓库；

```console
> ansible-inventory -i ansible_quickstart/inventory.ini --list
```

> **译注**： 该命令的输出如下。


```json
{
    "_meta": {
        "hostvars": {}
    },
    "all": {
        "children": [
            "ungrouped",
            "myhosts"
        ]
    },
    "myhosts": {
        "hosts": [
            "almalinux-6",
            "almalinux-100",
            "almalinux-109",
            "almalinux-213"
        ]
    }
}
```

4. 对咱们仓库中的 `myhosts` 组，进行 `ping` 操作。

```console
ansible myhosts -u root -m ping -i ansible_quickstart/inventory.ini
```

> **注**：如果控制节点和托管节点上的用户名不同，请传递 `ansible` 命令下的 `-u` 选项。

```console
almalinux-100 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.8"
    },
    "changed": false,
    "ping": "pong"
}
almalinux-213 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.8"
    },
    "changed": false,
    "ping": "pong"
}
almalinux-109 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.8"
    },
    "changed": false,
    "ping": "pong"
}
almalinux-6 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.8"
    },
    "changed": false,
    "ping": "pong"
}
```

恭喜，咱们已成功建立了一个仓库。


## INI 或 YAML 格式的库存

咱们既可以在 INI 文件中，也可以在 YAML 中创建仓库。大多数情况下，例如前面步骤中的示例，对于少量托管节点来说，INI 文件就非常简单且易于读取。

随着托管节点数量的增加，以 YAML 格式创建仓库，就成为一个明智选择。例如，下面就是个与 `inventory.ini` 等效的，声明了那些托管节点的唯一名称，并使用了 `ansible_host` 字段：

```yaml
{{#include ../ansible_quickstart/inventory.yaml}}
```

## 建立仓库的一些技巧

- 确保组的名字有意义且唯一。组的名字同样区分大小写；

- 组的名字中要避免使用空格、连字符（`-`）和先导数字（比如要使用 `floor_19`，而不是 `19th_floor`）；

+ 要根据主机是什么（**What**）、位于何处（**Where**）以及何时存在（**When**），对清单中的主机进行逻辑分组。

    - **What**

    根据拓扑对主机进行分组，例如：`db`、`web`、`leaf`、`spine`。

    > **译注**：这里的 `leaf`、`spine` 是指 Spine-Leaf 网络拓扑，特指数据中心网络拓扑。spine 有枝干，而 leaf即叶子的字面意思。
    > 参考：
    > - [[译] 数据中心网络：Spine-Leaf 架构设计综述（2016）](http://arthurchiao.art/blog/spine-leaf-design-zh/)
    > - [什么是 Spine-Leaf架构？](https://www.arubanetworks.com/zh-hans/faq/what-is-spine-leaf-architecture/)

    - **Where**

    按地理位置对主机进行分组，例如：数据中心、区域、楼层、建筑物。

    - **When**

    按阶段对主机进行分组，例如：开发、测试、灰度发布（staging）、生产。

### 使用元组别

**Use metagroups**

使用以下语法，创建出对仓库中的多个组，加以组织的元组别：

```yaml
metagroupname:
  children:
```

下面这个仓库，演示了某个数据中心的基本结构。这个示例仓库，包含着一个包括了所有网络设备的 `network` 元组别，以及一个包含了 `network` 组以及全部 Web 服务器的 `datacenter` 元组别。

```yaml
{{#include ../ansible_quickstart/datacenter.yaml}}
```

> **译注**：执行命令 `ansible-inventory -i ansible_quickstart/datacenter.yaml --list` 的输出如下：

```json
{{#include ../ansible_quickstart/datacenter.json}}
```

### 创建变量

变量设置托管节点的一些值，比如 IP 地址、FQDN、操作系统及 SSH 用户等，如此咱们在运行 Ansible 命令时，就无需传递他们了。

变量可以应用于特定主机。

```yaml
{{#include ../ansible_quickstart/datacenter.yaml:20:27}}
```

变量也可以应用于某个组别中的全部主机。

```yaml
{{#include ../ansible_quickstart/datacenter.yaml:20:29}}
```

> **译注**：此时对于更新后的 `ansible_quickstart/inventory_updated.yaml`：

```yaml
{{#include ../ansible_quickstart/inventory_updated.yaml}}
```


> 执行 `ansible website -m ping -i ansible_quickstart/inventory_updated.yaml`，可得到与原先同样的结果。
