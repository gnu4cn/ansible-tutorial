# 验证专辑

## 使用 `ansible-galaxy` 验证专辑


一旦安装了某个专辑，咱们可以验证该已安装专辑的内容，是否与服务器上的该专辑内容一致。该功能要求该专辑被安装在某个已配置的专辑路径中，且该专辑存在于某个已配置的 galaxy 服务器上。


```console
ansible-galaxy collection verify my_namespace.my_collection
```


在 `ansible-galaxy collection verify` 命令成功时，其输出是会是静默的。而若某个专辑被修改了，则被修改的文件会被列出在该专辑的名字下。


```console
$ ansible-galaxy collection verify chocolatey.chocolatey
Downloading https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/artifacts/chocolatey-chocolatey-1.5.3.tar.gz to /home/hector/.ansible/tmp/ansible-local-124731y90jgxvi/tmpm6zfutj9/chocolatey-chocolatey-1.5.3-rtsd3yzj
Verifying 'chocolatey.chocolatey:1.5.3'.
Installed collection found at '/home/hector/.ansible/collections/ansible_collections/chocolatey/chocolatey'
MANIFEST.json hash: 46ef5da34095001272231044708446a57f1692293326ed04cf8abbe060dbfcf3
Collection chocolatey.chocolatey contains modified content in the following files:
    plugins/modules/win_chocolatey_source.py
    plugins/modules/win_chocolatey.py
```

咱们可使用 `-vvv` 命令行开关，显示其他信息，比如该已安装专辑的版本与路径、用于验证的远端专辑的 URL，以及成功的验证输出等。


```console
$ ansible-galaxy collection verify fortinet.fortios -vvv                     ✔  15s 
...
Verifying 'fortinet.fortios:2.3.9'.
Installed collection found at '/home/hector/.ansible/collections/ansible_collections/fortinet/fortios'
Collection 'fortinet.fortios:2.3.9' obtained from server Galaxy
Remote collection cached as '/home/hector/.ansible/tmp/ansible-local-125076nmi_vr0c/tmp0t1df04k/fortinet-fortios-2.3.9-b2evf7ym/fortinet-fortios-2.3.9.tar.gz'
MANIFEST.json hash: edd99c086a582a32aceadf5feb2c61f055bf6e51179dbfc44ffc9b209c99ea0b
Successfully verified that checksums for 'fortinet.fortios:2.3.9' match the remote collection.
```

如果咱们安装了某个预发布或非最新版本的专辑，则咱们应包含要验证的特定版本。若省略了版本，那么该安装的专辑，将根据服务器上的最新版本进行验证。

```console
ansible-galaxy collection verify my_namespace.my_collection:1.0.0
```

除了 `namespace.collection_name:version` 这种格式外，咱们还可以在一个 `requirements.yml` 文件中，提供要验证的专辑。`requirements.yml` 中所列出专辑的依赖项，不包括在 `verify` 的过程中，而应单独验证他们。


```console
ansible-galaxy collection verify -r requirements.yml
```

与 `tar.gz` 文件的验证不受支持。如果咱们的 `requirements.yml` 包含了用于安装的到 `tar` 文件的路径或 URL，咱们可使用 `--ignore-errors` 命令行开关，确保该文件中所有使用 `namespace.name` 格式的专辑均被处理（验证）。


## 验证签名的专辑


如果某个专辑已由某个 [分发服务器](https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html#term-Distribution-server) 签名，那么该服务器就会提供 ASCII 批覆的、分离签名，ASCII armored, detached signatures，以验证 `MANIFEST.json` 的真实性，然后再用来验证该专辑的内容。并非所有分发服务器都提供此选项。请参阅 [分发专辑](https://docs.ansible.com/ansible/latest/dev_guide/developing_collections_distributing.html#distributing-collections)，查看支持专辑签名的服务器列表。有关如何在咱们安装某个已签名的专辑时，对其进行验证，请参阅 [安装带有签名验证的专辑](installation.md#安装有签名验证的专辑)。

要验证某个签名的已安装专辑：

```console
ansible-galaxy collection verify my_namespace.my_collection  --keyring ~/.ansible/pubring.kbx
```

使用 `--signature` 命令行选项，以其他签名验证 CLI 上所提供的专辑名字。此选项可多次使用，以提供多个签名。


```console
ansible-galaxy collection verify my_namespace.my_collection --signature https://examplehost.com/detached_signature.asc --signature file:///path/to/local/detached_signature.asc --keyring ~/.ansible/pubring.kbx
```

作为可选项，咱们可使用一个 `requirements.yml` 文件，验证专辑签名。


```console
ansible-galaxy collection verify -r requirements.yml --keyring ~/.ansible/pubring.kbx
```

当某个专辑是安装自某个分发服务器时，那么由该服务器提供的，用于验证该专辑真实性的签名，就会被保存在该已安装专辑边上。当提供了 `--offline` 这个命令行选项时，这些数据将用于验证该专辑的内部一致性，而无需再次查询分发服务器。


```console
ansible-galaxy collection verify my_namespace.my_collection --offline --keyring ~/.ansible/pubring.kbx
```


（End）


