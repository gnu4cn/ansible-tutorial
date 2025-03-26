# Galaxy 用户手册

*Ansible Galaxy* 指的是 [Galaxy](https://galaxy.ansible.com/) 网站，这是个用于查找、下载和共享社区开发的专辑与角色的免费网站。


使用 Galaxy，利用来自 Ansible 社区的精彩内容启动咱们的自动化项目。Galaxy 提供预打包的工作单元，如 [角色](usage/playbook/using/roles.md) 与 [专辑](usage/collection.md)。专辑这种格式，提供了一个全面的自动化包，其中可能包括多个 playbook、角色、模组和插件。有关 Galaxy 的详细信息，请参阅 [Galaxy 文档](https://ansible.readthedocs.io/projects/galaxy-ng/en/latest/)。


## 在 Galaxy 上查找专辑


要在 Galaxy 上找到专辑：

1. 单击左侧导航栏中的 `Collections -> Collections`；
2. 输入咱们的检索词。咱们可以按关键词、标签与命名空间进行筛选。


Galaxy 会给出符合咱们检索条件的专辑列表。


有关安装和使用专辑的完整详情，请参阅 [使用 Ansible 专辑](./collections.md)。


## 在 Galaxy 上查找角色


要查找独立角色（即不属于某个专辑的角色）：

1. 单击左侧导航栏中的 `Roles -> Roles`；
2. 输入咱们的检索词。咱们可以按关键词、标签与命名空间进行筛选。

Galaxy 会给出符合咱们检索条件的角色列表。


咱们可以选择使用 `ansible-galaxy` 这个 CLI 命令，按标签、平台、作者等，以多个关键字检索 Galaxy 数据库。

这个搜索命令将返回符合检索条件的前 1000 个结果列表：


```console
$ ansible-galaxy role search ibm

Found 22 roles matching your search:

 Name                                      Description
 ----                                      -----------
 fperreau.ibm_resiliency_orchestration_drm IBM Resiliency Orchestration Disaster Recover Manager install
 jpcasas.ibm_mq                            Ansible Role Install IBM MQ. installs from - IBM Repo (version 9.1.5)  - IBM Repo searching for latest>
 kamaxeon.libmbus                          Install libmbus developed by rscada
 kostyrev.ibm-dsa                          Installs IBM DSA
 mm0.ibm-integration-bus                   Ansible Role that installs IBM Integration Bus on RHEL/Centos using locally provided installation pack>
 mm0.ibm-websphere-mq                      Ansible Role that installs IBM Websphere MQ on RHEL/Centos using locally provided installation package>
 penguinperk.ibm_terraform_provider        Deploys the IBM Cloud Terraform Provider
 sakibmoon.ansible_wordpress_install       Install multiple wordpress via wp-cli in Debian/Ubuntu based system
 sakibmoon.fail2ban                        An ansible role to install and manage Fail2ban
 sakibmoon.users                           Ansible role to manage(create/delete/modify) users
 sgwilbur.ibm-installation-manager         An Ansible role for installing IBM Installation Manager.
 computate.computate_libmodplug            Install a more recent version of libmodplug
 djorgen_ibm.isam_ansible_roles            A set of roles to leverage ibmsecurity package for managing ISAM appliances
 dlemaireibm.pingdl                        IT architect automation
 gustavo_ribmartins.httpd_amzlinux         your role description
 gustavo_ribmartins.pointer_app            your role description
 ibm.infosvr                               Automates the deployment and configuration of IBM Information Server
 ibm.infosvr-import-export                 Automates extraction and loading of content and structures within Information Server
 ibm.infosvr-metadata-asset-manager        Automates data connectivity configuration through IBM Metadata Asset Manager
 ...
```


### 获取更多有关某个角色的信息

使用 `info` 命令查看某个特定角色的更多细节信息：


```console
$ ansible-galaxy role info jpcasas.ibm_mq

Role: jpcasas.ibm_mq
        description: Ansible Role Install IBM MQ. installs from - IBM Repo (version 9.1.5)  - IBM Repo searching for latest version  - From a File
        commit: fe57198621dfda407bc2b7379f2a494786220c6d
        commit_message: Update README.md
        created: 2023-05-08T21:02:50.536249Z
        download_count: 65
        github_branch: master
        github_repo: ibm-mq-ansible-role
        github_user: jpcasas
        id: 15015
        imported: 2022-12-08T13:15:16.534165-05:00
        modified: 2023-10-29T18:45:40.453659Z
        path: ('/home/hector/.ansible/roles', '/usr/share/ansible/roles', '/etc/ansible/roles')
        upstream_id: 61109
        username: jpcasas
```


## 安装 Galaxy 上的角色


Ansible 捆绑了 `ansible-galaxy` 命令与，咱们可以用他安装 Galaxy 上的角色，或直接从基于 Git 的 SCM 安装角色。咱们还可以用他创建新角色、移除角色或在 Galaxy 网站上执行任务。


默认情况下，这个命令行工具使用服务器地址 https://galaxy.ansible.com 与 Galaxy 网站的 API 通信。如果咱们运行了自己的内部 Galaxy 服务器，并希望使用他代替这个默认服务器，就要通过 `--server` 选项，并在其后输入该 Galaxy 服务器的地址。咱们可通过在 `ansible.cfg` 文件中，设置 Galaxy 服务器值来永久设置该选项。有关在 `ansible.cfg` 文件中设置 Galaxy 服务器值的详情，请参阅 [`GALAXY_SERVER`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy-server)。


### 安装角色


使用 `ansible-galaxy` 命令下载 [Galaxy 网站](https://galaxy.ansible.com/) 上的角色：


```console
ansible-galaxy role install namespace.role_name
```


**设置安装角色于何处**


默认情况下，Ansible 会将角色下载到默认路径列表 `~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles`，中的第一个可写入目录 。这会将角色安装到运行 `ansible-galaxy` 用户的主目录下。


咱们可使用以下选项之一，覆盖此行为：

- 设置咱们会话中的环境变量 `ANSIBLE_ROLES_PATH`；
- 使用 `ansible-galaxy` 命令的 `--roles-path` 选项；
- 在 `ansible.cfg` 文件中定义 `roles_path` 变量。


下面提供了一个如何使用 `--roles-path` 命令行选项，将角色安装到当前工作目录的示例：


```console
$ ansible-galaxy role install --roles-path . geerlingguy.apache
```


### 安装某个角色的特定版本


在 Galaxy 服务器导入某个角色时，他会导入任何符合 [语义版本，Semantic Version](https://semver.org/) 格式全部 Git 标签作为版本号。反过来，咱们就也可以通过指定其中一个导入的标签，下载到某个角色的特定版本。


要查看某个角色的可用版本：

1. 在 Galaxy 的检索页面找到该角色；
2. 点击角色名字，查看更多详请，其中就包括了可用的版本。



要安装 Galaxy 上某个角色的特定版本，就要添加逗号以及 GitHub 发布标签的值。例如：


```console
$ ansible-galaxy role install geerlingguy.apache,3.2.0
```


直接指向角色的 Git 仓库，并指定分支名称或某个提交哈希值作为版本也是可行的。例如，以下命令将安装某个特定提交：

```console
$ ansible-galaxy role install git+https://github.com/geerlingguy/ansible-role-apache.git,0b7cd353c0250e87a26e0499e59e7fd265cc2f25
```

### 安装一个文件中的多个角色


通过在某个 `requirements.yml` 文件中包含一些角色，咱们就可以安装这多个角色。该文件格式为 YAML，文件扩展名必须是 `.yml` 或 `.yaml`。

要使用以下命令，安装 `requirements.yml` 中包含的角色：


```console
$ ansible-galaxy install -r requirements.yml
```


同样，扩展名也很重要。如果不使用 `.yml` 的扩展名，`ansible-galaxy` CLI 就会认为该文件采用的是较早的、现已启用的 “基本” 格式。


该文件中的每个角色，都将有着以下一个或多个属性：

- `src`

角色的来源。若从 Galaxy 下载，就要使用 `namespace.role_name` 格式；否则，就要提供一个指向基于 Git 的 SCM 中某个代码仓库的 URL。请参阅下面的示例。此为必需属性。


- `scm`

指定 SCM。目前只允许使用 `git` 或 `hg`。请参阅下面的示例。默认为 `git`。


- `version`

要下载的角色版本。要提供某个发布的标签值、提交哈希值或分支名称。默认为代码仓库中设置为默认的分支，否则默认为 `master`/`main`。


- `name`


将该角色下载到某个指定名字。从 Galaxy 下载时默认为 Galaxy 的名字，否则默认为代码仓库的名字。

请使用下面的示例，作为在 `requirements.yml` 中指定出角色的指南：

```yaml
{{#include ./demo_requirements.yml}}
```

> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> 将凭据嵌入到 URL 中嵌入到 SCM URL 中不安全。出于安全考虑，请确保使用安全的认证选项。例如，在 Git 配置中使用 [SSH](https://help.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh)、[`netrc`](https://linux.die.net/man/5/netrc) 或 [`http.extraHeader`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpextraHeader)/[`url.<base>.pushInsteadOf`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-urlltbasegtpushInsteadOf)，防止凭据暴露在日志中。


### 安装同一 `requirements.yml` 文件中的角色与专辑


咱们可以安装同一需求文件中的角色与专辑：


```yaml
---
roles:
  # Install a role from Ansible Galaxy.
  - name: geerlingguy.java
    version: "1.9.6" # note that ranges are not supported for roles

collections:
  # Install a collection from Ansible Galaxy.
  - name: community.general
    version: ">=7.0.0"
    source: https://galaxy.ansible.com
```

### 安装多个文件中的角色

对于大型项目，`requirements.yml` 文件中的 `include` 指令，提供了将大文件拆分成多个小文件的能力。


例如，某个项目可能有个 `requirements.yml` 文件与一个 `webserver.yml` 文件。


下面是 `webserver.yml` 文件的内容：


```yaml
# from github
- src: https://github.com/bennojoy/nginx

# from Bitbucket
- src: git+https://bitbucket.org/willthames/git-ansible-galaxy
  version: v1.4
```


下面显示的是现在包含了 `webserver.yml` 文件的 `requirements.yml` 文件内容：


```yaml
# from galaxy
- name: yatesr.timezone
- include: <path_to_requirements>/webserver.yml
```


要安装这两个文件中的所有角色，就要命令行中传递根文件，这个示例中为 `requirements.yml`，如下所示：


```console
$ ansible-galaxy role install -r requirements.yml
```

### 依赖项

角色也可以依赖其他角色，当咱们安装某个有依赖项的角色时，这些依赖项会自动安装到 `roles_path` 中。


定义角色依赖项的方式有两种：


- 使用 `meta/requirements.yml`；
- 使用 `meta/main.yml`。

**使用 `meta/requirements.yml`**

*版本 2.0 中新增特性*。

咱们可以创建文件 `meta/requirements.yml`，并按照 [安装一个文件中的多个角色](#安装一个文件中的多个角色) 小节中描述的 `requirements.yml` 的同样格式，定义出依赖项。


在这里，咱们就可以导入或包含那些咱们任务中的指定角色。


**使用 `meta/main.yml`**

或者，咱们也可以通过在 `meta/main.yml` 文件的 `dependencies` 小节，提供一个角色列表，指定出角色依赖项。如果某个角色的来源是 Galaxy，则只需以 `namespace.role_name` 格式指定出该角色即可。咱们也可以使用 `requirements.yml` 文件中的更复杂格式，从而允许咱们提供 `src`、`scm`、`version` 及 `name` 等字段。


根据下文所述的其他因素，以这种方式安装的依赖项，在 playbook 执行期间会在该角色被执行 **之前** 执行。要更好地了解 play 执行过程中,依赖项的处理方式，请参阅 [角色](usage/playbook/using/roles.md)。


下面是个有着一些依赖角色的 `meta/main.yml` 文件示例：

```yaml
---
dependencies:
  - geerlingguy.java

galaxy_info:
  author: geerlingguy
  description: Elasticsearch for Linux.
  company: "Midwestern Mac, LLC"
  license: "license (BSD, MIT)"
  min_ansible_version: 2.4
  galaxy_tags:
    - web
    - system
    - monitoring
    - logging
    - lucene
    - elk
    - elasticsearch
```

其中的那些标签，是 *向下* 继承自依赖链的。为了将这些标签应用于某个角色及其所有依赖项，标签应被应用到该角色，而不是某个角色中的所有任务。


列为依赖项的角色，会受到条件与标签过滤的影响，而根据应用了哪些标签及条件，可能不会完全执行。


如果某个角色的来源是 Galaxy，就以 `namespace.role_name` 格式指定出该角色：


```yaml
dependencies:
  - geerlingguy.apache
  - geerlingguy.ansible
```

或者，也可以使用 `requirements.yml` 中的复合形式，指定出角色的依赖项，如下所示：


```yaml
dependencies:
  - name: geerlingguy.ansible
  - name: composer
    src: git+https://github.com/geerlingguy/ansible-role-composer.git
    version: 775396299f2da1f519f0d8885022ca2d6ee80ee8
```


> **注意**：Galaxy 希望所有角色依赖项都在 Galaxy 上，因此依赖项要以 `namespace.role_name` 格式指定。如果咱们导入了其某个依赖项中 `src` 值是个 URL 的角色，导入过程将失败。



### 列出已安装的角色


使用 `list` 子命令，显示出安装在 `roles_path` 中各个角色的名字和版本。


```console
$ ansible-galaxy role list
  - namespace-1.foo, v2.7.2
  - namespace2.bar, v2.6.2
```


### 移除某个已安装的角色

使用 `remove` 子命令删除 `roles_path` 中的某个角色。


```console
$ ansible-galaxy role remove namespace.role_name
```

（End）


