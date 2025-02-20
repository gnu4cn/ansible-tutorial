# `cliconf` 插件

`cliconf` 插件是到各种网络设备的 CLI 接口抽象。他们为 Ansible 在这些网络设备上执行任务，提供了标准接口。

这些插件通常与网络设备平台一一对应。Ansible 会根据 `ansible_network_os` 这个变量，自动加载相应的 `cliconf` 插件。


## 添加 `cliconf` 插件

通过将某个定制插件，放入 `cliconf_plugins` 目录，咱们便可将 Ansible 扩展为支持其他网络设备。


## 使用 `cliconf` 插件

要用到的 `cliconf` 插件是由 `ansible_network_os` 变量自动决定的。没有理由改写这一功能。

大多数 `cliconf` 插件都无需配置即可运行。少数 `cliconf` 插件有一些可被设置以对将任务转化为 CLI 命令方式，施加影响的额外选项。

这些 `cliconf` 插件都是自带文档的。各个插件都应记录了其配置选项。


## 查看 `cliconf` 插件

这些插件均已迁移到 [Ansible Galaxy](https://galaxy.ansible.com/) 上一些专辑。如果咱们使用 `pip` 安装了 Ansible 2.10 或更高版本，就可以访问到多个 `cliconf` 插件。咱们可使用 `ansible-doc -t cliconf -l` 查看可用插件的列表。使用 `ansible-doc -t cliconf <plugin name>` 查看特定插件的文档与示例。


（End）

