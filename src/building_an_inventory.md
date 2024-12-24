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
ansible myhosts -m ping -i ansible_quickstart/inventory.ini
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
