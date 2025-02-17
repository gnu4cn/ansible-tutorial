# 管理 vault 密码


如果咱们能制定一套管理 vault 密码的策略，那么管理咱们的加密内容就会变得更加容易。Vault 密码可以是咱们所选择的任何字符串。并无创建 vault 密码的特殊命令。不过，咱们需要记录咱们的 vault 密码。每次咱们以 Ansible Vault 加密变量或文件时，都必须提供一个密码。在某个命令或 playbook 中使用加密的变量或文件时，咱们都必须提供加密他们所使用的同一密码。要制定出管理 vault 密码的策略，请从两个问题入手：

- 咱们打算以同一个密码加密所有内容，还是根据不同的需要使用不同密码？
- 咱们想要在哪里存储密码？


## 在单一密码与多个密码间做出选择


若咱们的团队规模较小或敏感数据较少，咱们可以使用单一密码对 Ansible Vault 的所有内容进行加密。如下所述，要将咱们的 vault 密码安全地存储在某个文件，或密码管理器中。

而如果咱们有个较大的团队，或许多敏感数据，就可以使用多个密码。例如，咱们可以为不同的用户，或不同的访问级别，使用不同的密码。根据需要，咱们可能需要为每个加密文件、每个目录或每种环境，设置不同密码。咱们可能有个包含了两个变量文件的 playbook，其中一个用于开发环境，一个用于生产环境，分别用两个不同密码加密。在咱们运行该 playbook 时，可以使用 vault ID 为咱们所针对的环境，选择正确的vault 密码。


## 使用 vault ID 管理多个密码


若咱们使用了多个 vault 密码，则可使用 vault ID，区分不同密码。咱们可以以下三种方式使用 vault ID：

