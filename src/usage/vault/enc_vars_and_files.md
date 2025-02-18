# 使用加密变量及文件

当咱们运行某个用到加密变量或文件的任务或 playbook 时，咱们必须提供用于解密这些变量或文件的密码。咱们可以在命令行，或通过在某个配置选项，或某个环境变量中，设置一个默认密码来源完成这点。


## 传递单个密码



若咱们任务或 playbook 中的全部加密变量和文件，都需要使用某单个密码，那么咱们可以使用 `--ask-vault-pass` 或 `--vault-password-file` 的命令行选项。


要提示输入密码：


```console
ansible-playbook --ask-vault-pass site.yml
```

要从 `/path/to/my/vault-password-file` 文件获取密码：


```console
ansible-playbook --vault-password-file /path/to/my/vault-password-file site.yml
```

要从 vault 密码客户端脚本 `my-vault-password-client.py` 得到密码：


```console
ansible-playbook --vault-password-file my-vault-password-client.py
```


## 传递 vault ID



咱们还可以使用 `--vault-id` 命令行选项，传递单个密码及其 vault 标签。当在某单个仓库中，用到了多个 vault 时，这种方法更为清晰。


要提示输入 `'dev'` vault ID 的密码：

```console
ansible-playbook --vault-id dev@prompt site.yml
```

要从 `dev-password` 文件获取 `'dev'` vault ID 的密码：

```console
ansible-playbook --vault-id dev@dev-password site.yml
```

要从 vault 密码客户端脚本 `my-vault-password-client.py` 得到 `'dev'` vault ID 的密码：

```console
ansible-playbook --vault-id dev@my-vault-password-client.py site.yml
```


## 传递多个 vault 密码

若咱们的任务或 playbook，需要多个咱们以不同 vault ID 加密的加密变量或文件，此时咱们就必须使用 `--vault-id` 选项，传递多个 `--vault-id` 命令行选项，来指定出这些 vault ID（`'dev'`、`'prod'`、`'cloud'`、`'db'` 等）及密码来源（提示符、文件、脚本等）。例如，要使用一个从文件读取的 `'dev'` 密码，以及一个提示输入的 `'prod'` 密码：


```console
ansible-playbook --vault-id dev@dev-password --vault-id prod@prompt site.yml
```

默认情况下，vault ID 标签（`'dev'`、`'prod'` 等）仅是些提示。Ansible 会尝试以各个密码，解密 vault 内容。带有与加密数据相同标签的密码会被首先尝试，然后将按照在命令行上提供的顺序，尝试各个 vault 密码。


若加密的数据没有标签，或标签与提供的标签都不匹配，则将按这些密码被指定出的顺序，尝试他们。在上面的示例中，`'dev'` 这个密码将被首先尝试，然后是 `'prod'` 密码，以应对在 Ansible 不知道哪个 vault ID 曾被用作加密的情形。

## 在没有 vault ID 下使用 `--vault-id` 命令行开关


也可以在不指定 vault ID 下，使用 `--vault-id` 命令行选项。这种行为等同于 `--ask-vault-pass` 或 `--vault-password-file`，因此很少使用。


比如，要使用某个密码文件 `dev-password`：


```console
ansible-playbook --vault-id dev-password site.yml
```

要提示输入密码：


```console
ansible-playbook --vault-id @prompt site.yml
```


要从某个可执行脚本 `my-vault-password-client.py` 得到密码：

```console
ansible-playbook --vault-id my-vault-password-client.py
```


# 配置使用加密内容的默认值

## 设置一个默认 vault ID

若咱们使用某个 vault ID 的频率远高于任何其他 vault ID，那么咱们可设置 `DEFAULT_VAULT_IDENTITY_LIST` 这个配置选项，指定为某个默认的 vault ID 与密码来源。若咱们没有指定 `--vault-id`，Ansible 将全部使用默认的 vault ID 与密码来源。咱们可以给该选项设置多个值。设置多个值就相当于传递多个 `--vault-id` 的命令行选项。


> **译注**：这是在 `~/.ansible.cfg` 文件中，添加类似下面这样的一行设置的。注意由于 `~/.ansible.cfg` 是个 INI 文件，故该变量的清单写法无需 `[]`。


```ini
[defaults]
vault_identity_list = 'dev@~/.ansible/dev.secret', 'prod@~/.ansible/prod.secret'
```

## 设置默认密码来源


