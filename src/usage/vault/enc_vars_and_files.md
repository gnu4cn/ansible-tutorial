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



（End）



