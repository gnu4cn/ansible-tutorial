# 执行环境入门

像别的现代软件应用程序一样，咱们可以在容器中运行 Ansible 自动化。Ansible 使用称为 “执行环境 (Execution Environment, EE)” 的容器镜像，作为控制节点。EE 消除了扩展自动化项目的复杂性，进而使部署操作这类工作更加简单。

执行环境镜像，包含以下标准软件包：

- `ansible-core`

- `ansible-runner`

- Python

- Ansible 内容依赖

除标准包外，EE 还可以包含：

- 一或多个 Ansible 专辑以及他们的依赖项；

- 其他定制组件。


本入门指南向，展示如何建立及测试一种简单执行环境。生成的容器映像，代表一个 Ansible 控制节点，其中包含：

- 标准 EE 包；

- `community.postgresql` 专辑；

- `psycopg2-binary` Python 包。


## 执行环境介绍

Ansible 执行环境，旨在解决复杂度问题，并提供咱们可从容器化获取到全部好处。

### 降低复杂度

EE 可在三个主要领域，降低复杂性：

- 软件的依赖；

- 可移植性；

- 内容分离。


**依赖问题**

软件应用程序通常都有依赖项，Ansible 也不例外。这些依赖项包括软件库、配置文件或其他服务等。

传统上，管理员会使用 RPM 或 Python-pip 等打包管理工具，在操作系统上安装应用程序依赖项。这种方式的主要缺点，是应用程序所需的依赖项版本，可能与默认提供的版本不同。对于 Ansible，典型的安装由 `ansible-core` 和一组 Ansible 专辑构成。他们中的许多，都有各自所提供插件、模组、角色及 playbook 等组件的依赖项。

Ansible 专辑就可能依赖于以下软件及其版本：

- `ansible-core`

- Python

- Python 包

- 系统软件包

- 别的 Ansible 专辑


这些依赖项必须安装，且有时会相互冲突。


**部分** 解决依赖性问题的一种方法，是在 Ansible 控制节点上使用 Python 虚拟环境。不过，在用于 Ansible 时，虚拟环境有其缺点和天然限制。


**可移植性，portability**

Ansible 用户会在本地编写 Ansible 内容，并希望利用容器技术，使他们的自动化运行时可移植、可共享并可轻松部署到测试和生产环境中。


**内容分离，content separation**

当 Ansible 控制节点或 Ansible AWX/Controller 等工具，被多个用户使用时，他们可能希望将他们的内容分开，以避免配置与依赖的冲突。


## 用于执行环境的 Ansible 工具

Ansible 生态中的一些项目，还提供了一些可与执行环境配合使用的工具，例如：

- [Ansible Builder](https://ansible-builder.readthedocs.io/en/stable/)
- [Ansible Navigator](https://ansible-navigator.readthedocs.io/)
- [Ansible AWX](https://ansible.readthedocs.io/projects/awx/en/latest/)
- [Ansible Runner](https://ansible-runner.readthedocs.io/en/stable/)
- [VS Code Ansible](https://marketplace.visualstudio.com/items?itemName=redhat.ansible)
- [Dev Containers extensions](https://code.visualstudio.com/docs/devcontainers/containers)

## 设置环境

请完成以下步骤，为咱们的第一个执行环境，设置本地环境：


1. 确保咱们系统中安装了以下软件包：

- `podman` 或 `docker`

- `python3`

- `python3-pip`

如果咱们使用 DNF 软件包管理器，请按如下步骤安装这些先决条件：


```console
sudo dnf install -y podman python3 python3-pip
```

2. 安装 `ansible-navigator`：

```console
pip3 install ansible-navigator
```

安装 `ansible-navigator` 可让咱们在命令行上运行 EE。他包括了用于构建 EE 的 `ansible-builder` 软件包。

如果咱们想无需测试情况下构建 EE，则只需安装 `ansible-builder`：

```console
pip3 install ansible-builder
```


3. 使用以下命令验证咱们的环境：

```console
ansible-navigator --version
ansible-builder --version
```

准备好通过几个简单的步骤构建 EE 吗？请前往 [构建咱们的第一个执行环境](#构建咱们的首个执行环境)。

想在无需构建 EE 的情况下试用 EE？请前往 [使用社区 EE 映像运行 Ansible](#community_ee)。


# 构建咱们的首个执行环境

我们将构建一个 EE，他代表一个 Ansible 控制节点，除了 Ansible 专辑（ `community.postgresql` ）及其依赖包（`psycopg2-binary` Python 连接器）外，还包含 `ansible-core` 和 Python 等标准软件包。

要建立咱们的首个 EE：

1. 在文件系统中创建一个项目文件夹；

```console
mkdir my_first_ee && cd my_first_ee
```

2. 创建 `execution-environment.yml` 文件，指定出要包含在镜像中的依赖项；

```yaml
{{#include ../first_ee/execution-environment.yaml}}
```

