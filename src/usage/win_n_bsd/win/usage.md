# 使用 Ansible 与 Windows


在使用 Ansible 管理 Windows 时，许多适用于 Unix/Linux 主机的语法和规则，也适用于 Windows，但在路径分隔符与一些特定于操作系统的任务等组件方面，仍存在一些差异。此文档介绍了在 Windows 中使用 Ansible 的一些具体细节。



## 用例

Ansible 可用于编排 Windows 服务器上的大量任务。以下是一些常见任务的示例与信息。


### 安装软件

使用 Ansible 安装软件有三种主要方式：

- 使用 `win_chocolatey` 模组。该模组从默认的公共 [Chocolatey](https://chocolatey.org/) 软件库，获取程序数据。通过设置该模组的 `source` 选项，也可以使用咱们内部的软件库；
- 使用 `win_package` 模组。该模组使用某个本地/网络路径，或 URL 的 MSI 或 `.exe` 的安装程序安装软件；
- 使用 `win_command` 或 `win_shell` 模组，手动运行安装程序。


推荐使用 `win_chocolatey` 模组，因为他具有检查某个软件包是否已安装，以及是否为最新的最完整逻辑。


下面是使用所有三中选项，安装 7-Zip 的一些示例：


```yaml
# Install/uninstall with chocolatey
- name: Ensure 7-Zip is installed through Chocolatey
  win_chocolatey:
    name: 7zip
    state: present

- name: Ensure 7-Zip is not installed through Chocolatey
  win_chocolatey:
    name: 7zip
    state: absent

# Install/uninstall with win_package
- name: Download the 7-Zip package
  win_get_url:
    url: https://www.7-zip.org/a/7z1701-x64.msi
    dest: C:\temp\7z.msi

- name: Ensure 7-Zip is installed through win_package
  win_package:
    path: C:\temp\7z.msi
    state: present

- name: Ensure 7-Zip is not installed through win_package
  win_package:
    path: C:\temp\7z.msi
    state: absent

# Install/uninstall with win_command
- name: Download the 7-Zip package
  win_get_url:
    url: https://www.7-zip.org/a/7z1701-x64.msi
    dest: C:\temp\7z.msi

- name: Check if 7-Zip is already installed
  win_reg_stat:
    name: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{23170F69-40C1-2702-1701-000001000000}
  register: 7zip_installed

- name: Ensure 7-Zip is installed through win_command
  win_command: C:\Windows\System32\msiexec.exe /i C:\temp\7z.msi /qn /norestart
  when: 7zip_installed.exists == false

- name: Ensure 7-Zip is uninstalled through win_command
  win_command: C:\Windows\System32\msiexec.exe /x {23170F69-40C1-2702-1701-000001000000} /qn /norestart
  when: 7zip_installed.exists == true
```

诸如 Microsoft Office 或 SQL Server 等的一些安装程序，需要证书委派或对受 WinRM 限制组件的访问。绕过这些问题的最佳方法，是在任务中使用 `become`。有了 `become`，Ansible 将像其在主机上交互运行一样，运行安装程序。


> **注意**：许多安装程序都无法透过 WinRM，正确地传递错误信息。在这种情况下，若已验证过安装过程可在本地运行，那么建议做法是使用 `become`。

> **注意**：有的安装程序会重启 WinRM 或 HTTP 服务，或导致他们暂时不可用，从而使 Ansible 认为系统不可达。


### 安装更新


`win_updates` 和 `win_hotfix` 两个模组，可用于在主机上安装更新或热修复程序，updates or hotfixes。`win_updates` 模组用于依类别安装多个更新，而 `win_hotfix` 可用于安装已下载到本地的单个更新，或热修复文件。


> **注意**：`win_hotfix` 模组需要系统上已有 DISM 的 PowerShell cmdlets。这些 cmdlets 仅在 Windows Server 2012 及更新版本中才会默认加入，在较旧的 Windows 主机上必须另外安装。


下面这个示例展示了如何使用 `win_updates`：


```yaml
    - name: Install all critical and security updates
      win_updates:
        category_names:
        - CriticalUpdates
        - SecurityUpdates
        state: installed
      register: update_result

    - name: Reboot host if required
      win_reboot:
      when: update_result.reboot_required
```


下面这个示例展示了如何使用 `win_hotfix`，安装单个更新或热修补程序：


```yaml
- name: Download KB3172729 for Server 2012 R2
  win_get_url:
    url: http://download.windowsupdate.com/d/msdownload/update/software/secu/2016/07/windows8.1-kb3172729-x64_e8003822a7ef4705cbb65623b72fd3cec73fe222.msu
    dest: C:\temp\KB3172729.msu

- name: Install hotfix
  win_hotfix:
    hotfix_kb: KB3172729
    source: C:\temp\KB3172729.msu
    state: present
  register: hotfix_result

- name: Reboot host if required
  win_reboot:
  when: hotfix_result.reboot_required
```


### 设置用户和组


Ansible 可同时用于创建 Windows 的本地和域中的用户和组。

- **本地** 用户与组


`win_user`、`win_group` 和 `win_group_membership` 三个模组，可管理 Windows 的本地用户、组和组成员身份。


下面是创建可访问同一主机上某个文件夹的本地账户和组的示例：


```yaml
    - name: Create local group to contain new users
      win_group:
        name: LocalGroup
        description: Allow access to C:\Development folder

    - name: Create local user
      win_user:
        name: '{{ item.name }}'
        password: '{{ item.password }}'
        groups: LocalGroup
        update_password: always
        password_never_expires: true
      loop:
      - name: User1
        password: Password1
      - name: User2
        password: Password2

    - name: Create Development folder
      win_file:
        path: C:\Development
        state: directory

    - name: Set ACL of Development folder
      win_acl:
        path: C:\Development
        rights: FullControl
        state: present
        type: allow
        user: LocalGroup

    - name: Remove parent inheritance of Development folder
      win_acl_inheritance:
        path: C:\Development
        reorganize: true
        state: absent
```


- **域** 用户和组


`win_domain_user` 和 `win_domain_group` 两个模组管理域中的用户和组。下面是确保创建出一批域用户的示例：


```yaml
- name: Ensure each account is created
  win_domain_user:
    name: '{{ item.name }}'
    upn: '{{ item.name }}@MY.DOMAIN.COM'
    password: '{{ item.password }}'
    password_never_expires: false
    groups:
    - Test User
    - Application
    company: Ansible
    update_password: on_create
  loop:
  - name: Test User
    password: Password
  - name: Admin User
    password: SuperSecretPass01
  - name: Dev User
    password: '@fvr3IbFBujSRh!3hBg%wgFucD8^x8W5'
```


### 运行命令


如果任务没有合适的模组，则可使用 `win_shell`、`win_command`、`raw` 和 `script` 模组，运行某个命令或脚本。


`raw` 模组仅远程执行某个 Powershell 命令。由于 `raw` 没有 Ansible 通常会用到的封装器，因此 `become`、`async` 和环境变量等就无法工作。

`script` 模组在一或多台 Windows 主机上，执行来自 Ansible 控制节点的某个脚本。与 `raw` 一样，`script` 当前不支持 `become`、`async` 或环境变量等。

`win_command` 模组用于执行某个可执行文件或批处理文件，而 `win_shell` 模组则用于在 shell 中执行命令。


- **选择命令或 shell**

`win_shell` 和 `win_command` 模组二者均可用来执行一条或多条命令。`win_shell` 模组运行于类似于 `PowerShell` 或 `cmd` 的 shell 进程中，因此他可以访问 `<`、`>`、`|`、`;`、`&&` 及 `||` 等 shell 操作符。多行命令也可以在 `win_shell` 中运行。


`win_command` 模组只是在 shell 之外运行一个进程。通过将 shell 命令传递给 `cmd.exe` 或 `PowerShell.exe` 等某个 shell 可执行文件，他仍可以运行 `mkdir` 或 `New-Item` 等 shell 命令。


以下是一些使用 `win_command` 和 `win_shell` 的示例：


```yaml
    - name: Run a command under PowerShell
      win_shell: Get-Service -Name Spooler | Stop-Service

    - name: Run a command under cmd
      win_shell: mkdir C:\temp1
      args:
        executable: cmd.exe

    - name: Run a multiple shell commands
      win_shell: |
        New-Item -Path C:\temp1 -ItemType Directory
        Remove-Item -Path C:\temp1 -Force -Recurse
        $path_info = Get-Item -Path C:\temp1
        $path_info.FullName

    - name: Run an executable using win_command
      win_command: whoami.exe

    - name: Run a cmd command
      win_command: cmd.exe /c mkdir C:\temp1

    - name: Run a vbs script
      win_command: cscript.exe script.vbs
```


> **注意**：一些像是 `mkdir`、`del` 和 `copy` 的命令，只存在于 CMD 的 shell 中。因此要使用 `win_command` 运行这些命令，他们必需冠以 `cmd.exe /c` 作为前缀。


- **参数规则**


在经由 `win_command` 运行某个命令时，适用标准的 Windows 参数规则：


- 各个参数以空白分隔，空白即可是个空格，也可以是制表符；
- 参数可以用双引号 `”` 括起来. 两个双引号内的内容会被解释为一个参数，即使包含空白；
- 前面有反斜线 `\` 的双引号，会被解释为一个双引号 `"`，而不是参数分隔符；
- 反斜线会按字面解释，除非他紧接在双引号前；比如 `\ == \` 与 `\" == ”`；
- 若偶数个反斜线后跟了个双引号，则参数中会使用每对反斜线中的一个，同时后跟的双引号，会用作该参数的字符串分隔符；
- 若奇数个反斜线后跟了个双引号，则参数中会使用每对反斜线中的一个，同时后跟的双引号会被转义，而成为该参数中的一个字面的双引号；


记住了这些规则后，下面是一些引号的示例：


```yaml
- win_command: C:\temp\executable.exe argument1 "argument 2" "C:\path\with space" "double \"quoted\""

argv[0] = C:\temp\executable.exe
argv[1] = argument1
argv[2] = argument 2
argv[3] = C:\path\with space
argv[4] = double "quoted"

- win_command: '"C:\Program Files\Program\program.exe" "escaped \\\" backslash" unquoted-end-backslash\'

argv[0] = C:\Program Files\Program\program.exe
argv[1] = escaped \" backslash
argv[2] = unquoted-end-backslash\

# Due to YAML and Ansible parsing '\"' must be written as '{% raw %}\\{% endraw %}"'
- win_command: C:\temp\executable.exe C:\no\space\path "arg with end \ before end quote{% raw %}\\{% endraw %}"

argv[0] = C:\temp\executable.exe
argv[1] = C:\no\space\path
argv[2] = arg with end \ before end quote\"
```

更多信息，请参阅 <a href="https://msdn.microsoft.com/en-us/library/17w5ykft(v=vs.85).aspx" target="_blank" >转义参数</a>。


### 创建和运行计划任务

**Creating and Running a Scheduled Task**


WinRM 有一些在运行某些命令时，会导致错误的局限。绕过这些限制的一种方法，是通过计划任务运行某个命令。计划任务是个提供了在不同账户下，按计划运行可执行文件能力的 Windows 组件。


Ansible 2.5 版本添加了一些令到在 Windows 中，使用计划任务变得更容易的模组。以下是将某个脚本作为计划任务运行，并在运行后自行删除的示例：


```yaml
    - name: Create scheduled task to run a process
      win_scheduled_task:
        name: adhoc-task
        username: SYSTEM
        actions:
        - path: PowerShell.exe
          arguments: |
            Start-Sleep -Seconds 30  # This isn't required, just here as a demonstration
            New-Item -Path C:\temp\test -ItemType Directory
        # Remove this action if the task shouldn't be deleted on completion
        - path: cmd.exe
          arguments: /c schtasks.exe /Delete /TN "adhoc-task" /F
        triggers:
        - type: registration

    - name: Wait for the scheduled task to complete
      win_scheduled_task_stat:
        name: adhoc-task
      register: task_stat
      until: (task_stat.state is defined and task_stat.state.status != "TASK_STATE_RUNNING") or (task_stat.task_exists == False)
      retries: 12
      delay: 10
```

> **注意**：上面示例中用到的那些模组，是在 Ansible 2.5 版本中更新/添加的。


## Windows 中的路径格式化

**Path Formatting for Windows**


与传统的 POSIX 操作系统相比，Windows 在许多方面都由所不同。其中一个主要变化，是路径分隔符从 `/` 改为了 `\`。由于在 POSIX 系统中 `\` 经常被用作转义字符，这可能会对 playbook 的编写方式，造成很大的影响。


Ansible 允许两种不同样式的语法；每种语法处理 Windows 路径分隔符的方式也不同：


### YAML 样式

在任务中使用 YAML 语法时，YAML 标准明确规定了这些规则：

- 在使用普通字符串（不带引号）时，YAML 不会将反斜杠视为转义字符；
- 在使用单引号 `'` 时，YAML 不会将反斜杠视为转义字符；
- 在使用双引号 `"` 时，反斜杠会被视为转义字符，而需要用另一反斜杠转义。


> **注意**：咱们只应在绝对有必要，或 YAML 要求时，才使用单引号把字符串括起来。


YAML 规范会考虑以下 [转义序列](https://yaml.org/spec/current.html#id2517668)：

- `\0`、`\\`、`\”`、`\_`、`\a`、`\b`、`\e`、`\f`、`\n`、`\r`、`\t`、`\v`、`\L`、`\N` 及 `\P` - 这些单个字符的转义；
- `<TAB>`、`<SPACE>`、`<NBSP>`、`<LNSP>` 及 `<PSP>` - 这些特殊字符；
- `\x..` - 2 位的十六进制转义字符；
- `\u....` - 4 位的十六进制转义字符；
- `\u........` - 8 位的十六进制转义字符。


下面是一些如何编写 Windows 路径的示例：


```yaml
# GOOD
tempdir: C:\Windows\Temp

# WORKS
tempdir: 'C:\Windows\Temp'
tempdir: "C:\\Windows\\Temp"

# BAD, BUT SOMETIMES WORKS
tempdir: C:\\Windows\\Temp
tempdir: 'C:\\Windows\\Temp'
tempdir: C:/Windows/Temp
```

下面是个将失败的示例：


```yaml
# FAILS
tempdir: "C:\Windows\Temp"
```

下面这个示例显示了，在要求使用时单引号的用法：


```yaml
---
- name: Copy tomcat config
  win_copy:
    src: log4j.xml
    dest: '{{tc_home}}\lib\log4j.xml'
```


### 旧有的 `key=value` 样式


旧有的 `key=value` 语法，用于命令行中的临时命令，或 playbook 内部。由于反斜杠字符需要被转义，而这会增加 playbook 的阅读难度，因此不鼓励在 playbook 本中使用这种样式。这种旧有语法取决于 Ansible 的特定实现，用引号括起来（不管单引号还是双引号），对其被 Ansible 解析的方式没有任何影响。


Ansible 的 `key=value` 解析器 `parse_kv()`，会考虑以下转义序列：


- `\”`、`'`、`"`、`\a`、`\b`、`\f`、`\n`、`\r`、`\t` 及 `\v` - 这些单个字符的转义；
- `\x..` - 2 位的十六进制转义；
- `\u....` - 4 位的十六进制转义；
- `\u........` - 8 位的十六进制转义；
- `\N{...}` - 名义上的 Unicode 字符，Unicode character by name；


这意味着反斜杠是某些序列的转义字符，同时在这种形式下转义反斜杠通常会更安全。


下面是一些 `key=value` 样式下使用 Windows 路径的示例：


```yaml
# GOOD
tempdir=C:\\Windows\\Temp

# WORKS
tempdir='C:\\Windows\\Temp'
tempdir="C:\\Windows\\Temp"

# BAD, BUT SOMETIMES WORKS
tempdir=C:\Windows\Temp
tempdir='C:\Windows\Temp'
tempdir="C:\Windows\Temp"
tempdir=C:/Windows/Temp

# FAILS
tempdir=C:\Windows\temp
tempdir='C:\Windows\temp'
tempdir="C:\Windows\temp"
```


失败的那些示例并不会彻底失败，但会用 `<TAB>` 字符代替 `\t`，而导致 `tempdir` 变成了 `C:\Windows<TAB>emp`。


## 局限

咱们无法用 Ansible 和 Windows 做到的一些事情：

- 升级 PowerShell；
- 与 WinRM 监听器互动，interact with the WinRM listeners。


由于 WinRM 依赖那些于正常操作期间，在线并运行着的服务，因此咱们无法升级 PowerShell，或在 Ansible 下与 WinRM 的监听器交互。这两种操作都将导致连接失败。从技术上讲，这可通过使用 `async` 或计划任务来避免，但如果其所运行的进程，破坏了 Ansible 用到的底层连接，这些方法就会很脆弱，因此这两种操作最好留在引导进程或创建映像之前。


## 开发 Windows 模组

由于 Ansible 的 Windows 模组是以 PowerShell 编写的，因此 Windows 模组的开发指南，与标准模组的开发指南有很大不同。更多信息，请参阅 [Windows 模组开发指南](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general_windows.html#developing-modules-general-windows)。


（End）


