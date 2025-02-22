# `netconf` 插件


`netconf` 插件是对网络设备 `netconf` 接口的抽象。他们为 Ansible 在这些网络设备上执行任务，提供了标准接口。


这些插件通常与网络设备平台一一对应。Ansible 会根据 `ansible_network_os` 这个变量，自动加载相应的 `netconf` 插件。如果平台支持 [Netconf RFC 规范](https://datatracker.ietf.org/doc/html/rfc6241) 中定义的标准 Netconf 实现，Ansible 就会加载默认的 `netconf` 插件。若平台支持专有的 Netconf RPC，Ansible 则会加载特定于平台的 `netconf` 插件。


## 添加 `netconf` 插件

通过将定制插件放入 `netconf_plugins` 目录，咱们即可将 Ansible 扩展为支持其他网络设备。


## 使用 `netconf` 插件

要用到的 `netconf` 插件，是由 `ansible_network_os` 变量自动决定的。没有理由覆盖这一功能。


大多数 `netconf` 插件无需配置即可运行。少数插件会有一些可被设置，以影响任务如何转换为 `netconf` 命令的额外选项。可以在 `netconf` 插件中设置特定于设备的 `ncclient` 处理程序名字，否则各个 `ncclient` 设备处理程序都会使用 `default` 值。


这些插件都自带文档。各个插件都应记录了其配置选项。


## 列出 `netconf` 插件


这些插件均已迁移到 [Ansible Galaxy](https://galaxy.ansible.com/) 的专辑。如果咱们使用 `pip` 安装了 2.10 或更高版本的 Ansible，就可以访问到多个 `netconf` 插件。咱们可使用 `ansible-doc -t netconf -l` 命令查看可用插件的列表。使用 `ansible-doc -t netconf <plugin name>` 查看特定插件的文档与示例。


（End）


