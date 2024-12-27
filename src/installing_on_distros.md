# 在特定操作系统上安装 Ansible

> **注意**：这些教程都是由相应社区所提供。任何错误/问题都应提交给该社区，以便更新这些教程。Ansible 仅维护 `pip` 安装教程。

大多数系统都可以 [使用 `pip` 从 PyPI 安装](installing.md#使用-pip-安装和升级-ansible) `ansible` 软件包，但社区也为各种 Linux 发行版，打包和维护了该软件包。

本文档指导咱们，从不同发行版的软件包仓库安装 Ansible。


要在本指南中添加其他发行版的教程，软件包维护者 **必须** 完成以下操作：

- 确保发行版提供最新的 `ansible` 版本;

- 在构建系统允许的范围内，确保 `ansible-core` 和 `ansible` 版本保持同步；

- 要作为教程的一部分，提供联系发行版维护者的某种方式。我们也鼓励发行版维护者，加入 [Ansible 打包](https://matrix.to/#/#packaging:ansible.com) 的 Matrix 会议室。


## 在 Fedora Linux 上安装 Ansible

要安装完整 `ansible` 软件包，请运行：

```console
sudo dnf install ansible
```

要安装最小 `ansible-core` 软件包，请运行：

```console
sudo dnf install ansible-core
```

Fedora 软件仓库中还有数个 Ansible 专辑，用户可以将他们作为独立软件包，与 `ansible-core` 一起安装。例如，要安装 `community.general` 套件，请运行：

```console
sudo dnf install ansible-collection-community-general
```


