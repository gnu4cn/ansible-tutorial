# 在网络模组中使用命令输出与提示符


## 网络模组中的条件


Ansible 允许咱们使用条件，控制 playbook 的流程。Ansible 的网络 `command` 模组，使用了以下这些独特的条件语句。


- `eq` - 等于；
- `neq` - 不等于；
- `gt` - 大于；
- `ge` - 大于等于；
- `lt` - 小于；
- `le` - 小于等于；
- `contains` - 对象包含指定条目。


条件语句会评估在设备上远程执行命令的结果。任务执行了命令集后，`wait_for` 参数可用于在将控制权交回 Ansible playbook 前，对结果加以评估。

比如：


```yaml
{{#include ../../network_run/demo_conditional.yaml}}
```

在上面的示例任务中，`show interface Ethernet4 | json` 命令会在远端设备上执行，且结果会得以评估。如果路径 `(result[0].interfaces.Ethernet4.interfaceStatus)` 不等于 `"onnected"`，则该命令会被重试。这一过程会持续到条件满足，或重试次数已超出（默认情况下，重试次数为 10 次，每次间隔 1 秒）。


> **译注**：在条件检查失败时，会出现以下报错。

```console
TASK [wait for interface to be admin enabled] *************************************************************************************************
fatal: [arista-sw]: FAILED! => {"changed": false, "failed_conditions": ["result[1].interfaces.Ethernet5.interfaceStatus eq connected"], "msg": "One or more conditional statements have not been satisfied"}

```


`command` 模组还可以在一个接口中，评估多组命令结果。例如：


```yaml
{{#include ../../network_run/demo_conditional_multi.yaml}}
```


在上面的示例中，有两个命令在远端设备上执行了，且他们的结果得以评估。通过指定结果的索引值（`0` 或 `1`），正确的结果输出会根据条件得以检查。


`wait_for` 参数必须始终以 `result` 开头，然后是以 `[]` 形式的命令索引，其中 `0` 表示命令列表中的第一条命令，`1` 表示第二条，`2` 表示第三条，以此类推。



## 处理网络模组中的提示符

在对网络设备执行某个更改前，该设备可能要求咱们回应某个提示符。`cisco.ios.ios_command` 和 `cisco.nxos.nxos_command` 等个别网络模组，可使用 `prompt` 参数处理这种情形。


> **注意**：`prompt` 实际上是个 Python 正则表达式。如果咱们在 `prompt` 值中添加了诸如 `?` 这样的特殊字符，那么提示将匹配不了，同时咱们将得到一个超时。为避免出现这种情况，请确保 `prompt` 的值是个与实际设备提示相匹配的 Python 正则表达式。 `prompt` 中的任何特殊字符，都必需得到正确处理。

咱们也可以使用 [`ansible.netcommon.cli_command`](https://docs.ansible.com/ansible/latest/collections/ansible/netcommon/cli_command_module.html#ansible-collections-ansible-netcommon-cli-command-module) ，处理多重提示符。


```yaml
---
- name: multiple prompt, multiple answer (mandatory check for all prompts)
  ansible.netcommon.cli_command:
    command: "copy sftp sftp://user@host//user/test.img"
    check_all: True
    prompt:
      - "Confirm download operation"
      - "Password"
      - "Do you want to change that to the standby image"
    answer:
      - 'y'
      - <password>
      - 'y'
```

> **译注**：译者在思科 IOSXE/NXOS 平台上，尝试实验这种多重提示符始终未获成功。


咱们必须以相同的顺序，列出提示符和答复（即 `prompt[0]` 由 `answer[0]` 答复）。

在上面的示例中，`check_all: True` 确保了该任务给出每个提示符的匹配答复。若没有该设置，那么有着多重提示符的任务，就会将第一个答复，给到每个提示符。


> **译注**：在思科 IOSXE 平台上执行 `copy sftp:` 过程涉及到的提示符如下。

```console
ios-sw#copy sftp:hector@almalinux-61 nvram:inventory.yml
Address or name of remote host [almalinux-61]?
Source username [hector]?
Source filename [hector@almalinux-61]? /home/hector/inventory.yml
Destination filename [inventory.yml]?
Password:
!
497 bytes copied in 7.044 secs (71 bytes/sec)

```

> 而在思科 NXOS 平台上，执行该过程如下。

```console
nxos-sw# copy sftp://hector@almalinux-61/home/hector/inventory.yml volatile:inventory.yml
# 或者 nxos-sw# copy sftp://hector@almalinux-61/home/hector/inventory.yml /inventory.yml
# 默认根目录为 volatile:
Enter vrf (If no input, current vrf 'default' is considered):

hector@192.168.122.61's password:
sftp> progress
Progress meter enabled
sftp> get  /home/hector/inventory.yml  /volatile/inventory.yml
Fetching /home/hector/inventory.yml to /volatile/inventory.yml
/home/hector/inventory.yml                                                                          100%  497     0.5KB/s   00:00
sftp> exit
Copy complete.
```


在下面的示例中，第二个答复就将被忽略，同时 `y` 将是对两个提示符给出的答案。也就是说，因为两个答案相同，这个任务才会生效。还要再次注意的是，提示符必须是 Python 的正则表达式，这就是为什么第一个提示符中的 `?` 会被转义。


```yaml
{{#include ../../network_run/demo_multi-prompts.2nd.yml}}
```

> **译注**：这个任务中的 `prompt:` 选项可以是 `"This command will reboot the system. (y/n)?  [n]"` 里的任意字符串，比如 `"reboot"`、`"This"`、`"reboot"` 等等。


（End）


