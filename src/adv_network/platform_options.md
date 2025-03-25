# 平台选项

有的 Ansible 网络平台支持多种连接类型、权限提升（`enable` 模式）或其他选项。本节中的页面提供了理解每种网络平台上可用选项的一些标准化指南。我们（作者）欢迎社区维护的平台，为本节提供内容。



## 依平台的设置


<table>
<tr><th colspan="2"></th><th colspan="4"><code>ansible_connection: </code>可用设置</th></tr>
<tr>
    <td>Network 操作系统</td>
    <td><code>ansible_network_os: </code></td>
    <td><code>network_cli</code></td>
    <td><code>netconf</code></td>
    <td><code>httpapi</code></td>
    <td><code>local</code></td>
</tr>
| [Arista EOS](./platform_options/eos.md) | `arista.eos.eos` | ✓ |  | ✓ | ✓ |
</table>
