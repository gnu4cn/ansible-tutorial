# 运用动态仓库

如果咱们的 Ansible 会随时间波动，其中的主机会根据业务需求启动或关闭，那么 [如何建立清单](inventories_building.md) 中描述的静态仓库解决方案，将无法满足咱们的需求。咱们可能需要从多个来源跟踪主机：云服务提供商、LDAP、[Cobbler](https://cobbler.github.io/) 和/或企业的 CMDB 系统等。


Ansible 通过动态外部仓库系统，集成了所有这些选项。Ansible 支持两种连接外部仓库方式： [仓库插件](../plugins/inventory.md) 和 **仓库脚本**。

仓库插件会用到 Ansible Core 代码的最新更新。对于动态仓库，我们推荐使用插件而非脚本。你可以 [编写自己的插件](../dev_guide/inventory.md)，连接到更多的动态仓库源。

如果愿意，咱们仍可使用仓库脚本。在实现仓库插件时，我们通过脚本仓库插件，确保向后兼容性。下面的示例说明了如何使用仓库脚本。


如果咱们偏好用图形用户界面，来处理动态仓库，那么 AWX 或 [Red Hat Ansible Automation Platform](../refs/aap.md) 上的仓库数据库，会同步咱们所有的动态仓库源，提供了对结果的 Web 和 REST 访问，并提供图形化的仓库编辑器。有了全部主机的数据库记录，咱们就可以关联过去的事件历史，查看哪些主机在上一次 playbooks 运行过程中出现了故障。


## 仓库脚本示例：Cobbler


Ansible 与 [Cobbler](https://cobbler.github.io/) 无缝集成，Cobbler 是个 Linux 安装服务器，最初由 Michael DeHaan 编写，现在由在 Ansible 工作的 James Cammarata 领导。


虽然 Cobbler 主要用于启动操作系统安装，以及管理 DHCP 和 DNS，但他有个可表示多种配置管理系统（甚至同时）数据的通用层，而充当了一种 “轻量级的 CMDB”。


要将 Ansible 清单与 Cobbler 绑定，请将 [此脚本](cobbler.py) 复制到 `/etc/ansible` 并 `chmod +x` 该文件。在使用 Ansible 的任何时候，请运行 `cobblerd`，并使用 `-i` 命令行选项（如 `-i /etc/ansible/cobbler.py`），来使用 Cobbler 的 XMLRPC API 与 Cobbler 通信。


在 `/etc/ansible` 目录下，添加 `cobbler.ini` 文件，这样 Ansible 就能知道 Cobbler 服务器的位置，以及一些可供使用的缓存改进。例如：


```ini
[cobbler]

# 设置 Cobbler 的主机名或 IP 地址
host = http://127.0.0.1/cobbler_api

# 到 Cobbler 的 API 调用可能较慢。为此，咱们就要缓存某次 API 调用的
# 结果。请将此设置为咱们打算缓存文件要写入的路径。有两个文件将被
# 写入到该目录下：
#   - ansible-cobbler.cache
#   - ansible-cobbler.index

cache_path = /tmp

# 缓存文件被视为有效的秒数。在此之后，将构造一次新的 API 调用，同时
# 该缓存文件将被更新。

cache_max_age = 900
```