- 在咱们创建加密内容时，以 `--vault-id` 命令行开关，将其传递给 [`ansible-vault`](../cli/ansible-vault.md) 命令；
- 将其包含在咱们存储该 vault ID 所对应密码的地方（请参阅 [存储和访问 vault 密码](#存储与访问-vault-密码)）；
- 在运行某个用到以该 vault ID 加密的内容的游戏本时，以 `--vault-id` 命令行开关，将其传递给 [`ansible-playbook`](../cli/ansible-playbook.md) 命令。

当咱们将某个 vault ID 作为命令行选项，传递给 [`ansible-vault`](../cli/ansible-vault.md) 命令时，咱们就把一个标签（某种提示或昵称），添加到了加密的内容。该标签记录了咱们加密该内容所使用的密码。被加密的变量或文件，在头部包含了纯文本的 vault ID 标签。Vault ID 是加密内容前，最后那个元素。例如：


```yaml
my_encrypted_var: !vault |
          $ANSIBLE_VAULT;1.2;AES256;dev
          30613233633461343837653833666333643061636561303338373661313838333565653635353162
          3263363434623733343538653462613064333634333464660a663633623939393439316636633863
          61636237636537333938306331383339353265363239643939666639386530626330633337633833
          6664656334373166630a363736393262666465663432613932613036303963343263623137386239
          6330
```

除标签外，咱们还必须提供所关联密码的来源。来源可以是提示符、某个文件或某个脚本，具体取决于咱们存储 vault 密码的方式。模式如下：


```console
--vault-id label@source
```


若咱们的 playbook 用到多个咱们以不同密码加密的加密变量或文件，那么当咱们运行该 playbook 时，就必须传递这些 vault ID。咱们可单独使用 `--vault-id` 命令行开关，也可与 `--vault-password-file` 或 `--ask-vault-pass` 一起使用。其模式与创建加密内容时相同：要包含标签和与之匹配的密码来源。


有关以 vault ID 加密内容，及使用以 vault ID 加密的内容的示例，请参阅下文。`--vault-id` 这个命令行选项，适用于任何与 vault 交互的Ansible 命令，包括 [`ansible-vault`](../cli/ansible-vault.md)、[`ansible-playbook`](../cli/ansible-playbook.md) 等。


### Vault ID 的局限性


在咱们每次使用某个特定 vault ID 标签时，Ansible 不会强制要求都使用同一密码。咱们可使用同一 vault ID 标签，但以不同密码加密不同变量或文件。这种情况通常发生在咱们于某个提示符下，输入密码时出错。有意使用不同的密码和同一 vault ID 标签也是可能的。例如，咱们可将各个标签，用作某一类密码，而不仅是单个密码的参考。在这种情形下，咱们必须始终清楚，在上下文中要使用哪个特定密码或文件。不过，咱们更有可能会错误地用相同的 vault ID 标签，与不同的密码加密了两个文件。若咱们不小心以同一标签但不同密码加密了两个文件，咱们可以重制密钥（[`rekey`](encryping.md#rekey)）一个文件，解决这个问题。


### 强制执行 vault ID 匹配

默认情况下，vault ID 标签只是个提醒咱们，使用哪个密码加密某个变量或文件的提示。Ansible 不会检查加密内容头部的 vault ID，是否与咱们使用该内容时，所提供的 vault ID 一致。Ansible 会解密咱们命令或 playbook 所调用的，由咱们所提供密码加密的所有文件和变量。要只在加密内容中包含的 vault ID，与咱们用 `--vault-id` 命令行所提供的 ID 匹配时，才检查及解密这些加密内容，就要设置配置选项 [`DEFAULT_VAULT_ID_MATCH`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-vault-id-match)。当咱们设置了 [`DEFAULT_VAULT_ID_MATCH`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-vault-id-match) 后，各个密码就只会用于解密，使用同一标签加密的数据了。这样做既高效又可预测，还能减少以不同密码加密不同值时出现的错误。

> **注意**：即使启用了 `DEFAULT_VAULT_ID_MATCH` 设置，Ansible 也不会强制要求，咱们每次使用某个特定 vaul ID 标签时，都使用同一密码。


## 存储与访问 vault 密码


咱们可以记住咱们的 vault 密码，或从任意来源手动拷贝 vault 密码并在某个命令行提示符处粘贴他们，但大多数用户都会安全地把他们存储下来，并在需要时从 Ansible 中访问他们。咱们有两种存储 vault 密码可供 Ansible 中使用的选项：存储在文件中，或比如系统密钥环，the system keyring，及密码管理器，the secret manager 等第三方工具中。若咱们把密码存储在了第三方工具中，咱们需要某种 vault 密码客户端脚本，以在 Ansible 中获取到密码。


### 在文件中存储密码


要在某个文件中存储某个 vault 密码，就要在该文件中单个行上，以字符串形式键入该密码。要确保该文件权限适当。请勿将密码文件，添加到源码控制系统。


当咱们运行某个，用到存储在某个文件中 vault 密码的 playbook 时，就要在 `--vault-password-file` 命令行中指定出该文件。例如：


```yaml
ansible-playbook --extra-vars @secrets.enc --vault-password-file secrets.pass
```

> **译注**：**一个密码文件，只能保存一个密码**。而一个密码文件可以对应多个 vault ID。Vault ID 是存储在加密变量中的一种逻辑。


### 使用 vault 密码客户端脚本在第三方工具中存储密码

咱们就可将咱们 vault 密码，存储在系统密钥环、某个数据库或密码管理器中，然后在 Ansible 中使用某种 vault 密码客户端脚本获取到这些密码。要以单行字符串形式，输入密码。若咱们的密码有个 vault ID，则要将其与咱们密码存储工具相符的方式存储起来。


要创建某种 vault 密码客户端脚本：

- 创建一个以 `-client` 或 `-client.EXTENSION` 结尾名字的文件；
- 使该文件成为可执行；
+ 在该脚本内部：
    - 将密码打印到标准输出；
    - 接受一个 `--vault-id` 选项；
    - 如果脚本要提示数据输入（比如，某个数据库密码），则要将提示符示显示到 TTY。


当咱们运行某个，使用了存储在某个第三方工具中 vault 密码的 playbook 时，就要在 `--vault-id` 命令行中，将这个脚本指定为来源。例如：


```console
ansible-playbook --vault-id dev@contrib-scripts/vault/vault-keyring-client.py
```


Ansible 会以一个 `--vault-id` 选项执行该客户端脚本，因此该脚本就清楚，咱们指定了哪个 vault ID 标签。比如，某个从密码管理器加载密码的脚本，就可以使用这个 vault ID 标签，选取 `'dev'` 或 `'prod'` 的密码。上面的示例命令，会得到其中客户端脚本的如下执行：


```console
contrib-scripts/vault/vault-keyring-client.py --vault-id dev
```


有关从系统密钥环加载密码的客户端脚本示例，请参阅 [ansible-community/contrib-scripts](https://github.com/ansible-community/contrib-scripts/blob/main/vault/vault-keyring-client.py)。


（End）


