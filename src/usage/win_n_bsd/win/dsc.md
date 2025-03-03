# 预期状态设定

**Desired State Configuration**


## 何为预期状态设定？


预期状态设定，Desired State Configuration，简称 DSC，是内建于 PowerShell 的一个工具，可用于通过代码定义 Windows 主机设置。DSC 的总体目的与 Ansible 相同，只是被执行方式不同。自版本 2.4 起，Ansible 就添加了 `win_dsc` 模组，可在与 Windows 主机交互时，利用现有的 DSC 资源。

有关 DSC 的更多详细信息，请访问 [DSC 概述](https://docs.microsoft.com/en-us/powershell/scripting/dsc/overview?view=powershell-7.2)。

> **参考**：
>
> - [使用預期狀態設定(DSC)對多部伺服器進行一致的設定](https://www.uuu.com.tw/Public/content/article/140714tips.htm)


## 主机要求

要使用 `win_dsc` 这个模组，Windows 主机必须有安装 PowerShell v5.0 或更新版本。所有受支持的主机，都可以升级到 PowerShell v5。

一旦 PowerShell 的要求已满足，那么使用 DSC 就跟使用 `win_dsc` 模组创建某个任务这么简单了。


## 为何要用 DSC？


DSC 和 Ansible 的那些模组，有着共同的目标，那就是定义并确保某项资源的状态。因此，像是 DSC [文件资源](https://docs.microsoft.com/en-us/powershell/scripting/dsc/reference/resources/windows/fileresource) 与 Ansible `win_file` 这样的资源，可用于达成同一结果。而决定要使用哪个，则取决于具体场景。


使用 Ansible 模组而非 DSC 资源的理由：

- 主机不支持 PowerShell v5.0，或无法轻易被升级；
- DSC 资源未提供某个 Ansible 模组中存在的某项功能。例如，`win_regedit` 可以管理 `REG_NONE` 的属性类型，而 DSC 的 `Registry` 资源则不能；
- DSC 资源的检查模式支持有限，而一些 Ansible 模组则有着更好的检查；
- DSC 资源不支持差异模式，diff mode，而一些 Ansible 模组则支持；
- 一些自定义资源要运行在主机上，需要事先的一些进一步安装步骤，而 Ansible 模组则内置在 Ansible 中；
- Ansible 模组可工作的某个 DSC 资源中存在 bug。


使用 DSC 资源而非 Ansible 模组的原因：

- Ansible 模组不支持，但某个 DSC 资源中存在的某项功能；
- 尚无可用的 Ansible 模组；
- 现有的某个 Ansible 模组中存在 bug。


归根结底，是以 DSC 还是以 Ansible 模组，执行某项任务并不重要，重要的是该任务被正确执行，且 playbook 仍然可读。若咱们 DSC 的经验比 Ansible 更多，而且他会完成任务，那就使用 DSC 完成该任务。


## 怎样使用 DSC？

`win_dsc` 模组接收自由格式的选项，以便根据其所管理的资源而变通。可在 [资源](https://docs.microsoft.com/en-us/powershell/scripting/dsc/resources/resources) 处找到一个内置资源的列表。


以 [`Registry`](https://docs.microsoft.com/en-us/powershell/scripting/dsc/reference/resources/windows/registryresource) 这个资源为例，以下是微软文档中的 DSC 定义：

```
Registry [string] #ResourceName
{
    Key = [string]
    ValueName = [string]
    [ Ensure = [string] { Enable | Disable }  ]
    [ Force =  [bool]   ]
    [ Hex = [bool] ]
    [ DependsOn = [string[]] ]
    [ ValueData = [string[]] ]
    [ ValueType = [string] { Binary | Dword | ExpandString | MultiString | Qword | String }  ]
}
```

定义任务时，`resource_name` 字段必须设置为正使用的 DSC 资源 -- 在此情形下，`resource_name` 应设置为 `Registry`。`module_version` 字段可指向该已安装 DSC 资源的特定版本；若该字段留空，则默认为最新版本。其他选项为用于定义该资源的一些参数，比如 `Key` 与 `ValueName`。虽然该任务中的选项不区分大小写，但建议保持大小写不变，因为这样更容易将 DSC 的资源选项，与 Ansible 的 `win_dsc` 选项区分开来。


以下是上述 DSC `Registry` 资源的 Ansible 任务版本，可能的样子：

```yaml
    - name: Use win_dsc module with the Registry DSC resource
      win_dsc:
        resource_name: Registry
        Ensure: Present
        Key: HKEY_LOCAL_MACHINE\SOFTWARE\ExampleKey
        ValueName: TestValue
        ValueData: TestData
```


> **译注**：在针对 Windows 10 IoT Enterprise LTSC 21H2 19044.5487，执行包含该任务的 playbook，`ansible-playbook -i playbook_executing/inventory.yml playbook_executing/dsc_demo.yml` 时，报出了错误：`System.Management.Automation.ItemNotFoundException: Cannot find path 'WSMan:\localhost\Client\DefaultPorts\HTTP' because it does not exist.`。
>
> 在询问 Deepseek 后，发现需要开启 WinRM 服务。

```powershell
Enable-PSRemoting -Force
New-PSDrive -Name WSMan -PSProvider WSMan -Root "\" -ErrorAction SilentlyContinue
New-Item -Path "WSMan:\localhost\Client\DefaultPorts\HTTP" -Force
```

> 检查 WinRM 服务状态：

```powershell
Get-Service WinRM  # 确保状态为 "Running"‌:ml-citation{ref="1,4" data="citationList"}
```

> 防火墙放行 WinRM：

```powershell
Enable-NetFirewallRule -Name "WINRM-HTTP-In-TCP"
```

> 快速设置 `WSMan`：

```powershell
Set-WSManQuickConfig
```

> 随后上述报错消失，但出现新的报错：`Microsoft.Management.Infrastructure.CimException: Not found`。随后运行 `[System.Reflection.Assembly]::LoadFrom("Microsoft.Management.Infrastructure.dll")`，报出 `"Could not load file or assembly 'file:///C:\Windows\system32\Microsoft.Management.Infrastructure.dll' or one of its dependencies. The system cannot find the file specified."` 错误。
>
> ~~故疑似目标 Windows 10 IoT Enterprise LTSC 缺少 DSC/WinRM 的完整支持，后续下载安装 Windows server 2019 再进行测试~~。
>
> 后面进一步分析此问题，发现 Windows IoT Enterprise LTSC 上的 PowerShell 版本为 5.1 （查看 PowerShell 版本：`$PSVersionTable.PSVersion`），DSC 版本为 1.1。更高版本的 DSC 2.0.7 无法运行在 PowerShell 5.1 上。为此，尝试升级到 PowerShell 7.5.0，并运行命令 `Install-Module -Name PSDesiredStateConfiguration -Repository PSGallery -MaximumVersion 2.99` 安装 DSC2。
>
> 但是，尽管安装了 PowerShell 7.5.0 与 DSC 2.0.7，却无法通过 `Import-Module PSDesiredStateConfiguration` 在 Powershell 5.1 中加载。而 Powershell 5.1 是 Windows 10 系统的一部分，而无法将 Windows 10 的默认 PowerShell 切换到 7.5.0 版本。
>
> ~~因此，必需在 PowerShell 5.1 与 DSC 1.1 的基础上，解决此问题~~。
>
> 最后在将目标机器从 Windows 10 IoT Enterprise LTSC 变更为 Server 2019 后，上面的 playbook 顺利运行。
>
> **更新**：在原来无法运行 `win_dsc` 模组的 Windows 10 IoT Enterprise LTSC 主机上，运行了 [Windows 性能](performance.md#优化-powershell-性能减少-ansible-任务开销) 小节中的 PowerShell 脚本后，就可以执行该模组了！这说明该脚本不仅优化了 PowerShell 性能，还修复了原来的问题。
>
>
> 参考:
>
> - [System.Management.Automation dll throws ItemNotFoundException on Appx calls](https://stackoverflow.com/a/32139520/12288760)
>
> - [Troubleshooting DSC](https://learn.microsoft.com/en-us/powershell/dsc/troubleshooting/troubleshooting?view=dsc-1.1)
>
> - [Change default powershell version in windows 10](https://superuser.com/a/1435501)
>
> - [PSDesiredStateConfiguration v1.1](https://learn.microsoft.com/en-us/powershell/dsc/overview?view=dsc-1.1)


从 Ansible 2.8 开始，`win_dsc` 模组会自动以 DSC 定义，验证来自 Ansible 的输入选项。这意味着在选项名字不正确、某个强制选项未设置或值不是个有效选择时，Ansible 就会失败。在以输出信息级别 3 或更高 (`-vvv`) 运行 Ansible 时，返回值就将包含根据所指定的 `resource_name`，而可能的那些调用选项。下面是以上 `Registry` 任务的调用输出示例：


```json
{{#include ../../../../playbook_executing/dsc_demo_registry_output.json}}
```

其中的 `invocation.module_args` 键，就显示了那些已设置的具体值，及未设置的其他可能值。遗憾的是，这不会显示某个 DSC 属性的默认值，而只有该 Ansible 任务中设置的值。出于安全考虑，任何 `*_password` 选项，都将在输出中屏蔽；若有任何别的敏感模组选项，请在该任务上设置 `no_log： true`，以停止记录所有任务输出。


### 属性类型

每个 DSC 资源属性，都有种与之关联的类型。在执行过程中，Ansible 会尝试将所定义的选项，转换为正确的类型。对于像是 `[string]` 和 `[bool]` 等简单类型，这属于一个简单的操作，但像是 `[PSCredential]` 或数组（比如 `[string[]]` ）等复杂类型，则需要一定的规则。

- **`PSCredential`**

某个 `[PSCredential]` 对象，用于以安全方式存储凭证，但 Ansible 没有通过 JSON 将其序列化的办法。要设置某个 DSC 的 `PSCredential` 属性，该参数的定义，应包含用于表示用户名和密码的，后缀分别为 `_username` 和 `_password` 的条目。例如：

```yaml
PsDscRunAsCredential_username: '{{ ansible_user }}'
PsDscRunAsCredential_password: '{{ ansible_password }}'

SourceCredential_username: AdminUser
SourceCredential_password: PasswordForAdminUser
```

> **注意**：在 2.8 以上版本的 Ansible 中，咱们应在 Ansible 种的任务定义上，设置 `no_log：true`，以确保用到的全部凭证，不会存储在任何日志文件或控制台输出中。


`[PSCredential]` 属性，是以 `EmbeddedInstance(“MSFT_Credential”)`，并以某项 DSC 资源的 MOF 定义格式定义的。

> **译注**：'a DSC resource MOF definition'，其中 'MOF' 指的是 Managed Object Format，托管对象格式。
>
> 参考：
>
> - [Desired State Configuration: MOF Files](https://jesspomfret.com/dsc-mof-files/)


- **`CimInstance`** 类型


DSC 使用 `[CimInstance]` 对象，存储基于该资源所定义的自定义类的字典对象。在 YAML 中定义某个取 `[CimInstance]` 类型的值，与在 YAML 中定义某个字典相同。例如，要在 Ansible 中定义一个 `[CimInstance]` 的值：


```yaml
# [CimInstance]AuthenticationInfo == DSC_WebAuthenticationInformation
AuthenticationInfo:
  Anonymous: false
  Basic: true
  Digest: false
  Windows: true
```

在上面的示例中，其中的 CIM 实例便是类 `DSC_WebAuthenticationInformation` 的表示。这个类接受四个布尔值变量：`Anonymous`、`Basic`、`Digest` 与 `Windows`。在某个 `[CimInstance]` 的值中使用的键，取决于其所表示的类。请阅读资源的文档，确定出可使用的键及各个键值的类型。类的定义通常位于 `<resource name>.schema.mof` 这个文件中。


- **`HashTable` 类型**

`[HashTable]` 对象也是个字典，不过他并无一组严格的键值可以/需要定义。与 `[CimInstance]` 一样，在 YAML 中将其定义为一般字典值即可。`[HashTable]]` 是以 `EmbeddedInstance(“MSFT_KeyValuePair”)`，以某项 DSC 资源的 MOF 定义格式定义的。


- **数组**


像 `[string[]]` 或 `[UInt32[]]` 这样的简单类型数组，会被定义为列表或逗号分隔的字符串，然后再将其转换为他们的类型。建议使用列表，因为在将值传递给 DSC 引擎前，这些值不会被 `win_dsc` 模组手动解析（？）。例如，要在 Ansible 中定义某个简单类型的数组：

```yaml
# [string[]]
ValueData: entry1, entry2, entry3
ValueData:
- entry1
- entry2
- entry3

# [UInt32[]]
ReturnCode: 0,3010
ReturnCode:
- 0
- 3010
```

像 `[CimInstance[]]`（字典数组）这样的复杂类型数组，可以像下面这个示例这样定义：


```yaml
# [CimInstance[]]BindingInfo == DSC_WebBindingInformation
BindingInfo:
- Protocol: https
  Port: 443
  CertificateStoreName: My
  CertificateThumbprint: C676A89018C4D5902353545343634F35E6B3A659
  HostName: DSCTest
  IPAddress: '*'
  SSLFlags: 1
- Protocol: http
  Port: 80
  IPAddress: '*'
```

上面的示例是个带有两个 [`DSC_WebBindingInformation`](https://github.com/dsccommunity/WebAdministrationDsc/blob/main/source/DSCResources/DSC_WebSite/DSC_WebSite.schema.mof) 类值的数组。在定义某个 `[CimInstance[]]` 时，请务必阅读资源文档，了解在定义中要使用哪些键。


- **`DateTime`**


`[DateTime]` 对象是个以 ISO 8601 日期时间格式，表示日期和时间的 `DateTime` 字符串。某 `[DateTime]` 字段的值应在 YAML 中以单引号括起来，以确保该字符串能恰当地序列化到 Windows 主机。下面是个如何在 Ansible 中，定义 `[DateTime]` 值的示例：


```yaml
# As UTC-0 (No timezone)
DateTime: '2019-02-22T13:57:31.2311892+00:00'

# As UTC+4
DateTime: '2019-02-22T17:57:31.2311892+04:00'

# As UTC-4
DateTime: '2019-02-22T09:57:31.2311892-04:00'
```


上面的所有值，都等于 UTC 日期时间 2019 年 2 月 22 日下午 1:57 的 31 秒 2311892 毫秒。


### 以另一用户运行


默认情况下，DSC 会以 `SYSTEM` 账户，而非 Ansible 用以运行该模组的账户，运行各项资源。这意味着这些资源会根据用户配置文件，被动态地加载，比如 `HKEY_CURRENT_USER` 这个注册表项目，就将在 `SYSTEM` 的配置文件下加载。参数 `PsDscRunAsCredential` 是个可对每项 DSC 资源设置，并强制 DSC 引擎在别的账户下运行的参赛。由于 `PsDscRunAsCredential` 的类型为 `PSCredential`，因此要以 `_username` 和 `_password` 后缀定义。


以 `Registry` 资源类型为例，以下便是定义一个访问 Ansible 用户的 `HKEY_CURRENT_USER` 项目的方式：

```yaml
    - name: Use win_dsc with PsDscRunAsCredential to run as a different user
      win_dsc:
        resource_name: Registry
        Ensure: Present
        Key: HKEY_CURRENT_USER\ExampleKey
        ValueName: TestValue
        ValueData: TestData
        PsDscRunAsCredential_username: '{{ ansible_user }}'
        PsDscRunAsCredential_password: '{{ ansible_password }}'
      no_log: true
```


## 定制 DSC 资源

DSC 资源并不仅限于微软的那些内置选项。可以安装一些定制模组，来管理通常不可用的其他资源。


### 查找定制 DSC 资源


咱们可使用 [`PSGallery`](https://www.powershellgallery.com/)，查找定制资源，以及如何在 Windows 主机上安装这些资源的文档。


`Find-DscResource` 这个cmdlet 也可用于查找定制资源。例如：


```powershell
# Find all DSC resources in the configured repositories
Find-DscResource

# Find all DSC resources that relate to SQL
Find-DscResource -ModuleName "*sql*"
```


> **注意**：由 Microsoft 开发的以 `x` 开头的 DSC 资源，表示该资源是试验性的，不提供任何支持。


### 安装某个定制资源


可以三种方式，将某个 DSC 资源安装在主机上：

- 手动使用 `Install-Module` 这个 cmdlet；
- 使用 `win_psmodule` 这个 Ansible 模组；
- 手动保存该模组，并将其拷贝到另一主机上。


以下是个使用 `win_psmodule` 安装 `xWebAdministration` 资源的示例：


```yaml
    - name: Install xWebAdministration DSC resource
      win_psmodule:
        name: xWebAdministration
        state: present
```

一旦某项资源安装后，`win_dsc` 模组就可以 `resource_name` 选项，引用该资源。


上面的前两种方法，只有在主机可以访问互联网时才会工作。当主机没有访问互联网时，就必须先在一台有访问互接入的主机上，使用上述方式安装模组，然后将该模组复制到另一主机上。要将某个模组保存到本地文件路径，可运行以下 PowerShell cmdlet：


```powershell
Save-Module -Name xWebAdministration -Path C:\temp
```


这将在 `C:\temp` 中创建一个名为 `xWebAdministration` 的文件夹，其可被复制到任何主机上。要让 PowerShell 看到此离线资源，必须将其复制到设置在 `PSModulePath` 环境变量中的目录。在大多数情况下，通过该变量设置的是 `C:\Program Files\WindowsPowerShell\Module`，但可使用 `win_path` 添加别的路径。


## 示例


### 提取某个 zip 文件


```yaml
    - name: Extract a zip file
      win_dsc:
        resource_name: Archive
        Destination: C:\temp\output
        Path: C:\temp\zip.zip
        Ensure: Present
```

### 创建目录


```yaml
    - name: Create file with some text
      win_dsc:
        resource_name: File
        DestinationPath: C:\temp\file
        Contents: |
            Hello
            World
        Ensure: Present
        Type: File

    - name: Create directory that is hidden is set with the System attribute
      win_dsc:
        resource_name: File
        DestinationPath: C:\temp\hidden-directory
        Attributes: Hidden,System
        Ensure: Present
        Type: Directory
```


### 与 Azure 交互


```yaml
- name: Install xAzure DSC resources
  win_psmodule:
    name: xAzure
    state: present

- name: Create virtual machine in Azure
  win_dsc:
    resource_name: xAzureVM
    ImageName: a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201409.01-en.us-127GB.vhd
    Name: DSCHOST01
    ServiceName: ServiceName
    StorageAccountName: StorageAccountName
    InstanceSize: Medium
    Windows: true
    Ensure: Present
    Credential_username: '{{ ansible_user }}'
    Credential_password: '{{ ansible_password }}'
```


### 设置 IIS Web 站点


```yaml
- name: Install xWebAdministration module
  win_psmodule:
    name: xWebAdministration
    state: present

- name: Install IIS features that are required
  win_dsc:
    resource_name: WindowsFeature
    Name: '{{ item }}'
    Ensure: Present
  loop:
  - Web-Server
  - Web-Asp-Net45

- name: Setup web content
  win_dsc:
    resource_name: File
    DestinationPath: C:\inetpub\IISSite\index.html
    Type: File
    Contents: |
      <html>
      <head><title>IIS Site</title></head>
      <body>This is the body</body>
      </html>
    Ensure: present

- name: Create new website
  win_dsc:
    resource_name: xWebsite
    Name: NewIISSite
    State: Started
    PhysicalPath: C:\inetpub\IISSite\index.html
    BindingInfo:
    - Protocol: https
      Port: 8443
      CertificateStoreName: My
      CertificateThumbprint: C676A89018C4D5902353545343634F35E6B3A659
      HostName: DSCTest
      IPAddress: '*'
      SSLFlags: 1
    - Protocol: http
      Port: 8080
      IPAddress: '*'
    AuthenticationInfo:
      Anonymous: false
      Basic: true
      Digest: false
      Windows: true
```

（End）


