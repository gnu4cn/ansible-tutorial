# 回调插件

回调插件令到在响应事件时，添加新行为到 Ansible 可行。默认情况下，回调插件控制了运行命令行程序时，咱们所看到的大部分输出，但也可用于添加额外输出、与其他工具集成以及将事件汇聚到某种存储后端。如有必要，你可 [创建定制的回调插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#developing-callbacks)。


## 示例回调插件


[`log_plays`](https://docs.ansible.com/ansible/2.9/plugins/callback/log_plays.html#log-plays-callback) 回调是如何将 playbook 事件记录到某个日志文件的示例，而 [`mail`](https://docs.ansible.com/ansible/2.9/plugins/callback/mail.html#mail-callback) 回调则会在 playbook 失败时发送电子邮件。

[`say`](https://docs.ansible.com/ansible/2.9/plugins/callback/say.html#say-callback) 回调会以一段与 playbook 事件有关的计算机合成语音响应之。


## 启用回调插件


通过将某个定制回调放入 `ansible.cfg` 中配置的回调目录来源之一，或某个专辑中并以 FQCN 在配置中引用他，然后根据其 `NEEDS_ENABLED` 属性，激活该回调。

这些插件会按字母数字顺序加载。例如，在名为 `1_first.py` 文件中实现的某个插件，将在名为 `2_second.py` 的插件文件之前运行。

随 Ansible 提供的大多数回调，默认都是关闭的，需要在咱们的 `ansible.cfg` 文件中启用后才能发挥作用。例如：


```ini
#callbacks_enabled = timer, mail, profile_roles, collection_namespace.collection_name.custom_callback
```

## 给 `ansible-playbook` 设置某个回调插件

咱们只能有一个插件，作为咱们控制台输出的主管理器插件。若咱们打算替换默认的控制台输出主管理器插件，应在子类中定义 `CALLBACK_TYPE = stdout`，然后在 `ansible.cfg` 中配置 `stdout` 插件。例如：


```ini
stdout_callback = dense
```

或者使用咱们的定制回调：

```ini
stdout_callback = mycallback
```

默认这只会影响 `ansible-playbook` 命令。


## 给 ad hoc 命令设置某个插件


`ansible` 临时命令特别为 `stdout` 使用了别的回调插件，因此在 [“Ansible 配置设置”](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 中有个咱们需要添加的额外设置，来使用上面定义的 `stdout` 回调：


```ini
[defaults]
bin_ansible_callback = True
```

咱们也可以一个环境变量，设置这个插件：


```console
export ANSIBLE_LOAD_CALLBACK_PLUGIN=1
```


## 回调插件的类型

有以下三种类型的回调插件：

- `stdout` 的回调插件：这些插件处理主控制台输出。只能有一个是活动的。他们总是会首先获取到事件；其余回调会按配置顺序获取到事件；
- 聚合回调插件，aggregate callback plugins：聚合回调可将一些额外控制台输出，添加到某个 `stdout` 回调后面。这可以是 playbook 运行结束时的一些聚合信息、每个任务的额外输出或其他任何内容；
- 通知回调插件，notification callback plugins：通知回调会通知其他应用程序、服务或系统。这包括日志记录到数据库、在即时信息应用中的通知错误，或在服务器不可达时发送电子邮件等。


## 插件列表

咱们可使用 `ansible-doc -t callback -l` 命令查看可用插件的列表。使用 `ansible-doc -t callback <plugin name>` 命令查看特定插件的文档与示例。


（End）

