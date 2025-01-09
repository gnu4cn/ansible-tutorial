# 安装 Ansible

Ansible 是种无代理自动化工具，an agentless automation tool，可安装于单台主机（称为控制节点）。

通过控制节点，Ansible 可以使用 SSH、Powershell 远程控制及许多其他传输方式，远程管理整个机群与其他设备（称为托管节点），所有这些都可通过简单的命令行界面实现，无需数据库或守护进程。

## 控制节点要求

对于 *控制* 节点（运行 Ansible 的机器），咱们可使用几乎任何安装了 Python 的类 UNIX 机器。这包括 Red Hat、Debian、Ubuntu、macOS、BSD 和 [Windows Subsystem for Linux (WSL) 发行版](https://docs.microsoft.com/en-us/windows/wsl/about) 下的 Windows。不带 WSL 的 Windows 未原生支持作为控制节点；有关更多信息，请参阅 [马特·戴维斯的博客文章](http://blog.rolpdog.com/2020/03/why-no-ansible-controller-for-windows.html)。


## 托管节点要求

托管节点（Ansible 管理的机器）无需安装 Ansible，但需要 Python 来运行 Ansible 生成的 Python 代码。托管节点还需一个可通过 SSH，连接到带有交互式 POSIX shell 节点的用户账号。

> **注意**：在一些模组要求中可能有例外。例如，网络模组就不需要在托管设备上安装 Python。请参阅所用模组的文档。


## 节点要求概要

在 [`ansible-core` 控制节点 Python 支持](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html#support-life)，和 [`ansible-core` 支持](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html#ansible-core-support-matrix) Matrix 会议室小节，咱们可以找到每个 Ansible 版本对控制和托管节点要求的详细信息，包括 Python 版本。


## 选择要安装的 Ansible 软件包和版本


Ansible 的社区软件包，以两种方式分发：

- `ansible-core`: 是一种最小语言和运行包，包含一套 [内置的模组和插件](collections/ansible_builtin.md)；

- `ansible`：是一个更大的 “弹夹装满，batteries included” 软件包，其中增加了一套社区精选的 Ansible 专辑，用于自动化各种设备。

请选择适合咱们需要的软件包。以下说明使用 `ansible` 作为软件包名称，但如果咱们想从最小软件包开始，则可以代之以 `ansible-core`,而单独安装咱们所需的 Ansible 专辑。

`ansible` 或 `ansible-core` 软件包可能已在咱们操作系统的软件包管理器中，咱们可以用自己喜欢的方法，安装这些软件包。更多信息，请参阅 [在特定操作系统上安装 Ansible](#在特定操作系统上安装-Ansible) 指南。下面这些安装说明仅涵盖官方支持的，使用 `pip` 安装 python 软件包的方法。


有关软件包中所包含的 `ansible-core` 版本，请参阅 [Ansible 软件包发布状态表](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html#ansible-changelogs)。


## 使用 `pipx` 安装和升级 Ansible

在某些系统上，由于操作系统开发人员的决定，可能无法使用 `pip` 安装 Ansible。在这种情况下，`pipx` 是种广泛使用的替代方案。


本教程将不再赘述安装 `pipx` 的步骤；如果需要这些说明，请继续阅读 [`pipx` 安装说明](https://pypa.github.io/pipx/installation/) 以获取更多信息。

> **译注**： 在使用 `pyenv` 下，应如下安装 `pipx`。


```console
python3 -m pip install --user pipx
python3 -m pipx ensurepath
sudo pipx ensurepath --global # optional to allow pipx actions with --global argument
```

并使用命令 `python3 -m pip install --user --upgrade pipx` 升级 `pipx`。


> **参考**：[Install pipx](https://pipx.pypa.io/stable/)


### 安装 Ansible

请在咱们的环境中，使用 `pipx` 安装完整的 Ansible 软件包：


```console
> pipx install --include-deps ansible
  installed package ansible 11.1.0, installed using Python 3.12.7
  These apps are now globally available
    - ansible
    - ansible-community
    - ansible-config
    - ansible-console
    - ansible-doc
    - ansible-galaxy
    - ansible-inventory
    - ansible-playbook
    - ansible-pull
    - ansible-test
    - ansible-vault
done! ✨ 🌟 ✨
```

> **译注**： 该命令的输出中有很多告警，是因为系统中先前已经安装过 Ansible。

咱们可安装最小的 `ansible-core` 包：

```console
pipx install ansible-core
```

咱们也可安装某个特定版本的 `ansible-core`：

```console
pipx install ansible-core==2.12.3
```


### 升级 Ansible

把某个既有 Ansible 安装，升级到最新发布的版本：


```console
pipx upgrade --include-injected ansible
```

### 安装额外的 Python 依赖项

以安装 `argcomplete` 这个 python 软件包为例，安装可能需要的其他 python 依赖项：


```console
> pipx inject ansible argcomplete
  injected package argcomplete into venv ansible
done! ✨ 🌟 ✨
```

包含 `--include-apps` 选项可使额外 python 依赖关系中的应用程序，在咱们 `PATH` 中可用。这样就可以在 shell 中执行这些应用程序的命令。


```console
pipx inject --include-apps ansible argcomplete
```


## 使用 `pip` 安装和升级 Ansible


### 找到 Python

找到并记住用于运行 Ansible 的 Python 解释器路径。以下教程将该 Python 作为 `python3`。例如，如果确定要在 `/usr/bin/python3.9` 下安装 Ansible，就要指定该 Python，而不是 `python3`。


### 确保 `pip` 可用

要验证咱们首选的 Python 是否已安装 `pip`：

```console
> python3 -m pip -V
pip 24.3.1 from /home/hector/.pyenv/versions/3.12.7/lib/python3.12/site-packages/pip (python 3.12)
```

如果是这样，那么 `pip` 就可用，咱们可以继续 [下一步](#installing_ansible_pip)。

如果出现 `No module named pip` 这样的错误，那么在继续之前，咱们需要在所选的 Python 解释器下安装 `pip`。这可能意味着要安装一个额外的操作系统软件包（例如，`python3-pip`），或直接从 [Python 打包管理局](https://www.pypa.io/)，安装最新的 `pip`，方法如下：


```console
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py --user
```

在运行 Ansible 之前，咱们可能需要执行一些额外配置。更多信息，请参阅有关 [安装到用户处，installing to the user site](https://packaging.python.org/tutorials/installing-packages/#installing-to-the-user-site) Python 文档。

<a name="installing_ansible_pip"></a>
### 安装 Ansible

在咱们所选的 Python 环境中，使用 `pip` 为当前用户安装完整的 Ansible 软件包：


```console
python3 -m pip install --user ansible
```

咱们可为当前用户，安装最小的 `ansible-core` 软件包：

```console
python3 -m pip install --user ansible-core
```

咱们也可以安葬某个指定版本的 `ansible-core`:

```console
python3 -m pip install --user ansible-core=2.12.3
```


### 升级 Ansible


要将此 Python 环境中现有的 Ansible 安装，升级到最新发布的版本，只需在上述命令中添加 `--upgrade` 即可：


```console
python3 -m pip install --upgrade --user ansible
```


## 将 Ansible 安装到容器


与手动安装 Ansible 内容不同，咱们可简单地构建出一个执行环境容器镜像，或使用某个可用的社区镜像作为控制节点即可。详情请参阅 [执行环境入门](ee.md)。


## 用于开发的安装

如果咱们正测试新功能、修复漏洞，或与开发团队合作修改核心代码，则可以从 GitHub 安装并运行源代码。

> **注意**：请只在修改 `ansible-core` 或试用开发中的功能时，才安装并运行 `devel` 分支。这是个快速变化的代码源，随时可能变得不稳定。

有关参与 Ansible 项目的更多信息，请参阅 [Ansible 社区指南](https://docs.ansible.com/ansible/latest/community/index.html#ansible-community-guide)。

有关创建 Ansible 模组与专辑的更多信息，请参阅 [开发人员指南](dev_guide.md)。


### 使用 `pip` 从 GitHub 安装 `devel`

咱们可以使用 `pip`，直接从 GitHub 安装 `ansible-core` 的 `devel` 分支：

```console
python3 -m pip install --user https://github.com/ansible/ansible/archive/devel.tar.gz
```

咱们可以用 GitHub 上的任何其他分支或标记，替换上述 URL 中的 `devel`，以安装 Ansible 的旧版本、`alpha` 或 `beta` 标记版本以及候选发布版本。


### 从某个克隆运行 `devel` 分支

`ansible-core` 易于源代码运行。使用他无需 `root` 权限，也不需要实际安装什么软件。无需守护进程或数据库设置。


1. 克隆出 `ansible-core` 存储库；

```console
git clone https://github.com/ansible/ansible.git
cd ./ansible
```

2. 设置 Ansible 环境；

- 使用 Bash；

```console
source ./hacking/env-setup
```

- 使用 Fish；

```console
source ./hacking/env-setup.fish
```

- 要消除某些虚假警告/错误，请使用 `-q` 参数。

```console
source ./hacking/env-setup -q
```


3. 安装 Python 依赖项；

```console
python3 -m pip install --user -r ./requirements.txt
```

4. 更新本地计算机上 `ansible-core` 的 `devel` 分支。

```console
git pull --rebase
```


## 确认安装


咱们可通过检查版本，来测试 Ansible 是否已正确安装：

```console
ansible --version
```

该命令显示的版本，是已安装的相关 `ansible-core` 软件包的版本。

检查已安装的 `ansible` 软件包的版本：

```console
> ansible-community --version
Ansible community version 11.1.0
```

## 添加 Ansible 命令 shell 补全

通过安装名为 `argcomplete` 的可选依赖项，可以为 Ansible 命令行实用工具，添加 shell 补全功能。他支持 `bash`，对 `zsh` 和 `tcsh` 的支持有限。


有关安装和配置的更多信息，请参阅 [`argcomplete` 文档](https://kislyuk.github.io/argcomplete/)。

### 安装 `argcomplete`

如果咱们选择的是 `pipx` 安装教程：

```console
pipx inject --include-apps ansible argcomplete
```

如果咱们选择的是 `pip` 安装教程：


```console
python3 -m pip install --user argcomplete
```

### 配置 `argcomplete`

有两种种方法可以配置 `argcomplete`，来实现 Ansible 命令行实用程序的 shell 补全：全局方式，或依命令方式。


- **全局的配置**

全局补全需要 `bash` 4.2。

```console
activate-global-python-argcomplete --user
```

这会将一个 `bash` 补全文件，写入用户位置。使用 `--dest` 更改位置，或使用 `sudo` 设置系统全局补全。

- **依命令的配置**

如果没有 `bash` 4.2，则必须单独注册每个脚本。


```console
eval $(register-python-argcomplete ansible)
eval $(register-python-argcomplete ansible-config)
eval $(register-python-argcomplete ansible-console)
eval $(register-python-argcomplete ansible-doc)
eval $(register-python-argcomplete ansible-galaxy)
eval $(register-python-argcomplete ansible-inventory)
eval $(register-python-argcomplete ansible-playbook)
eval $(register-python-argcomplete ansible-pull)
eval $(register-python-argcomplete ansible-vault)
```

应将上述命令，放入 shell 的配置文件中，如 `~/.profile` 或 `~/.bash_profile`。


### 在 `zsh` 或 `tcsh` 中使用 `argcomplete`

请参阅 [`argcomplete` 文档](https://kislyuk.github.io/argcomplete/)。


（End）


