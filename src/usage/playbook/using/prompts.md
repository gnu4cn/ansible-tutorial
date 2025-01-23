# 交互式输入：提示符

若咱们想要咱们的 playbook，提示用户输入某些内容，就要添加一个 `vars_prompt` 小节。提示用户提供一些变量，可避免记录像是口令这样的敏感数据。除了安全性，提示符还提供了灵活性。例如，如果咱们在多个软件版本间，使用一个 playbook，就可以提示以特定版本提示用户。

以下是个基本示例：


```yaml
---
- hosts: all
  vars_prompt:

    - name: username
      prompt: What is your username?
      private: false

    - name: password
      prompt: What is your password?

  tasks:

    - name: Print a message
      ansible.builtin.debug:
        msg: 'Logging in as {{ username }}'
```


默认情况下，用户输入是隐藏的，但可通过设置 `private: false` 使其可见。


> **注意**：对于已通过命令行的 `--extra-vars` 选项定义的变量，或自非交互会话（如 `cron` 或 Ansible AWX）运行 playbook 时，这些 `vars_prompt` 变量的提示将被跳过。请参阅 [在运行时定义变量](vars.md)。


若咱们有个不经常变化的变量，那么可提供一个可覆盖的默认值。

```yaml
  vars_prompt:

    - name: release_version
      prompt: Product release version
      default: "1.0"
```


## 哈希化由 `vars_prompt` 提供的值

咱们可对输入的值进行哈希处理，以便咱们可以使用他，例如，在用户模组下定义一个口令变量：


```yaml
  vars_prompt:

    - name: my_password2
      prompt: Enter password2
      private: true
      encrypt: sha512_crypt
      confirm: true
      salt_size: 7
```

若咱们安装了 [`Passlib`](https://passlib.readthedocs.io/en/stable/)，就可以使用该库支持的全部加密方案：

- `des_crypt` - DES 加密
- `bsdi_crypt` - BSDi 加密
- `bigcrypt` - BigCrypt
- `crypt16` - Crypt16
- `md5_crypt` - MD5 加密
- `bcrypt` - BCrypt
- `sha1_crypt` - SHA-1 加密
- `sun_md5_crypt` - Sun MD5 加密
- `sha256_crypt` - SHA-256 加密
- `sha512_crypt` - SHA-512 加密
- `apr_md5_crypt` - Apache 基金会的 MD5-Crypt 变种
- `phpass` - [PHPass](https://www.openwall.com/phpass/) 的可移植哈希
- `pbkdf2_digest` - 通用 PBKDF2 哈希，参考：[The specification for the PBKDF2 algorithm](http://tools.ietf.org/html/rfc2898#section-5.2)
- `cta_pbkdf2_sha1` - Dwayne Litzenberger 的 PBKDF2 哈希
- `scram` - SCRAM 哈希
- `bsd_nthash` - FreeBSD 的 MCF 兼容 nthash 编码


唯一接受的参数是 `'salt'` 或 `'salt_size'`。咱们可通过定义 `'salt'`，使用自己的盐值，也可使用 `'salt_size'` 自动生成盐值。默认情况下，Ansible 会生成大小为 `8` 的盐值。


*版本 2.7 中的新特性*。

若咱们没有安装 `Passlib`，Ansible 将使用 [`crypt`](https://docs.python.org/3/library/crypt.html) 库作为备用。此时 Ansible 最多支持四种加密方案，根据平台不同，最多支持以下加密方案：


- `bcrypt` - BCrypt
- `md5_crypt` - MD5 加密
- `sha256_crypt` - SHA-256 加密
- `sha512_crypt` - SHA-512 加密

*版本 2.8 中的新特性*。


## 允许 `vars_prompt` 值中的特殊字符

一些特殊字符，比如 `{` 和 `%`，会造成模板错误。若咱们需要接受特殊字符，就要使用 `unsafe` 选项：


```yaml
  vars_prompt:
    - name: my_password_with_weird_chars
      prompt: Enter password
      unsafe: true
      private: true
```


（End）


