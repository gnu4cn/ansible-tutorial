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

请参阅 [Fedora 软件包索引](https://packages.fedoraproject.org/search?query=ansible-collection)，了解 Fedora 中打包的 Ansible 专辑完整列表。

请在 Red Hat Bugzilla 中，[提交](https://bugzilla.redhat.com/enter_bug.cgi) 针对 Fedora `EPEL` 产品的 bug，以便与软件包维护者联系。

### 从 EPEL 安装 Ansible

CentOS Stream、Almalinux、Rocky Linux 以及相关发行版的用户，可以从社区维护的 [EPEL](https://docs.fedoraproject.org/en-US/epel/)（Extra Packages for Enterprise Linux）软件包仓库，安装 `ansible` 或 Ansible 专辑。

在 [启用 EPEL 软件包仓库](https://docs.fedoraproject.org/en-US/epel/#_quickstart) 后，用户就可以使用与 Fedora Linux 相同的 `dnf` 命令了。

{{#include installing_on_distros.md:41}}


## 在 OpenSUSE Tumbleweed/Leap 上安装 Ansible


```console
sudo zypper install ansible
```

请参阅 [OpenSUSE 支持门户](https://en.opensuse.org/Portal:Support)，获取 OpenSUSE 上 Ansible 的更多帮助。


## 在 Ubuntu 上安装 Ansible

Ubuntu 的构建，可在 [此处的 PPA](https://launchpad.net/~ansible/+archive/ubuntu/ansible) 中获取。

要在系统上配置 PPA 并安装 Ansible，请运行以下命令：


```console
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

> **注意**：在较旧版本的 Ubuntu 发行版中，`software-properties-common` 被称为 `python-software-properties`。较旧的版本中，咱们可能需要使用 `apt-get` 而不是 `apt`。此外，请注意只有较新的发行版（即 18.04、18.10 及更高版本）才有 `-u` 或 `--update` 命令行开关。请根据需要调整脚本。

请在 [该 PPA 的问题跟踪程序](https://github.com/ansible-community/ppa/issues) 中，提交任何问题。


## 在 Debian 上安装 Ansible

虽然 Ansible 可从 [Debian 主软件源](https://packages.debian.org/stable/ansible) 中获取，但他可能已经过时。

要获取最新版本，Debian 用户可根据下表，使用 Ubuntu PPA：


| Debian |  | Ubuntu | UBUNTU_CODENAME |
| :-- | :-: | :-- | :-- |
| Debian 12(Bookworm) | -> | Ubuntu 22.04(Jammy) | `jammy` |
| Debian 11(Bullseys) | -> | Ubuntu 20.04(Focal) | `focal` |
| Debian 10(Buster) | -> | Ubuntu 18.04(Bionic) | `bionic` |

在下面的示例中，我们假设已经安装了 `wget` 和 `gpg`（`sudo apt install wget gpg`）。

请运行以下命令，添加软件源并安装 Ansible。根据上表设置 `UBUNTU_CODENAME=...`（本例中使用 `jammy`）。


```console
UBUNTU_CODENAME=jammy
wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list
sudo apt update && sudo apt install ansible
```

请注意：密钥服务器 URL 前后的 `""`（双引号） 很重要。而在 `echo deb` 中用到的 `""` 而不是 `''` 也很重要。

这些命令会下载签名密钥，并在 `apt` 的软件源中添加指向那个 PPA 的条目。


以前，咱们可能会使用 `apt-key add`。出于安全考虑，现在这种方法 [已被弃用](https://manpages.debian.org/testing/apt/apt-key.8.en.html)（在 Debian、Ubuntu 和其他平台上）。更多详情，请参阅 [这个 AskUbuntu 帖子](https://askubuntu.com/a/1307181)。还要注意的是，出于安全考虑，我们不会将密钥添加到 `/etc/apt/trusted.gpg.d/` 或 `/etc/apt/trusted.gpg` 中，因为在那里，密钥将被允许签署来自 **任何** 软件源的发行版本。


## 在 Arch Linux 上安装 Ansible


要安装完整 `ansible` 软件包，请运行：


```console
sudo pacman -S ansible
```

要安装最小 `ansible-core` 软件包，请运行：

```console
sudo pacman -S ansible-core
```

Arch Linux 软件源中还有多个 Ansible 生态系统软件包，用户可将其作为独立软件包，与 `ansible-core` 一起安装。有关 Arch Linux 中 Ansible 软件包的完整列表，请参见 [Arch Linux 软件包索引](https://archlinux.org/packages/?sort=&q=ansible)。


请在相关软件包的 GitLab 仓库中 [开启问题](https://gitlab.archlinux.org/archlinux/packaging/packages)，以联系该软件包维护者。

## 在 Windows 系统上安装 Ansible

Ansible 控制节点不能使用 Windows 系统。请参阅 [Ansible 能否在 Windows 上运行？](https://docs.ansible.com/ansible/latest/os_guide/windows_faq.html#windows-faq-ansible)


（End）