若咱们不愿在命令行上提供密码文件，或者咱们使用某个 vault 密码文件的频率远高于其他文件，那么咱们可设置 [`DEFAULT_VAULT_PASSWORD_FILE`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-vault-password-file) 这个配置选项，或 [`ANSIBLE_VAULT_PASSWORD_FILE`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#envvar-ANSIBLE_VAULT_PASSWORD_FILE) 这个环境变量，指定出要使用的某个默认文件。例如，若咱们设置了 `ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt`，Ansible 就会自动检索该文件中的密码。这在比如咱们从诸如 Jenkins 等持续集成系统中，使用 Ansible 时，就非常有用。

咱们引用的文件，既可以是个包含着密码的文件（纯文本的），也可以是某个会返回密码的脚本（设置了可执行权限）。


# 加密文件于何时成为可见？


一般来说，咱们用 Ansible Vault 加密的内容，会在执行后保持加密。但有一个例外。若咱们将加密文件作为 `src` 参数，传递给 [`copy`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html#copy-module)、[`template`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html#template-module)、[`unarchive`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/unarchive_module.html#unarchive-module)、[`script`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/script_module.html#script-module)或 [`assemble`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/assemble_module.html#assemble-module) 等模组，那么该文件将在目标主机上不会被加密（假设咱们在运行 play 时，提供了正确的 vault 密码）。这种行为是有意的，也是有用的。咱们可以加密某个配置文件或模板，以避免共享咱们的配置细节，但当咱们将该配置复制到咱们环境中的服务器时，就会希望其被解密，以便本地用户和进程可以访问他。

# 使用 Ansible Vault 加密的文件格式

Ansible Vault 会创建出 UTF-8 编码的 txt 文件。这种文件格式包括以一个换行结束的头部。例如：


```text
$ANSIBLE_VAULT;1.1;AES256
```

或者：

```text
$ANSIBLE_VAULT;1.2;AES256;vault-id-label
```

该头部可包含以分号 (`;`) 分隔的最多四个元素。


- 该格式的 ID（`$ANSIBLE_VAULT`）。目前，`$ANSIBLE_VAULT` 是唯一有效的格式 ID。格式 ID 标识出使用 Ansible Vault（以 `vault.is_encrypted_file()`） 加密的内容；
- Vault 格式的版本（ `1.X` ）。在提供了某个带标签的 vault ID 时，当前所有支持 Ansible 版本，都将默认为 `'1.1'` 或 `'1.2'`。`'1.0'` 的格式仅支持读取（写入时将自动转换为 `'1.1'` 格式）。格式的版本目前只用作精确的字符串比较（版本号目前不会进行 “比较”）；
- 用于加密数据的密码算法（`AES256`）。目前 `AES256` 是唯一支持的加密算法。Vault 的格式 `1.0` 使用的是 `'AES'`，但当前代码会始终使用 `'AES256'`；
- 用于加密数据的 vault ID 标签（可选项，`vault-id-label`） 例如，若咱们以 `--vault-id dev@prompt` 加密某个文件，则 `vault-id-label` 即为 `'dev'`。

注意：今后，该头部可能会变化。格式 ID 和格式版本后的字段，会取决于格式版本。将来的保险库格式版本，可能会增加更多密码算法选项和/或附加字段。

加密文件的其余部分，就是 `'vaulttext'` 了。所谓 `'vaulttext'`，是加密密文的文本加固版本。每行 80 个字符宽，但最后一行可能会较短。


### 格式版本 `1.1` 与 `1.2` 下的 Ansible Vault 荷载格式


`'vaulttext'` 是加密密文，与一个 SHA256 摘要的字符串连接结果的 “十六进制化”。

所谓 “十六进制化”，指的是 Python 标准库的 `binascii` 模组中的 `hexlify()` 方法。


包含以下内容的 `hexlify()` 后的结果：

- 盐值，the salt，经 `hexlify()` 后的字符串，后跟一个新行（`0x0a`）；
+ 加密后的 HMAC 经 `hexlify()` 后的字符串，后跟一个新行。所谓 HMAC 为：
    + 某个 [RFC2104](https://www.ietf.org/rfc/rfc2104.txt) 样式的 HMAC
        + 有以下输入：
            - AES256 加密的密文
            + 一个 PBKDF2 的密钥。该密钥、密码密钥，the cipher key，和密码 IV，the cipher IV，均产生自：
                - 盐值，以字节形式；
                - 10,000 此迭代；
                - `SHA256()` 算法；
                - 头 32 字节属于密码密钥；
                - 第二个 32 字节属于 HMAC 密钥；
                - 其余 16 自己属于密码 IV。
+ 密文经 `hexlify()` 后的字符串。密文为：
    + AES256 加密后的数据。数据加密时用到：
        - AES-CTR 流式密码；
        - 密码密钥；
        - 密码 IV；
        - 以某个整数 IV 作种子的 128 位计数块，a 128-bit counter block seeded from an integer IV；
        + 明文
            - 原始明文
            - 填充到 AES256 的块大小。(用于填充的数据是基于 [RFC5652]()https://tools.ietf.org/html/rfc5652#section-6.3 的）


（End）


