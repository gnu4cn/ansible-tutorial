# Meraki 平台选项

[`cisco.meraki`](https://galaxy.ansible.com/ui/repo/published/cisco/meraki) 专辑目前只支持 `local` 的连接类型。

> **译注**：Cisco Meraki 是一家云管理 IT 公司，总部位于加利福尼亚州旧金山。其产品包括无线、交换、安全、企业移动管理，enterprise mobility management, EMM，及安全摄像头，所有产品均可通过网络集中管理。Meraki 于 2012 年 12 月被思科系统公司收购，成为其的一家子公司。
>
>
> 参考:
>
> - [Cisco Meraki](https://en.wikipedia.org/wiki/Cisco_Meraki)

## 可用连接


|  | 仪表板 Dashboard API |
| 协议 | HTTPS |
| 凭据 | 使用仪表板中的 API 密钥 |
| 连接设置 | `ansible_connection: local` |
| 返回数据格式 | `data.` |


## 示例 Meraki 任务

```yaml
cisco.meraki.meraki_organization:
  auth_key: abc12345
  org_name: YourOrg
  state: present
delegate_to: localhost
```

（End）


