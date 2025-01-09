# `ansible-galaxy`

执行各种与角色和专辑相关的操作。


## 简介

```console
usage: ansible-galaxy [-h] [--version] [-v] TYPE ...
```

## 描述

用于管理 Ansible 角色和专辑的命令。

该 CLI 的工具全都被设计为不能同时运行。请使用外部调度器，并/或加锁，以确保不会出现操作冲突。


## 常用选项

{{#include ansible.md:46}}
{{#include ansible.md:60}}
{{#include ansible.md:68}}


## 操作

### `collection`

对 Ansible Galaxy 专辑执行操作。必须与下文列出的 `init`/`install` 等下一步操作结合使用。

+ `collection download`，以 tar 包形式下载专辑及其依赖项，以便离线安装；
    - `--clear-response-cache`，清除现有的服务器响应缓存；
    - `--no-cache`，不使用服务器响应缓存；
    - `--pre`，包括预发布版本。默认会忽略语义版本控制的预发布版本；
    - `--timeout <TIMEOUT>`，对 Galaxy 服务器进行操作的等待时间，默认为 60 秒；
    - `--token <API_KEY>, --api-key <API_KEY>`，Ansible Galaxy 的 API 密钥，可在 [https://galaxy.ansible.com/me/preferences](https://galaxy.ansible.com/me/preferences) 处找到；
    - `-c, --ignore-certs`，忽略 SSL 证书验证错误；
    - `-n, --no-deps`，不要下载列为依赖项的那些专辑；
    - `-p <DOWNLOAD_PATH>, --download-path <DOWNLOAD_PATH>`，要下载专辑的目录；
    - `-r, <REQUIREMENTS>, --requirements-file <REQUIREMENTS>`，包含要下载专辑列表的文件；
    - `-s <API_SERVER>, --server <API_SERVER>`，Galaxy API 服务器的 URL。

+ `collection init`，创建符合 Galaxy 元数据格式的角色或专辑的骨架框架。需要角色或专辑名称。专辑名称的格式必须是 `<namespace>.<collection>`；
    - `--collection-skeleton, <COLLECTION_SKELETON>`，新专辑应基于的专辑骨架路径；
    - `--init-path <INIT_PATH>`，创建骨架专辑的路径。默认为当前工作目录；
{{#include ansible-galaxy.md:36:38}}
    - `-f, --force`，强制覆盖现有角色或专辑;
{{#include ansible-galaxy.md:42}}

+ `collection build`，构建某个 Ansible Galaxy 专辑制品，a Ansible Galaxy collection artifact，该制品可存储在类似 Ansible Galaxy 的某个中心资源库中。默认情况下，该命令从当前工作目录构建。咱们可以选择传入该专辑的输入路径（`galaxy.yml` 文件的所在位置）。
    - `--output-path <OUTPUT_PATH>`，该专辑要构建到的路径。默认为当前工作目录；
{{#include ansible-galaxy.md:36:38}}
{{#include ansible-galaxy.md:48}}
{{#include ansible-galaxy.md:42}}

+ `collection publish`，将某个专辑发布到 Ansible Galaxy。需要提供所发布专辑 tar 压缩包的路径；
    - `--imoprt-timeout <IMPORT_TIMEOUT>`，等待专辑导入过程完成的时间；
    - `--no-wait`，无需等待导入验证的结果；
{{#include ansible-galaxy.md:36:38}}
{{#include ansible-galaxy.md:42}}

+ `collection install`，安装一或多个角色（`ansible-galaxy role install`），或一或多个专辑（`ansible-galaxy collection install`）。咱们可以传入一个列表（角色或专辑的），也可以使用下面列出的文件选项（二者是互斥的）。如果咱们传入了个列表，则他可以是个名称（将通过 galaxy API 和 github 下载），也可以是个本地的 tar 归档文件。
{{#include ansible-galaxy.md:33}}
    - `--disable-gpg-verify`，从某个 Galaxy 服务器安装专辑时，禁用 GPG 签名验证；
    - `--force-with-deps`，强制覆盖现有专辑及其依赖关系；
    - `--ignore-signature-status-code`，--消息抑制--。该参数可以指定多次；
    - `--ignore-signature-status-codes`，以空格分隔的状态代码列表，用于在签名验证过程中忽略这些代码（例如，`NO_PUBKEY FAILURE` 等）。有关这些选项的说明，请参见 [General status codes](https://github.com/gpg/gnupg/blob/master/doc/DETAILS#general-status-codes)。注意：请在位置参数后指定这些参数，或使用 `-` 分隔他们。该参数可指定多次。
    - `keyring`，签名验证时使用的密钥环；
{{#include ansible-galaxy.md:34}}
    - `--offline`，在不联系任何分发服务器下，安装专辑制品（tar 包）。此选项不适用于远程 Git 仓库中的专辑，或指向远端压缩包的 URL；
{{#include ansible-galaxy.md:35}}
    - `--required-valid-signature-count <REQUIRED_VALID_SIGNATURE_COUNT>`，必须成功验证该专辑的签名数。该值应为正整数，或表示必须使用所有签名来验证该专辑的 `-1`。如果未找到该专辑的有效签名，则以前导的 `+` 表示验证失败（例如 `+all`）；
    - `--signature`，额外签名源，用于在从 Galaxy 服务器上安装专辑前，验证 `MANIFEST.json` 的真实性。与随后的专辑名称一起使用（与 `-requirements-file` 相互排斥）。该参数可指定多次；
{{#include ansible-galaxy.md:36:37}}
    - `-U, --upgrade`，升级已安装的专辑制品。除非提供 `-no-deps`，否则也会更新依赖项；
{{#include ansible-galaxy.md:48}}
    - `-i, --ignore-errors`，忽略安装过程中的错误，并继续下一指定专辑。这不会忽略依赖冲突错误；
{{#include ansible-galaxy.md:39}}
    - `-p <COLLECTION_PATH>, --collection-path <COLLECTION_PATH>`，包含咱们专辑目录的路径；
{{#include ansible-galaxy.md:39}}
{{#include ansible-galaxy.md:41:42}}

+ `collection list`，列出已安装的专辑或角色；
    - `--format <OUTPUT_FORMAT>`，显示专辑列表的格式；
{{#include ansible-galaxy.md:36:38}}
    - `-p, --collections-path`，除默认的 `COLLECTIONS_PATHS` 目录外，还要搜索的一或多个目录。多个路径之间用 `:` 分隔。此参数可指定多次；
{{#include ansible-galaxy.md:42}}

+ `collection verify`，比较服务器上发现的专辑，与所安装副本的校验和。这不会验证依赖关系；
    - `--ignore-signature-status-code`，--消息抑制--。该参数可以指定多次；
    - `--ignore-signature-status-codes`，以空格分隔的状态代码列表，用于在签名验证过程中忽略这些代码（例如，`NO_PUBKEY FAILURE` 等）。有关这些选项的说明，请参见 [General status codes](https://github.com/gpg/gnupg/blob/master/doc/DETAILS#general-status-codes)。注意：请在位置参数后指定这些参数，或使用 `-` 分隔他们。该参数可指定多次。
    - `keyring`，签名验证时使用的密钥环；
    - `--offline`，在不联系服务器获取规范清单哈希值下，于本地验证专辑的完整性；
{{#include ansible-galaxy.md:73:74}}
{{#include ansible-galaxy.md:36:38}}
{{#include ansible-galaxy.md:78}}
{{#include ansible-galaxy.md:87}}
{{#include ansible-galaxy.md:41:42}}

### `role`

对某个 Ansible Galaxy 角色执行操作。必须与下文列出的 `delete`/`install`/`init` 等进一步操作相结合。


+ `role init`，创建符合 Galaxy 元数据格式的角色或专辑的骨架框架。需要一个角色或专辑名称。专辑名称的格式必须是 `<namespace>.<collection>`；
    - `--init-path <INIT_PATH>`，将在其中创建骨架角色的路径。默认为当前工作目录;
    - `--offline`，在创建角色时不查询 Galaxy API；
    - `--role-skeleton <ROLE_SKELETON>`，新角色所基于角色骨架的路径；
{{#include cli.md:533:534}}
    - `--type <ROLE_TYPE>`，使用某种替代角色类型初始化。有效类型包括 `container`、`apb` 及 `network`；
{{#include ansible-galaxy.md:38}}
{{#include ansible.md:58}}
{{#include ansible-galaxy.md:48}}
{{#include ansible-galaxy.md:42}}

+ `role remove`，移除作为参数传递的本地系统上的角色列表；
    - `--timeout <TIMEOUT>`，对 Galaxy 服务器进行操作的等待时间，默认为 60 秒；
{{#include ansible-galaxy.md:37:38}}
    - `-p, --roles-path`，包含角色的目录路径。默认路径是通过 `DEFAULT_ROLES_PATH` 配置的第一个可写路径： `{{ ANSIBLE_HOME ~ "/roles:/usr/share/ansible/roles:/etc/ansible/roles" }}` 。该参数可指定多次；
{{#include ansible-galaxy.md:42}}


+ `role delete`，删除来自 Ansible Galaxy 的某个角色；
    - `--timeout <TIMEOUT>`，对 Galaxy 服务器进行操作的等待时间，默认为 60 秒；
{{#include ansible-galaxy.md:37:38}}
{{#include ansible-galaxy.md:42}}


+ `role list`，列出已安装的专辑或角色；
    - `--timeout <TIMEOUT>`，对 Galaxy 服务器进行操作的等待时间，默认为 60 秒；
{{#include ansible-galaxy.md:37:38}}
{{#include ansible-galaxy.md:120}}
{{#include ansible-galaxy.md:42}}

+ `role search`，检索 Ansible Galaxy 服务器上的角色；
    - `--author <AUTHOR>`，GitHub 用户名；
    - `--galaxy-tags <GALAXY_TAGS>`，要过滤的 galaxy 标签列表；
    - `--platforms <PLATFORMS>`，要过滤的 OS 平台列表；
{{#include ansible-galaxy.md:36:38}}
{{#include ansible-galaxy.md:42}}


+ `role import`，用于将某个角色，导入 Ansible Galaxy；
    - `--branch <REFERENCE>`，要导入的分支名称。默认为版本库的默认分支（通常是 `master`/`main`）；
    - `--no-wait`，无需等待导入结果；
    - `--role-name <ROLE_NAME>`，在不同于源码库名字时，该角色应有的名字；
    - `--status`，检查给定 `github_user/github_repo` 的最新导入请求状态；
{{#include ansible-galaxy.md:36:38}}
{{#include ansible-galaxy.md:42}}


+ `role setup`，为 Ansible Galaxy 角色设置自 GitHub 或 Travis 的集成；
    - `--list`，列出咱们的所有集成；
    - `--remove <REMOVE_ID>`，删除与所提供 ID 值相匹配的集成。请使用 `--list` 查看 ID 值；
{{#include ansible-galaxy.md:36:38}}
{{#include ansible-galaxy.md:120}}
{{#include ansible-galaxy.md:42}}


+ `role info`，打印出某个已安装角色的详细信息，以及 galaxy API 提供的信息；
    - `--offline`，在创建角色时不查询 Galaxy API；
{{#include ansible-galaxy.md:36:38}}
{{#include ansible-galaxy.md:120}}
{{#include ansible-galaxy.md:42}}


+ `role install`，安装一或多个角色（`ansible-galaxy role install`），或一或多个专辑（`ansible-galaxy collection install`）。咱们可传入一个列表（角色或专辑的），也可以使用下面所列出的文件选项（二者互斥）。如果咱们传入了个列表，则其可以是一个名称（将通过 galaxy API 和 github 下载），也可以是一个本地 tar 压缩文件。
    - `--force-with-deps`，强制覆盖现有角色及其依赖关系；
{{#include ansible-galaxy.md:36:38}}
{{#include ansible-galaxy.md:48}}
    - `-g, --keep-scm-meta`，打包角色时，使用 tar 而不是 SCM 的归档选项；
    - `-i, --ignore-errors`，忽略安装过程中的错误，并继续下一指定角色；
    - `-n, --no-deps`，不要下载列为依赖项的那些角色；
{{#include ansible-galaxy.md:120}}
    - `-r <REQUIREMENTS>, --role-file <REQUIREMENTS>`，包含待安装角色列表的文件；
{{#include ansible-galaxy.md:42}}



{{#include ansible.md:70:72}}

{{#include ansible.md:76:78}}



## 文件

{{#include ansible.md:84:}}


（End）


