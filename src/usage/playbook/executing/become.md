# 掌握权限提升：`become`

Ansible 使用了现有的权限提升系统，来以 root 权限或另一用户的权限执行任务。因为该特性允许咱们 “成为” 不同于登录到机器用户（远程用户）的另一用户，所以我们称之为 `become`。`become` 这个关键字，使用了现有的权限提升工具，如 `sudo`、`su`、`pfexec`、`doas`、`pbrun`、`dzdo`、`ksu`、`runas`、`machinectl` 等。


## 使用 `become`

咱们可通过 `play` 或 `task` 指令、连接变量或命令行等，控制 `become` 的使用。若咱们以多种方式，设置了权限提升属性，请查看 [一般优先规则](https://docs.ansible.com/ansible/latest/reference_appendices/general_precedence.html#general-precedence-rules)，以了解何种设置将被使用。

Ansible 中包含的所有插件完整列表，可在 [插件列表](https://docs.ansible.com/ansible/latest/plugins/become.html#become-plugin-list) 中找到。


### `become` 指令

咱们可以在 play 或任务级别，设置控制 `become` 的指令。可以通过设置连接变量，咱们可覆盖这些指令，不同主机的连接变量往往不同。这些变量和指令是独立的。例如，设置 `become_user` 并不会设置 `become`。


- `become`
设置为 `true` 以激活权限提升。

- `become_user`
设置为有着所需权限的用户 - 咱们要 *成为* 的用户，而 **不是** 咱们登录的用户。这 **不** 意味着在主机级别允许设置的 `become：true`，Does NOT imply `become: true`, to allow it to be set at the host level。默认值为 `root`。

- `become_method`
(于 play 或任务级别）覆盖 `ansible.cfg` 中设置的默认方式，设置为使用某种 [`become` 插件](https://docs.ansible.com/ansible/latest/plugins/become.html#become-plugins)。

- `become_flags`
(于 play 或任务级别）允许对任务或角色，使用特定开关。一种常见的用法是，当 shell 被设置为 `nologin` 时，将用户更改为 `nobody`。是在 Ansible 2.2 中添加的。


例如，以非 root 用户身份连接时，要管理某项系统服务（需要 `root` 权限），就可使用 `become_user` 的默认值（root）：


```yaml
    - name: Ensure the nginx service is running
      service:
        name: nginx
        state: started
      become: true
```

以 `apache` 用户身份运行一条命令：


```yaml
    - name: Run a command as the apache user
      command: somecommand
      become: true
      become_user: apache
```


