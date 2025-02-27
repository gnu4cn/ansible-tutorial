# 下载专辑


要为离线安装而下载某个专辑及其依赖项，请运行 `ansible-galaxy collection download` 命令。这会下载将指定专辑及其依赖项，到指定文件夹，并会创建出一个可用于在无法访问 Galaxy 服务器的主机上，安装这些程序集的 `requirements.yml` 文件。默认情况下，所有这些专辑都会下载到 `./collections` 这个文件夹。


与 `install` 命令一样，这些专辑的来源，也是基于 [所配置的 Galaxy 服务器配置](installation.md##配置-ansible-galaxy-客户端)。即使要下载的专辑是由某个 URL 或到 `tar` 包的路径所指定的，该专辑也会从所配置的 Galaxy 服务器重新下载。


这些专辑可被指定为一或多个专辑，或就像 `ansible-galaxy collection install` 命令一样，使用一个 `requirements.yml` 文件。


要下载某单个专辑与其依赖项：


```console
ansible-galaxy collection download my_namespace.my_collection
```


要下载指定版本的某单个专辑：


```console
ansible-galaxy collection download my_namespace.my_collection:1.0.0
```

要下载多个专辑，要么如上所示将多个专辑指定为命令行参数，要么以 [“使用需求文件安装多个专辑”](installation.md#使用需求文件安装多个专辑) 中所记录的格式，使用一个需求文件。


```console
ansible-galaxy collection download -r requirements.yml
```

咱们还可下载某个源代码的专辑目录。该专辑将以必须的 `galaxy.yml` 文件构建出来。


```console
ansible-galaxy collection download /path/to/collection

ansible-galaxy collection download git+file:///path/to/collection/.git
```

通过提供到某单个命名空间的路径，咱们可下载该命名空间中的多个源代码专辑。


```console
ns/
├── collection1/
│   ├── galaxy.yml
│   └── plugins/
└── collection2/
    ├── galaxy.yml
    └── plugins/
```


```console
ansible-galaxy collection install /path/to/ns
```

默认情况下，所有专辑都会被下载到 `./collections` 这个文件夹，但也可以使用 `-p` 或 `--download-path` 命令行参数，指定其他路径：

```console
ansible-galaxy collection download my_namespace.my_collection -p ~/offline-collections
```

一旦咱们已下载这些专辑，该文件夹就会包含所指定的专辑、他们的依赖项以及一个 `requirements.yml` 文件。咱们可以将此文件夹原封不动地与 `ansible-galaxy collection install` 一起使用，在无法访问 Galaxy 服务器的主机上安装这些专辑。


```console
# This must be run from the folder that contains the offline collections and requirements.yml file downloaded
# by the internet-connected host
cd ~/offline-collections
ansible-galaxy collection install -r requirements.yml
```

（End）


