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


