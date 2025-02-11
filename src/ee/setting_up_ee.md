# 设置环境

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

想在无需构建 EE 的情况下试用 EE？请前往 [使用社区 EE 映像运行 Ansible](community_ee.md)。


## 构建咱们的首个执行环境

我们将构建一个 EE，他代表一个 Ansible 控制节点，除了 Ansible 专辑（ `community.postgresql` ）及其依赖包（`psycopg2-binary` Python 连接器）外，还包含 `ansible-core` 和 Python 等标准软件包。

要建立咱们的首个 EE：

1. 在文件系统中创建一个项目文件夹；

```console
mkdir my_first_ee && cd my_first_ee
```

2. 创建 `execution-environment.yml` 文件，指定出要包含在镜像中的依赖项；

```yaml
{{#include ../../first_ee/execution-environment.yaml}}
```

> **注意**：`psycopg2-binary` Python 软件包，包含在了该专辑的 `requirements.txt` 文件中。对于不包含 `requirements.txt` 文件的专辑，就需要明确指定出 Python 依赖关系。详情请参阅 [Ansible Builder 文档](https://ansible-builder.readthedocs.io/en/stable/definition/)。

3. 构建出一个名为 `postgresql_ee` 的 EE 容器镜像。

如果使用 `docker`，就要添加 `--container-runtime docker` 参数。


```console
ansible-builder build --tag postgresql_ee
```

4. 列出容器映像，以验证是否成功构建。

```console
> docker images
REPOSITORY                                    TAG       IMAGE ID       CREATED             SIZE
postgresql_ee                                 latest    fd6bc16db1ae   About an hour ago   258MB
...
```

通过检查 `context` 目录中的 `Containerfile` 或 `Dockerfile` 查看其配置，咱们可以验证所创建的镜像。

```console
> less first_ee/context/Dockerfile
{{#include ../../first_ee/context/Dockerfile}}
```

咱们还可以使用 Ansible Navigator，查看镜像的详细信息。

请运行 `ansible-navigator` 命令，在 TUI 中输入 `:images`，然后选择 `postgresql_ee`。


（End）


