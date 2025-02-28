# 使用 Ansible 管理 BSD 主机

管理 BSD 机器不同于管理其他类 Unix 机器。如果咱们曾管理过运行 BSD 的节点，请查看这些主题。


## 连接到 BSD 节点


Ansible 默认使用 OpenSSH 连接托管节点。若咱们使用 SSH 密钥进行身份验证，这在 BSD 上是可行的。但是，若咱们使用 SSH 密码进行身份验证，Ansible 就会依赖 `sshpass`。大多数版本的 `sshpass` 不能很好地处理 BSD 登录提示符，因此对 BSD 机器使用 SSH 密码时，就要使用 `paramiko` 而不是 OpenSSH 进行连接。咱们可在 `ansible.cfg` 中做到这点，也可将其设置为仓库/组/主机变量。例如：


```ini
[freebsd]
myfreebsdhost ansible_connection=paramiko
```

## 引导 BSD

**Bootstrapping BSD**


Ansible 默认是无代理的，但需要托管节点上的 Python。只有 [`raw`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/raw_module.html#raw-module) 这个模组，可以在没有 Python 的情况下运行。虽然该模组可用于引导 Ansible，并在 BSD 的那些变种上安装 Python（见下文），但其极其有限，必须使用 Python 才能充分利用 Ansible 的功能。


以下示例会安装 Python，其中包含了实现 Ansible 全部功能所需的 `json` 库。在咱们的控制机器上，咱们可为大多数版本的 FreeBSD，执行以下操作：


```console
ansible -m raw -a "pkg install -y python" freebsd-14 -bK -i playbook_executing/inventory.yml
```

或对于 OpenBSD：


```console
ansible -m raw -a "pkg_add -I python%3.11" myopenbsdhost
```

此操作完成后，咱们就可以使用 `raw` 模组以外的其他 Ansible 模组了。


> **注意**：这个示例演示了在 FreeBSD 上使用 `pkg` 和在 OpenBSD 上使用 `pkg_add`，然而，咱们应能替换为咱们 BSD 的适当软件包工具；软件包的名字也可能不同。有关咱们打算安装的 Python 软件包确切名字，请参阅咱们所使用 BSD 变种的软件包列表或文档。


## 设置 Python 解释器

为支持各种类 Unix 操作系统与发行版，Ansible 无法始终依赖现有的环境或 `env` 变量，定位正确的 Python 二进制文件。默认情况下，模组会指向 `/usr/bin/python`，因为这是最常见的位置。而在 BSD 的那些变种上，这个路径就可能不同，因此建议将这个二进制文件的位置告知 Ansible。参见 [`INTERPRETER_PYTHON`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#interpreter-python)。例如，设置 `ansible_python_interpreter` 这个仓库变量：


```ini
[freebsd:vars]
ansible_python_interpreter=/usr/local/bin/python
[openbsd:vars]
ansible_python_interpreter=/usr/local/bin/python3
```


### FreeBSD 的软件包与 ports

在 FreeBSD 中，无法保证默认安装了 `/usr/local/bin/python` 这个可执行文件，或到某个可执行文件的链接。对于 Ansible 而言，对于某个远端主机的最佳做法，是至少要安装 Ansible 所支持的 Python 版本，比如 `lang/python311`，以及 `lang/python3` 与 `lang/python` 这两个元 ports。以下内容引自 `/usr/ports/lang/python3/pkg-descr`：


```text
This is a meta port to the Python 3.x interpreter and provides symbolic links
to bin/python3, bin/pydoc3, bin/idle3 and so on to allow compatibility with
minor version agnostic Python scripts.
```

以下内容引自 `/usr/ports/lang/python/pkg-descr`：


```text
This is a meta port to the Python interpreter and provides symbolic links
to bin/python, bin/pydoc, bin/idle and so on to allow compatibility with
version agnostic python scripts.
```


结果，就安装了以下这些软件包：


```console
$ pkg info | grep python
python-3.11_3,2                "meta-port" for the default version of Python interpreter
python3-3_4                    Meta-port for the Python interpreter 3.x
python311-3.11.11              Interpreted object-oriented programming language
```


以及以下这些可执行文件与链接：

```console
$ ll /usr/local/bin/ | grep python
lrwxr-xr-x   1 root wheel uarch      7 Jan 31 16:25 python@ -> python3
lrwxr-xr-x   1 root wheel uarch     14 Jan 31 16:25 python-config@ -> python3-config
lrwxr-xr-x   1 root wheel uarch     10 Jan 30 09:40 python3@ -> python3.11
lrwxr-xr-x   1 root wheel uarch     17 Jan 30 09:40 python3-config@ -> python3.11-config
-r-xr-xr-x   1 root wheel uarch   4744 Jan 30 09:15 python3.11*
-r-xr-xr-x   1 root wheel uarch   3113 Jan 30 09:15 python3.11-config*
```


### `INTERPRETER_PYTHON_FALLBACK`

自版本 2.8 开始，Ansible 提供了个，用于指定检索 Python 的路径列表的有用变量 `ansible_interpreter_python_fallback`。参见 [`INTERPRETER_PYTHON_FALLBACK`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#interpreter-python-fallback)。该列表将被检索，而所找到的第一个项目将被使用。例如，下面的配置将使上一节中的元 ports 安装具有冗余，也就是说，若咱们不安装那些 Python 的元 ports，那么该列表中的前两项将被跳过，而 `/usr/local/bin/python3.11` 将被发现。


```ini
ansible_interpreter_python_fallback=['/usr/local/bin/python', '/usr/local/bin/python3', '/usr/local/bin/python3.11']
```


咱们可以使用这个被 Python 的那些较低版本延长的变量，并将其放到比如 `group_vars/all` 中。然后，若有需要，在 `group_vars/{group1，group2，...}` 中为特定组别覆盖此变量，或在在 `host_vars/{host1, host2, ...}` 中为特定主机覆盖他。请参阅 [变量优先级： 我应该把变量放在哪里？](../playbook/using/vars.md#变量优先级我该把变量放在哪里)。


### 调试 Python 的发现


例如，对于下面这个给定仓库：


```ini
[test]
test_11
test_12
test_13

[test:vars]
ansible_connection=ssh
ansible_user=admin
ansible_become=true
ansible_become_user=root
ansible_become_method=sudo
ansible_interpreter_python_fallback=['/usr/local/bin/python', '/usr/local/bin/python3', '/usr/local/bin/python3.11']
ansible_perl_interpreter=/usr/local/bin/perl
```

有以下 playbook：


```yaml
# playbook.yml
- hosts: freebsd-14
  gather_facts: false
  tasks:
    - command: which python
      register: result
    - debug:
        var: result.stdout
    - debug:
        msg: |-
          {% for i in _vars %}
          {{ i }}:
            {{ lookup('vars', i)|to_nice_yaml|indent(2) }}
          {% endfor %}
      vars:
        _vars: "{{ query('varnames', '.*python.*') }}"
```

就会显示出以下详细信息：


```console
$ ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i playbook_executing/inventory.yml playbook_executing/playbook.yml -bK
BECOME password:

PLAY [freebsd-14] **************************************************************************************************************

TASK [command] *****************************************************************************************************************
changed: [freebsd-14]

TASK [debug] *******************************************************************************************************************
ok: [freebsd-14] =>
  result.stdout: /usr/local/bin/python

TASK [debug] *******************************************************************************************************************
ok: [freebsd-14] =>
  msg: |-
    ansible_python_interpreter:
      /usr/local/bin/python

    ansible_interpreter_python_fallback:
      - /usr/local/bin/python
      - /usr/local/bin/python3
      - /usr/local/bin/python3.11

    ansible_playbook_python:
      /home/hector/.pyenv/versions/3.12.7/bin/python3.12

PLAY RECAP *********************************************************************************************************************
freebsd-14                 : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

咱们可以看到，列表 `ansible_interpreter_python_fallback` 中的第一个条目，就在 FreeBSD 远端主机上发现了。变量 `ansible_playbook_python` 保存了运行该 playbook 的 Linux 控制节点的 Python 路径。

关于其中的告警信息，以下内容引自 [`INTERPRETER_PYTHON`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#interpreter-python)：

```text
The fallback behavior will issue a warning that the interpreter
should be set explicitly (since interpreters installed later may
change which one is used). This warning behavior can be disabled by
setting auto_silent or auto_legacy_silent. ...
```

> **译注**：原文中该 playbook 的输出中的 `[command]` 小节有告警信息，但译者在 FreeBSD 14.2 上实验时并没有。该告警信息如下。

```console
TASK [command] *******************************************************************************
[WARNING]: Platform freebsd on host test_11 is using the discovered Python interpreter at
/usr/local/bin/python, but future installation of another Python interpreter could change the
meaning of that path. See https://docs.ansible.com/ansible-
core/2.18/reference_appendices/interpreter_discovery.html for more information.
changed: [test_11]
```

咱们既可以忽略该告警信息，也可通过设置变量 `ansible_python_interpreter=auto_silent` 来消除他，因为使用 `/usr/local/bin/python` 正是咱们想要的（ *“以后安装的解释器可能会改变使用的解释器”* ）。例如：


```ini
[test]
test_11
test_12
test_13

[test:vars]
ansible_connection=ssh
ansible_user=admin
ansible_become=true
ansible_become_user=root
ansible_become_method=sudo
ansible_interpreter_python_fallback=['/usr/local/bin/python', '/usr/local/bin/python3', '/usr/local/bin/python3.11']
ansible_python_interpreter=auto_silent
ansible_perl_interpreter=/usr/local/bin/perl
```


> **译注**：可将 `ansible_python_interpreter=auto_silent` 设置为组变量或主机变量，即可生效。


> ***参考***：
>
> - [解释器发现](https://docs.ansible.com/ansible/latest/reference_appendices/interpreter_discovery.html#interpreter-discovery)
>
> - [FreeBSD wiki: Ports/`DEFAULT_VERSIONS`](https://wiki.freebsd.org/Ports/DEFAULT_VERSIONS)



### 其余变量

若咱们用到了某些除 Ansible 捆绑插件以外的其他插件，那么咱们可根据插件的编写方式，为 `bash`、`perl` 或 `ruby` 等，设置一些类似的变量。例如：


```ini
[freebsd:vars]
ansible_python_interpreter=/usr/local/bin/python
ansible_perl_interpreter=/usr/local/bin/perl
```


## 有哪些可用的模组？


大多数 Ansible 核心模组，都是针对类 Unix 机器与其他通用服务的组合编写的，因此除了明显针对 Linux 技术的模组（如 [LVG](https://docs.ansible.com/ansible/latest/collections/community/general/lvg_module.html)）外，大多数模组都应能在 BSD 上正常运行。



## 使用 BSD 作为控制节点


使用 BSD 作为控制机器非常简单，只需为咱们的 BSD 变种安装 Ansible 软件包，或依照 [`pip`](../../installing.md#使用-pip-安装和升级-ansible) 或 “从源代码” 的说明进行安装即可。


## BSD 的事实

Ansible 从 BSD 收集信息的方式，与 Linux 机器类似，但由于网络、磁盘和其他设备的数据、名字及结构等可能不同，因此输出结果可能略有不同，但对于 BSD 管理员来说仍是熟悉的。


## BSD 的努力与贡献

在 Ansible，BSD 的支持对我们非常重要。尽管我们的大多数贡献者都使用 Linux 并以其为目标平台，但我们也有个活跃的 BSD 社区，并努力做到对 BSD 尽可能友好。请随时报告您发现的任何问题或与 BSD 的不兼容性；我们也欢迎包含修复的拉取请求！


（End）


