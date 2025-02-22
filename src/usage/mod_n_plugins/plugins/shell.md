# `shell` 插件


`shell` 插件的作用，是确保 Ansible 运行的一些基本命令有被恰当格式化，能在目标计算机上运行，并允许用户配置与 Ansible 执行任务方式相关的某些行为。

## 启用 `shell` 插件

通过把某个定制 `shell` 插件放如与咱们 play 相邻的 `shell_plugins` 目录中，或者放在 `ansible.cfg` 中配置的 `shell` 插件目录来源之一中，咱们即可添加该 `shell` 插件。


> <span style="background-color: #f0b37e; color: black"> **警告**：</span>
>
> - <span style="background-color: #ffedcc; color: black">除非默认的 `/bin/sh` 并非 POSIX 兼容的 shell，或其无法执行，否则咱们不应更改所使用的插件。</span>

##
