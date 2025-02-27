# 列出专辑


要列出已安装的专辑，请运行 `ansible-galaxy collection list`。这会显示出在所配置的专辑检索路径中，找到的全部已安装集合。他还将显示出那些包含一个 `galaxy.yml` 文件而非 `MANIFEST.json` 文件的，出于开发中的专辑。专辑所处的路径，与版本信息会一并显示出来。若没有可用的版本信息，则会显示一个 `*` 作为版本号。


```console
$ ansible-galaxy collection list

# /home/hector/.ansible/collections/ansible_collections
Collection            Version
--------------------- -------
ansible.netcommon     7.1.0
ansible.posix         2.0.0
ansible.utils         5.1.2
ansible.windows       2.7.0
chocolatey.chocolatey 1.5.3
community.general     10.2.0
kubernetes.core       5.0.0


# /usr/share/ansible/collections/ansible_collections
Collection        Version
----------------- -------
fortinet.fortios  1.0.6
pureport.pureport 0.0.8
sensu.sensu_go    1.3.0
```

以 `-vvv` 命令行开关运行，就会显示更多详细信息。咱们可能会在此看到，作为咱们已安装专辑的依赖项，而添加的一些其他专辑。要在咱们的 playbook 中，只使用咱们已直接安装的那些专辑。


要列出某特定专辑，就要将一个有效的完全合格专辑名称 (FQCN)，传递给 `ansible-galaxy collection list` 命令。该专辑所有实例都将被列出。


```console
$ ansible-galaxy collection list fortinet.fortios

# /home/hector/.ansible/collections/ansible_collections
Collection       Version
---------------- -------
fortinet.fortios 2.3.9

# /usr/share/ansible/collections/ansible_collections
Collection       Version
---------------- -------
fortinet.fortios 1.0.6
```

要检索其他路径的专辑，就使用 `-p` 命令行选项。以 `:` 分隔多个路径，指定出他们。在命令行中指定出的路径列表，将被添加到已配置的专辑检索路径开头。


```console
> ansible-galaxy collection list -p '/opt/ansible/collections:/etc/ansible/collections'

# /opt/ansible/collections/ansible_collections
Collection      Version
--------------- -------
sandwiches.club 1.7.2

# /etc/ansible/collections/ansible_collections
Collection     Version
-------------- -------
sandwiches.pbj 1.2.0

# /home/hector/.ansible/collections/ansible_collections
Collection            Version
--------------------- -------
ansible.netcommon     7.1.0
ansible.posix         2.0.0
ansible.utils         5.1.2
ansible.windows       2.7.0
chocolatey.chocolatey 1.5.3
community.general     10.2.0
fortinet.fortios      2.3.9
kubernetes.core       5.0.0

# /usr/share/ansible/collections/ansible_collections
Collection        Version
----------------- -------
fortinet.fortios  1.0.6
pureport.pureport 0.0.8
sensu.sensu_go    1.3.0
```

（End）


