# 安装专辑

> **注意**：若咱们按照本篇中所述，手动安装了某个专辑，则在咱们升级 `ansible` 软件包或 `ansible-core` 时，该专辑不会自动被升级。


## 在容器中安装专辑

咱们可在称为 “执行环境” 的容器中，安装专辑及其依赖项。有关详情，请参阅 [开始使用执行环境](../../ee.md)。


## 使用 `ansible-galaxy` 安装专辑


默认情况下，`ansible-galaxy collection install` 会使用 https://galaxy.ansible.com 作为 Galaxy 服务器（在 `ansible.cfg` 文件中列出于 [`GALAXY_SERVER`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy-server) 下）。咱们无需进一步配置。默认情况下，Ansible 会将专辑安装在 `~/.ansible/collections` 中的 `ansible_collections` 目录下。


若咱们使用了其他 Galaxy 服务器，比如 Red Hat Automation Hub，请参阅 [配置 `ansible-galaxy` 客户端](#配置-ansible-galaxy-客户端)。

要安装托管 Galaxy 上的某个专辑：


```console
ansible-galaxy collection install my_namespace.my_collection
```

要将某个专辑升级到 Galaxy 服务器上的最新可用版本，咱们可使用 `--upgrade` 选项：


```console
ansible-galaxy collection install my_namespace.my_collection --upgrade
```


咱们还可直接使用来自咱们构建的 tarball 压缩包：

```console
ansible-galaxy collection install my_namespace-my_collection-1.0.0.tar.gz -p ./collections
```

> **译注**：其中 `-p, --role-path` 指定路径，参见 `ansible-galaxy install --help` 帮助文档。


咱们可从某个本地源代码目录，构建并安装专辑。`ansible-galaxy` 实用工具，会使用该目录中的 `MANIFEST.json` 或 `galaxy.yml` 元数据，构建该专辑。

```console
ansible-galaxy collection install /path/to/collection -p ./collections
```

咱们也可以在一个命名空间的目录中，安装多个专辑。


```console
ns/
├── collection1/
│   ├── MANIFEST.json
│   └── plugins/
└── collection2/
    ├── galaxy.yml
    └── plugins/
```


```console
ansible-galaxy collection install /path/to/ns -p ./collections
```

> **注意**：`install` 命令会自动将 `ansible_collections` 这个路径，添加到使用 `-p` 选项指定的路径中，除非该父目录已位于名为 `ansible_collections` 的文件夹中。

在使用 `-p` 选项指定安装路径时，要使用 `COLLECTIONS_PATHS` 中配置的值之一，因为这是 Ansible 本身期望发现专辑之处。若咱们没有指定某个路径，`ansible-galaxy collection install` 命令会将该专辑安装到 `COLLECTIONS_PATHS` 中，定义的首个路径，这默认为 `~/.ansible/collections`。


## 安装有签名验证的专辑

若某个专辑已由某个分发服务器签名，那么该服务器将提供 ASCII 批覆、分离式的签名，ASCII armored, detached signatures，以验证 `MANIFEST.json` 的真实性，然后再用其验证该专辑的内容。该选项并非在所有分发服务器都可用。请参阅 [分发专辑](https://docs.ansible.com/ansible/latest/dev_guide/developing_collections_distributing.html#distributing-collections)，查看列出支持专辑签名服务器的一张表格。


要对签名过的专辑，使用签名验证：

1. 为 `ansible-galaxy` [配置一个 GnuPG 密钥环](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy-gpg-keyring)，或在咱们安装该签名的专辑时，使用 `--keyring` 选项提供到该密钥环的路径；
2. 将来自分发服务器的公钥，密钥环；

```console
gpg --import --no-default-keyring --keyring ~/.ansible/pubring.kbx my-public-key.asc
```

3. 安装该专辑时验证签名；

```console
ansible-galaxy collection install my_namespace.my_collection --keyring ~/.ansible/pubring.kbx
```

若咱们已经 [配置了 GnuPG 密钥环](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy-gpg-keyring)，则无需使用 `--keyring` 选项。


4. 可选择在安装后的任何时刻验证签名，以证明该专辑未被篡改。有关详细信息，请参阅 [验证签名的专辑](verifying.md)。

除了由分发服务器提供的签名外，咱们还可包含其他签名。使用 `--signature` 选项以这些附加签名，验证专辑的 `MANIFEST.json`。这些补充签名应以 URI 的形式提供。


```console
ansible-galaxy collection install my_namespace.my_collection --signature https://examplehost.com/detached_signature.asc --keyring ~/.ansible/pubring.kbx
```

GnuPG 的验证仅适用于从分发服务器上安装的专辑。用户提供的签名不会用于验证从 Git 仓库、源代码目录，或者到 `tar.gz` 文件的 URL/路径所安装的专辑。


咱们还可以在专辑的 `requirements.yml` 文件中 `signatures` 键下，添加额外签名。


```yaml
# requirements.yml
collections:
  - name: ns.coll
    version: 1.0.0
    signatures:
      - https://examplehost.com/detached_signature.asc
      - file:///path/to/local/detached_signature.asc
```


有关如何安装带有此文件的专辑详细信息，请参见 [专辑需求文件](#使用需求文件安装多个专辑)。

默认情况下，只要有 1 个签名成功验证了该专辑，验证就视为成功。可以 `--required-valid-signature-count` 或 [`GALAXY_REQUIRED_VALID_SIGNATURE_COUNT`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy-required-valid-signature-count)，配置所需的签名数量。通过将该选项设置为 `all`，便可使所有签名为必需验证。而要在找不到有效签名的情况下，令到签名验证失败，可在值前加上 `+`，比如 `+all` 或 `+1`。

```console
export ANSIBLE_GALAXY_GPG_KEYRING=~/.ansible/pubring.kbx
export ANSIBLE_GALAXY_REQUIRED_VALID_SIGNATURE_COUNT=2
ansible-galaxy collection install my_namespace.my_collection --signature https://examplehost.com/detached_signature.asc --signature file:///path/to/local/detached_signature.asc
```

可使用 `--ignore-signature-status-code` 命令行开关，或 [`GALAXY_REQUIRED_VALID_SIGNATURE_COUNT`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy-required-valid-signature-count) 环境变量忽略某些 GnuPG 错误。`GALAXY_REQUIRED_VALID_SIGNATURE_COUNT` 环境变量应是个列表，而 `--ignore-signature-status-code` 命令行选项则可提供多次，以忽略多个额外错误状态代码。


下面这个示例就需要由分发服务器提供的任何签名，以验证专辑，除非这些签名因 `NO_PUBKEY` 而失败：


```console
export ANSIBLE_GALAXY_GPG_KEYRING=~/.ansible/pubring.kbx
export ANSIBLE_GALAXY_REQUIRED_VALID_SIGNATURE_COUNT=all
ansible-galaxy collection install my_namespace.my_collection --ignore-signature-status-code NO_PUBKEY
```

如果上面示例中的验证失败，就只会显示那些 `NO_PUBKEY` 以外的错误。


在验证为不成功时，专辑就不会被安装。可使用 `--disable-gpg-verify` 命令行开关，或通过配置 [`GALAXY_DISABLE_GPG_VERIFY`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy-disable-gpg-verify) 环境变量，禁用 GnuPG 签名验证。


## 安装某个专辑的较早版本

咱们一次只能安装某个专辑的一个版本。默认情况下，`ansible-galaxy` 会安装最新可用版本。若咱们想要安装某个特定版本，可添加一个版本范围标识符。例如，要安装该专辑的 `1.0.0-beta.1` 版本：


```console
ansible-galaxy collection install my_namespace.my_collection:==1.0.0-beta.1
```

咱们可指定出多个以 `,` 分隔的范围标识符。要使用单引号，这样 shell 就会传递整个命令，包括 `>`、`!` 及其他操作符等。例如，要安装大于等于 `1.0.0` 且小于 `2.0.0` 的最新版本：

```console
ansible-galaxy collection install 'my_namespace.my_collection:>=1.0.0,<2.0.0'
```

Ansible 总是会安装满足咱们指定范围标识符的最新版本。咱们可使用以下这些范围标识符：


- `*`：最新版本。这是默认范围标识符；
- `!=`：不等于指定的版本；
- `==`：正好是指定的版本；
- `>=`：大于等于指定的版本；
- `>`：大于指定的版本；
- `<=`：小于等于指定的版本；
- `<`：小于指定的版本。

> **注意**：默认情况下，`ansible-galaxy` 会忽略那些预发布版本。要安装某个预发布版本，咱们必须使用 `==` 范围标识符，显式要求该版本。


## 使用需求文件安装多个专辑

咱们可设置个 `requirements.yml` 文件，在一条命令中安装多个专辑。该文件是个 YAML 的文件，按以下格式：


```yaml
---
collections:
# With just the collection name
- my_namespace.my_collection

# With the collection name, version, and source options
- name: my_namespace.my_other_collection
  version: ">=1.2.0" # Version range identifiers (default: ``*``)
  source: ... # The Galaxy URL to pull the collection from (default: ``--api-server`` from cmdline)
```

对于各个专辑条目，咱们可指定出以下键值：

- `name`
- `version`
- `signatures`
- `source`
- `type`

`version` 键值使用与 [安装某个专辑的较早版本](#安装某个专辑的较早版本) 中，所记录的同样范围标识符。

`signatures` 键值接受一个签名源的列表，这些签名源用于在专辑安装与执行 `ansible-galaxy collection verify` 时，对在 Galaxy 服务器上找到的签名源加以补充。签名源应是包含分离签名的一些 URI。若指定了签名，就必须提供 `--keyring` 这个CLI 选项。


签名仅用于验证 Galaxy 服务器上的专辑。用户提供的签名不会被用于验证安装自 git 仓库、源代码目录，或到 `tar.gz` 文件的 URL/路径的专辑。


```yaml
collections:
  - name: namespace.name
    version: 1.0.0
    type: galaxy
    signatures:
      - https://examplehost.com/detached_signature.asc
      - file:///path/to/local/detached_signature.asc
```


`type` 键值可以被设置为 `file`、`galaxy`、`git`、`url`、`dir` 或 `subdirs`。若 `type` 被省略，则会使用 `name` 键值隐式确定出该专辑的来源。


当咱们以 `type: git` 安装某个专辑时，`version` 键值可指向某个分支，或某个 [git 提交样式](https://git-scm.com/docs/gitglossary#def_commit-ish) 的对象（提交或标签）。例如：


```yaml
collections:
  - name: https://github.com/organization/repo_name.git
    type: git
    version: devel
```


咱们也可将一些角色，添加到 `requirements.yml` 文件，于 `roles` 关键字下。这些值与旧版 Ansible 中的需求文件格式相同。


```yaml
---
roles:
  # Install a role from Ansible Galaxy.
  - name: geerlingguy.java
    version: "1.9.6" # note that ranges are not supported for roles


collections:
  # Install a collection from Ansible Galaxy.
  - name: geerlingguy.php_roles
    version: ">=0.9.3"
    source: https://galaxy.ansible.com
```


要使用一条命令同时安装这些角色与专辑，请运行以下命令：


```console
ansible-galaxy install -r requirements.yml
```


运行 `ansible-galaxy collection install -r` 或 `ansible-galaxy role install -r` 命令，都将只分别安装专辑或角色。

> **注意**：在指定了自定义的专辑或角色安装路径时，那么从同一需求文件，同时安装角色和专辑将不生效。在这种情况下，专辑将被跳过，而该命令将像 `ansible-galaxy role install` 那样，处理各个角色。


## 下载某个专辑供离线使用

要从 Galaxy 下载专辑的压缩包，以供离线使用：


1. （在 web 浏览器中）导航至该专辑页面；
2. 点击 “Download tarball”。

咱们可能还需要手动下载全部依赖的专辑。

> **译注**：~~这说明 Ansible 还缺少像是 [`pip` 中那样的](https://tips.xfoss.com/49_Python_tips.html#%E5%9C%A8%E5%86%85%E7%BD%91%E5%AE%89%E8%A3%85-python-%E7%AC%AC%E4%B8%89%E6%96%B9%E5%8C%85)，下载专辑及其依赖的工具~~。
>
> 后面的 [下载专辑](downloading.md) 小节，将专门讲到使用 `ansible-galaxy collection download` 命令，下载专辑及其依赖项。


## 将专辑安装在 playbook 旁边


咱们可将专辑安装在咱们项目内咱们的 playbook 旁边，而非安装在咱们系统上的某个全局位置，或 [AWX](https://github.com/ansible/awx) 上。


使用本地安装在 playbook 旁边的专辑，有一些好处，比如：

- 确保该项目的所有用户，都使用同一专辑版本；
- 使用独立项目，self-contained projects，可以方便地在不同环境间迁移。提升的可迁移性，还降低了建立新环境时的开销。在云环境中部署 Ansible playbook 时，这非常有利；
- 在本地管理专辑，可让咱们将其与 playbook 一起纳入版本管理；
- 本地安装专辑，可将他们与有着多个项目的环境中，那些全局安装隔离开来。


下面是把某个专辑放在当前 playbook 旁边，于 `collections/ansible_collections/` 目录结构下的一个示例。


```console
./
├── play.yml
├── collections/
│   └── ansible_collections/
│               └── my_namespace/
│                   └── my_collection/<collection structure lives here>
```

有关专辑目录结构的详细信息，请参阅 [专辑结构](https://docs.ansible.com/ansible/latest/dev_guide/developing_collections_structure.html#collection-structure)。


## 从源代码文件安装某个专辑

Ansible 也可以多种方式，从某个源代码目录安装专辑：


```yaml
collections:
  # directory containing the collection
  - name: ./my_namespace/my_collection/
    type: dir

  # directory containing a namespace, with collections as subdirectories
  - name: ./my_namespace/
    type: subdirs
```


通过直接指定输出文件，Ansible 也可安装使用 `ansible-galaxy collection build` 命令收集的某个专辑，或从 Galaxy 下载以供离线使用的某个专辑：


```yaml
collections:
  - name: /tmp/my_namespace-my_collection-1.0.0.tar.gz
    type: file
```


> **注意**：相对路径是从当前工作目录（咱们调用 `ansible-galaxy install -r` 之处）开始计算的。他们不会相对于 `requirements.yml` 文件进行计算。

## 从 Git 代码仓库安装某个专辑


咱们可从某个 git 代码仓库，而非 Galaxy 或 Automation Hub 安装某个专辑。作为开发者，从某个 git 代码仓库安装，可让咱们在创建压缩包和发布咱们的专辑前，对其加以复查。而作为一名用户，从某个 git 代码仓库安装，可以让咱们用上 Galaxy 或 Automation Hub 上还没有的一些专辑或版本。该功能只是为内容开发者提供了一个前述内容的最基本捷径，git 代码仓库可能不支持 `ansible-galaxy` CLI 的全部功能。在复杂情形下，一种更灵活选择，可能是 `git clone` 该仓库到该专辑安装目录的正确文件结构中。


该代码仓库必须包含一个 `galaxy.yml` 或 `MANIFEST.json` 文件。此文件提供了诸如版本号及该专辑的命名空间等元数据。


### 在命令行下从某个 git 仓库安装专辑

要在命令行下从某个 git 代码仓库安装专辑，就要使用该代码仓库的 URI，而非专辑名字或到某个 `tar.gz` 文件的路径。除非咱们使用了以 `git` 用户的 SSH 认证（例如 `git@github.com:ansible-collections/ansible.windows.git`），就要使用前缀 `git+`。咱们可使用逗号分隔的 [git commit-ish 语法](https://git-scm.com/docs/gitglossary#def_commit-ish)，指定出分支、提交或标签。


比如：


```console
# Install a collection in a repository using the latest commit on the branch 'devel'
ansible-galaxy collection install git+https://github.com/organization/repo_name.git,devel

# Install a collection from a private GitHub repository
ansible-galaxy collection install git@github.com:organization/repo_name.git

# Install a collection from a local git repository
ansible-galaxy collection install git+file:///home/user/path/to/repo_name.git
```


> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> 将凭据嵌入 git URI 并不安全。要使用安全的认证选项，防止咱们凭据在日志中或其他地方暴露。
>
> - 使用 [SSH](https://help.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh) 认证；
>
> - 使用 [`netrc`](https://linux.die.net/man/5/netrc) 认证；
>
> - 在咱们的 git 配置中使用 [`http.extraHeader`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpextraHeader)；
>
> - 在咱们的 git 配置中使用 [`url.<base>.pushInsteadOf`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-urlltbasegtpushInsteadOf)。


### 指定出 git 代码仓库中专辑的位置


当咱们从某个 git 代码仓库安装专辑时，Ansible 会使用该专辑的 `galaxy.yml` 或 `MANIFEST.json` 元数据文件构建该专辑。默认情况下，Ansible 会在两个路径下，检索专辑的 `galaxy.yml` 或 `MANIFEST.json` 元数据文件：

- 该代码仓库的顶层；
- 该代码仓库路径中的各个目录（深入一级）。


如果该代码仓库的顶层中，存在 `galaxy.yml` 或 `MANIFEST.json` 文件，Ansible 就会使用该文件中的专辑元数据，安装某单个专辑。


```console
├── galaxy.yml
├── plugins/
│   ├── lookup/
│   ├── modules/
│   └── module_utils/
└─── README.md
```


如果该代码仓库路径中的一或多个目录（深入一级）中，存在 `galaxy.yml` 或 `MANIFEST.json` 文件，Ansible 则会将每个带元数据的目录，作为一个专辑安装。例如，Ansible 默认会安装以下代码仓库结构中的 `collection1` 和 `collection2`：


```console
├── collection1
│   ├── docs/
│   ├── galaxy.yml
│   └── plugins/
│       ├── inventory/
│       └── modules/
└── collection2
    ├── docs/
    ├── galaxy.yml
    ├── plugins/
    |   ├── filter/
    |   └── modules/
    └── roles/
```


若咱们有别的代码仓库结构，或者只打算安装一些专辑的子集，咱们可在咱们 URI 末尾（于可选的逗号分隔的版本前），添加一个片段，以指明元数据文件的位置。该路径应是个目录，而非元数据文件本身。例如，要只安装有着两个专辑的示例代码仓库中的 `collection2`：


```console
ansible-galaxy collection install git+https://github.com/organization/repo_name.git#/collection2/
```

在某些代码仓库中，主目录会与命名空间相对应：


```console
namespace/
├── collectionA/
|   ├── docs/
|   ├── galaxy.yml
|   ├── plugins/
|   │   ├── README.md
|   │   └── modules/
|   ├── README.md
|   └── roles/
└── collectionB/
    ├── docs/
    ├── galaxy.yml
    ├── plugins/
    │   ├── connection/
    │   └── modules/
    ├── README.md
    └── roles/
```

咱们可安装该代码仓库中的全部专辑，也可安装某个特定提交中的一个专辑：


```console
# Install all collections in the namespace
ansible-galaxy collection install git+https://github.com/organization/repo_name.git#/namespace/

# Install an individual collection using a specific commit
ansible-galaxy collection install git+https://github.com/organization/repo_name.git#/namespace/collectionA/,7b60ddc245bc416b72d8ea6ed7b799885110f5e5
```

## 配置 `ansible-galaxy` 客户端

默认情况下，`ansible-galaxy` 会使用 https://galaxy.ansible.com 作为 Galaxy 服务器（正如 `ansible.cfg` 文件中 [`GALAXY_SERVER`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy-server) 下所列出的）。

咱们可使用以下任一选项，配置 `ansible-galaxy collection` 命令使用其他服务器（如某个定制 Galaxy 服务器）：


- 设置 [配置文件](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings-locations) 中 [`GALAXY_SERVER_LIST`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy-server-list) 配置选项下的服务器列表；
- 使用 `--server` 命令行参数，限制到某单个服务器。


要在 `ansible.cfg` 中配置一个 Galaxy 服务器列表：


1. 将到一或多个服务器名字的 `server_list` 选项，添加到 `[galaxy]` 小节下；
2. 为每个服务器名字，创建一个新的小节；
3. 设置各个服务器名字的 `url` 选项；
4. 作为可选项，设置每个服务器名字的 API 令牌。访问 https://galaxy.ansible.com/me/preferences 并单击 `"Show API key"`。

> **注意**：各个服务器名字的 `url` 选项都必需以前向斜杠 `/` 结束。若咱们没有在咱们 Galaxy 服务器列表中设置 API 令牌，就要使用 `--api-key` 命令行参数，将令牌传递给 `ansible-galaxy collection publish` 命令。


以下示例展示了如何配置多个服务器：

```ini
[galaxy]
server_list = my_org_hub, release_galaxy, test_galaxy, my_galaxy_ng

[galaxy_server.my_org_hub]
url=https://automation.my_org/
username=my_user
password=my_pass

[galaxy_server.release_galaxy]
url=https://galaxy.ansible.com/
token=my_token

[galaxy_server.test_galaxy]
url=https://galaxy-dev.ansible.com/
token=my_test_token

[galaxy_server.my_galaxy_ng]
url=http://my_galaxy_ng:8000/api/automation-hub/
auth_url=http://my_keycloak:8080/auth/realms/myco/protocol/openid-connect/token
client_id=galaxy-ng
token=my_keycloak_access_token
```


> **注意**：
>
> 咱们可使用 `--server` 命令行参数，选取 `server_list` 中的某个明确的 Galaxy 服务器，而此参数的值，应与该服务器的名字匹配。要使用某个不在该服务器列表中的服务器，就要将该值设置为访问该服务器的 URL（此时服务器列表中的所有服务器都将被忽略）。此外，咱们不能对任何这些预定义服务器，使用 `--api-key` 命令行参数。只有在咱们未曾定义出服务器列表，或在 `--server` 参数中指定了 URL 的情况下，才能使用 `api_key` 这个参数。


### Galaxy 服务器列表的配置选项

[`GALAXY_SERVER_LIST`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy-server-list) 选项，是个以优先顺序排列的服务器标识符列表。在检索某个专辑时，安装进程会按照该顺序进行搜索，例如，先检索 `automation_hub`，然后是 `my_org_hub`、`release_galaxy`，最后是 `test_galaxy`，到找到该专辑为止。随后具体的 Galaxy 实例会被定义在 `[galaxy_server.{{ id }}]` 小节下，其中 `{{ id }}` 为定义在列表中的服务器标识符。此小节随后可以定义以下键值：

- `url`：要连接 Galaxy 实例的 URL。必需项；
- `token`：用于对该 Galaxy 实例进行身份验证的 API 令牌密钥。与 `username` 互斥；
- `username`：用于对该 Galaxy 实例进行基本身份验证的用户名。与 `token` 互斥；
- `password`：与 `username` 一起，用于基本身份验证的密码；
- `auth_url`：在使用 SSO 身份验证（比如 galaxyNG）时，某 [Keycloak 服务器](https://www.keycloak.org/) `'token_endpoint'` 的 URL。与 `username` 互斥。需要 `token` 键值；
- `validate_certs`：是否要验证 Galaxy 服务器的 TLS 证书。除非提供了 `--ignore-certs` 命令行选项，或将 `GALAXY_IGNORE_CERTS` 被配置为 `True`，否则该键值默认为 `True`；
- `client_id`：用于身份验证的 Keycloak 令牌的 `client_id`。需要 `auth_url` 和 `token` 两个键值。默认 `client_id` 为在 Red Hat SSO 下生效的云服务；
- `timeout`：等待该 Galaxy 服务器响应的最长秒数。


除了在 `ansible.cfg` 文件中定义这些服务器选项，咱们还可以将他们定义为环境变量。环境变量的形式为 `ANSIBLE_GALAXY_SERVER_{{ id }}_{{ key }}`，其中 `{{ id }}` 是服务器标识符的大写形式，`{{ key }}` 是要定义的键。例如，咱们可以通过设置 `ANSIBLE_GALAXY_SERVER_RELEASE_GALAXY_TOKEN=secret_token`，为 `release_galaxy` 服务器定义令牌。


对于那些只会用到一个 Galaxy 服务器的操作（比如，`publish`、`info` 或 `install` 命令），`ansible-galaxy collection` 命令使用 `server_list` 中的第一个条目，除非咱们使用 `--server` 参数，传递了一个显式服务器。

> **注意**：`ansible-galaxy` 可以在其他配置的 Galaxy 实例上，寻找依赖项，以支持某个专辑依赖于另一 Galaxy 实例中专辑的用例。


## 移除某个专辑


若咱们不再需要某个专辑，只需从文件系统中移除安装目录即可。根据咱们操作系统不同，其路径也可能不同：


```console
rm -rf ~/.ansible/collections/ansible_collections/community/general
rm -rf ./venv/lib/python3.9/site-packages/ansible_collections/community/general
```

（End）


