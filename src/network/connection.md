# 使用网络连接选项


网络模组可支持多种连接协议，比如 `ansible.netcommon.network_cli`、`ansible.netcommon.netconf` 及 `ansible.netcommon.httpapi` 等。这些连接均包括一些，咱们可以通过设置以控制与网络设备连接行为的共同选项。


一些共同选项有：

- [权限提升：`enable` 模式、`become` 与 `authorize`](difference.md#权限提升enable-模式become-与-authorize) 中所述的 `become` 和 `become_method`；
- `network_os` - 设置为咱们与之通信的网络平台相匹配。请参阅 [特定平台](https://docs.ansible.com/ansible/latest/network/user_guide/platform_index.html#platform-options) 页面；
- [设置远端用户](../usage/connection.md#设置远端用户) 中所描述的 `remote_user`；
- 超时选项 - `persistent_command_timeout`、`persistent_connect_timeout` 与 `timeout`。


## 设置超时选项


在与某个远端设备通信时，咱们可控制 Ansible 与该设备保持连接的时间，以及 Ansible 等待该设备上某条命令完成的时间。这些选项都可以设置为 playbook 文件中的变量、环境变量或 `ansible.cfg` 文件中的设置项。

例如，控制连接超时的三个选项如下所示。


使用 `vars`（每任务下）：


```yaml
- name: save running-config
  cisco.ios.ios_command:
    commands: copy running-config startup-config
  vars:
    ansible_command_timeout: 30
```

使用环境变量：

```console
$ export ANSIBLE_PERSISTENT_COMMAND_TIMEOUT=30
```

使用全局配置（于 `~/.ansible.cfg` 中）：

```ini
[persistent_connection]
command_timeout = 30
```

请参阅 [变量优先级：我应该把变量放在哪里？](../usage/playbook/using/vars.md#变量优先级我该把变量放在哪里) ，了解有关这些变量的相对优先级的详细信息。参阅每种连接类型以掌握每个选项。


（End）


