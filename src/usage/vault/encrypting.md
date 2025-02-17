# 使用 Ansible Vault 加密内容

一旦咱们有了某种管理和存储 vault 密码的策略，就可以开始加密内容了。咱们可使用 Ansible Vault 加密两种内容类型：变量与文件。加密的内容总是会包含告诉 Ansible 和 YAML，该内容需要被解密的 `!vault` 标签，以及一个允许多行字符串的 `|` 字符。以 `--vault-id` 命令行开关创建的加密内容，还会包含 vault ID 标签。有关加密过程与使用 Ansible Vault 加密的内容格式的更多详情，请参阅 [使用 Ansible Vault 加密的文件格式](enc_vars_and_files.md#使用-Ansibler-Vault-加密的文件格式)。下面这个表格，显示了加密变量与加密文件的主要区别：


|  | 加密变量 | 加密文件 |
| :-- | :-- | :-- |
| 加密了多少内容？ | 某个纯文本文件里的变量 | 整个文件 |
| 何时会被解密？ | 根据需要，且只在需要时 | 每当被加载或被引用时 <sup>[1](#f-1)</sup> |
| 那些内容可被加密？ | 仅变量 | 任何结构化的数据文件 |

[<a name="f-1">1</a>] 若不解密文件，Ansible 就无法知道，他是否需要某个加密文件中的内容，因此他会解密 playbook 和角色中，所引用的全部加密文件。


## 使用 Ansible Vault 加密单个变量

咱们可以使用 [`ansible-vault encrypt_string`](../cli/ansible-vault.md#encrypt_string) 命令，加密 YAML 文件中的单个值。要了解保持咱们 vault 变量安全可见的一种方法，请参阅 [保持 vault 变量安全可见](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html#tip-for-variables-and-vaults)。

### 变量加密的优缺点


在变量级别的加密下，咱们的文件仍然很容易辨认。咱们可以混合使用明文变量和加密变量，甚至可以在 playbook 或角色中使用。不过，密码轮换不像文件级别加密那么简单。咱们无法为加密变量 [重新设置密钥](#修改加密文件的密码与或-vault-idrekey)。此外，变量级别加密只对变量有效。若咱们要加密任务或其他内容，必须加密整个文件。


### 创建加密的变量


[`ansible-vault encrypt_string`](../cli/ansible-vault.md#encrypt_string) 命令会将咱们输入（或拷贝或生成）的任何字符串，加密为一种可包含在 playbook、角色或变量文件中的格式。要创建某个基本加密变量，就要向 [`ansible-vault encrypt_string`](../cli/ansible-vault.md#encrypt_string) 命令传递以下三个选项：

- 某种 vault 密码来源（提示符、文件或脚本，带有或不带某个 vault ID）；
- 要加密的字符串；
- 字符串的名字（变量的名字）。


模式看起来如下：

```console
ansible-vault encrypt_string <password_source> '<string_to_encrypt>' --name '<string_name_of_variable>'
```

比如，要使用仅存储在 `'a_password_file'` 种的密码，及变量名 `'the_secret'`，加密字符串 `'foobar'`：

```console
ansible-vault encrypt_string --vault-password-file a_password_file 'foobar' --name 'the_secret'
```

上面的命令会创建出以下内容：


```console
the_secret: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      62313365396662343061393464336163383764373764613633653634306231386433626436623361
      6134333665353966363534333632666535333761666131620a663537646436643839616531643561
      63396265333966386166373632626539326166353965363262633030333630313338646335303630
      3438626666666137650a353638643435666633633964366338633066623234616432373231333331
      6564
```

要加密字符串 `'foooodev'`，并以存储在 `'a_password_file'` 中的 `'dev'` vault 密码，添加上 vault ID 标签 `'dev'`，以及调用该加密变量的 `'the_dev_secret'` 名字：


```console
ansible-vault encrypt_string --vault-id dev@a_password_file 'foooodev' --name 'the_dev_secret'
```

上面的命令会创建出如下内容：


```console
the_dev_secret: !vault |
          $ANSIBLE_VAULT;1.2;AES256;dev
          61373932663963623339363465383238346463346530316662366430613666333036626261323462
          3836396338343234393733316335353232623239646661300a636535663763373033336561663561
          30386163353863366335383531613930386138356438373161306335623165626365646464653035
          3531333332613633310a666461333138383630643837393932643532346336393363616165303863
          6263
```

要加密从 `stdin` 读取的字符串 `'letmein'`，并使用存储在 `'a_password_file'` 中的 `'dev'`  vault 密码，添加上 vault ID `'dev'`，以及将该变量命名为 `'db_password'`：


```console
$ echo -n 'letmein' | ansible-vault encrypt_string --vault-id dev@/home/hector/.ansible/passwd --stdin-name 'db_password'
Reading plaintext input from stdin. (ctrl-d to end input, twice if your content does not already have a newline)

Encryption successful
db_password: !vault |
          $ANSIBLE_VAULT;1.2;AES256;dev
          30663439336239636235633733653735666431663739306337383261333266666238653836323732
          6338323332663331353732383934316265396264643961350a383132303630653835363630396637
          63313834326362616564376531316364646265363466643730323366346536363763663737626432
          3631396261636563350a316466373637626630363633373638353235656635303031353061333165
          3133
```

> **注意**：直接在命令行输入秘密内容（无提示符下），会在 shell 历史记录中留下该秘密字符串。请勿在测试之外这样做。

要在提示符下输入某个要加密的字符串，并用 `'a_password_file'` 中的 `'dev'` vault 密码加密，且将该变量命名为 `'new_user_password'`，并给他 vault ID 标签 `'dev'`：


```console
$ ansible-vault encrypt_string --vault-id dev@/home/hector/.ansible/passwd --stdin-name 'new_user_password'
Reading plaintext input from stdin. (ctrl-d to end input, twice if your content does not already have a newline)
xfoss.com
Encryption successful
new_user_password: !vault |
          $ANSIBLE_VAULT;1.2;AES256;dev
          34643864613965323935303861626165646336353633613939653039616637393534653036303666
          6364333233303439656534666230343739323639646133330a663238386235653461653836636238
          33613831326465313333643063636662653761333661306235373165326134626133353433643531
          6530393535383864310a643233613638383063623063656137343731663561626138393631396130
          3931
```

上面的命令会触发下面这个提示：

```console
Reading plaintext input from stdin. (ctrl-d to end input, twice if your content does not already have a newline)
```

输入要加密的字符串（例如 `'xfoss.com'`），按下 `ctrl-d`，然后等待。


> **注意**：请勿在提供了要加密的字符串后按 `Enter`。这会在加密的值上添加一个换行符。


咱们可以将上述任一示例的输出，添加到任何的 playbook、变量文件或角色中供将来使用。加密的变量要比纯文本的变量大，但他们能保护咱们的敏感内容，同时以纯文本方式，保留 playbook、变量文件或角色的其余部分，以便咱们能轻松阅读。


### 查看加密的变量

使用 `debug` 模组，咱们就可以查看某个加密变量的原始值。咱们必须传递用于加密该变量的密码。例如，若咱们已将上一示例中，创建的变量存储在名为 `'vars.yml'` 的某个文件中，那么咱们就可以像下面这样，查看该变量的未加密值：


```console
$ ansible localhost -m ansible.builtin.debug -a var="new_user_password" -e "@vault_demos/vars.yml" --vault-id dev@~/.ansible/passwd
[WARNING]: No inventory was parsed, only implicit localhost is available
localhost | SUCCESS => {
    "new_user_password": "xfoss.com"
}
```


## 使用 Ansible Vault 加密文件


Ansible Vault 可加密 Ansible 使用的任何结构化数据文件，包括：

- 仓库中的组变量文件；
- 仓库中的主机变量文件；
- 使用 `-e @file.yml` 或 `-e @file.json` 等传递给 `ansible-playbook` 命令的变量文件；
- 由 `include_vars` 或 `vars_files` 指令所加载的变量文件；
- 角色中的变量文件；
- 角色中的默认文件；
- 任务文件；
- 处理器文件；
- 二进制文件或其他任意文件。


整个文件都会在 vault 中加密。


> **注意**：Ansible Vault 会使用某种编辑器，创建或修改加密文件。有关确保编辑器安全的指导，请参阅 [确保编辑器安全的步骤](#保全编辑器的步骤)。


### 加密文件的优点和缺点


文件级别的加密易于使用。加密文件的密码轮换，直接可以使用 [`rekey`](#rekey) 命令完成。对文件进行加密，不仅可以隐藏那些敏感值，还可以咱们所使用变量的名字。不过，在文件级别加密下，文件内容就不再容易访问和阅读。这可能是加密任务文件的一个问题。在加密某个变量文件时，请参阅 [“保持库变量安全可见”](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html#tip-for-variables-and-vaults)，了解在非加密文件中保留对这些加密变量引用的一种方法。在某个加密文件被加载或引用到时，Ansible 总是会解密整个加密文件，因为除非解密该文件，Ansible 就无法知道是否需要其内容。


### 创建加密文件


使用 `~/.ansible/secrets` 中的 `'dev'` vault 密码，创建一个名为 `'foo.yml'` 的新加密数据文件：


```console
ansible-vault create --vault-id dev@~/.ansible/secrets vault_demos/foo.yml
```

该工具会启动某个编辑器（咱们以 `$EDITOR` 环境变量定义的编辑器，默认编辑器为 `vi`）。请添加内容。在咱们关闭编辑器会话后，该文件将被保存为加密数据。文件的头部会反映出创建文件所使用的 vault ID：


```text
$ANSIBLE_VAULT;1.2;AES256;dev
```


要以指定了 `'my_new_password` 的 vault ID，提示输入的密码，创建一个新加密数据文件：

```console
$ ansible-vault create --vault-id my_new_password@prompt vault_demos/bar.yml
New vault password (my_new_password):
Confirm new vault password (my_new_password):
```

同样，请在编辑器中添加内容到该文件并保存。请确保把咱们在提示符下创建的新密码保存起来，这样当咱们要解密该文件时，就能找到他。



### 加密既有文件


要加密某个现有文件，就要使用 [`ansible-vault encrypt`](../cli/ansible-vault.md#encrypt) 命令。该命令可同时对多个文件执行。例如：

```console
ansible-vault encrypt foo.yml bar.yml baz.yml
```

要以 `~/.ansible/secrets` 中的 `'prod'` 的 vault ID，加密既有文件：

```console
ansible-vault encrypt --vault-id prod@~/.ansible/secrets foo.yml bar.yml baz.yml
```

> **译注**：使用 `--vault-id project@prompt` 以 `'project'` 作为 vault ID，并在提示符下输入密码同样可以。

### 查看加密的文件


要查看某个加密文件的内容而不对其进行编辑，咱们可使用 [`ansible-vault view`](../cli/ansible-vault.md#view) 命令：


```console
ansible-vault view foo.yml bar.yml baz.yml
```

> **译注**：
>
> - 经测试，使用密码文件与 vault ID 加密的文件，无法通过提示符提供的密码查看到。反之亦然。
>
> - 还发现，vault ID 与密码文件结合使用时，即使将不同 vault ID 与同一密码文件使用，也能查看到加密文件。但若修改了密码文件，就立即无法查看到加密文件。这再次表明了 `ansible-vault` 会将密码文件视为一个整体，将其当作加密时使用的密码，而不管密码文件是单行还是多行；且 vault ID 与密码文件并无紧密关系。


### 编辑加密文件

要就地编辑某个加密文件，就要使用 [`ansible-vault edit`](../cli/ansible-vault.md#edit) 命令。该命令将该文件解密为一个临时文件，允许咱们编辑内容，然后保存并重新加密内容，并在关闭编辑器时删除临时文件。例如：

```console
ansible-vault edit --vault-id prod@~/.ansible/secrets foo.yml
```

要编辑某个以 `vault2` 的密码文件加密，并分配了 vault ID `pass2` 的文件：

```console
ansible-vault edit --vault-id pass2@vault2 foo.yml
```

<a name="rekey"></a>
### 修改加密文件的密码与/或 vault ID，`rekey`
要更改某个加密文件，或某些加密文件的密码，要使用 [`ansible-vault rekey`](../cli/ansible-vault.md#rekey) 命令：


```console
ansible-vault rekey foo.yml bar.yml baz.yml
```

该命令可同时为多个数据文件重新设置密钥，将请求输入原始密码和新密码。要为重置密钥文件设置某个别的 vault ID，就要把新 ID 传递给 `--new-vault-id` 这个命令行选项。例如，要将以 `'ppold'` 密码文件中 `'preprod1'` vault ID 加密的文件，重置密钥为 `'preprod2'` vault ID，并要提示输入新的密码：

```console
ansible-vault rekey --vault-id preprod1@ppold --new-vault-id preprod2@prompt foo.yml bar.yml baz.yml
```


### 解密出加密文件


若咱们有个不再想保持加密的加密文件，咱们可通过运行 [`ansible-vault decrypt`](../cli/ansible-vault.md#decrypt) 命令，将其永久解密。该命令会将未加密的文件保存到磁盘，因此请确保咱们不是要 [编辑](#编辑加密文件) 他。

```console
ansible-vault decrypt foo.yml bar.yml baz.yml
```


### 解密出加密字符串


若咱们只想要检查某个加密字符串的内容，咱们还可以通过 `stdin` 传入字符串来查看他：

```console
echo -e '$ANSIBLE_VAULT;1.1;V2\neyJrZXkiOiAiZ0FBQUFBQm5UYzlPUVgzeUc5NFo3R2pzYVNMSXVsdXA3Z0paMmczNVRtS0NqMUcwMTVx\nSU1JVDlJZlRrSXBkVThmLXhKS00xZGl6X3F3YXZmWWUteGJWaHNZZXZNWl9hMWZvLVRYM3ZUZDRvaHRR\nWkhIdkJmZEZWNlBwVjhNVjJFT05QbDFwandaazAiLCAiY2lwaGVydGV4dCI6ICJnQUFBQUFCblRjOU9u\nWmM2dDh2VEN5c3NTQVlyV0hMclNEOFZfSGd2eEVHdERCdkJfakFpcUpaWWNTV19sR2hPY0VsWEVweS0z\nQ0NBcmJfdUdsUEt0NzJuSmFxVVVmRFIzdz09In0=' | ansible-vault decrypt
```

或者，咱们也可使用以下命令，让 Ansible 提示咱们输入（使用两次 `Ctrl+D` 结束输入），就像使用 `encrypt_string` 一样：


```console
ansible-vault decrypt
Reading ciphertext input from stdin
```


### 确保编辑器安全的一些步骤


Ansible Vault 依赖于咱们所配置的编辑器，而这就可能是一种泄密源。大多数编辑器都有一些阻止数据丢失的方法，但这些方法通常会依赖于可包含咱们机密明文副本的一些额外纯文本文件。请查阅编辑器文档，将编辑器配置为避免泄露安全数据。以下小节提供了一些常见编辑器的指南，但不应被视为确保编辑器安全的完整指南。

- **`vim`**

咱们可在命令模式下设置以下 `vim` 选项，以避免泄密情形。为确保安全，咱们可能需要修改更多设置，尤其是在使用一些插件时，请查阅 `vim` 文档。


1. 禁用在崩溃或中断时，起自动保存作用的 `swapfile`；

```console
:set noswapfile
```

2. 禁用创建备份文件；

```console
:set nobackup
:set nowritebackup
```

3. 仅用从咱们的当前会话拷贝数据的 `viminfo` 文件；

```console
:set viminfo=
```

4. 禁用拷贝到系统剪贴板。

```console
:set clipboard=
```

咱们可选择将这些设置，添加到 `.vimrc` 中对所有文件生效，或仅对特定路径或文件扩展名生效。详情请查看 `vim` 的手册。


- **Emacs**


咱们可设置以下 Emacs 选项来避免泄密情形。为确保安全，咱们可能需要修改更多设置，尤其是在使用插件时，请查阅 Emacs 文档。


1. 不要拷贝数据到系统剪贴板；


```console
(setq x-select-enable-clipboard nil)
```

2. 禁用创建备份文件；

```console
(setq make-bakcup-files nil)
```

3. 禁用自动保存文件。


```console
(setq auto-save-default nil)
```

（End）


