![](https://img.shields.io/github/license/HeidiSQL/HeidiSQL.svg?style=flat)
![](https://img.shields.io/github/release/meta222888/HeidiSQL.svg?style=flat)
![](https://img.shields.io/github/languages/top/HeidiSQL/HeidiSQL.svg?style=flat)

# HeidiSQL

HeidiSQL 是一款图形化数据库管理工具，支持 [MariaDB](http://www.mariadb.org/)、[MySQL](http://www.mysql.com/)、[Microsoft SQL Server](http://www.microsoft.com/sql/)、[PostgreSQL](http://www.postgresql.org/)、[SQLite](https://www.sqlite.org/)、[Interbase](https://www.embarcadero.com/de/products/interbase) 和 [Firebird](https://firebirdsql.org/)。你可以浏览和编辑数据、管理表/视图/存储过程/触发器/计划事件，并将结构或数据导出到 SQL 文件、剪贴板或其他服务器。

本仓库为 [meta222888/HeidiSQL](https://github.com/meta222888/HeidiSQL) fork，在官方 **12.18** 基础上针对 **SQL Server** 与 **中文环境** 做了修复与改进。

## 下载

预编译便携版见 [GitHub Releases](https://github.com/meta222888/HeidiSQL/releases)。解压后运行 `heidisql.exe` 即可（无需安装）。

## 本 Fork 的改动

### 修复 MSSQL 查询结果中文乱码

通过 ADO 连接 SQL Server 时，在以下场景中文会显示为乱码：

- Windows 开启了 **「Beta: 使用 Unicode UTF-8 提供全球语言支持」**（系统代码页 65001）
- 数据库 `VARCHAR` / `TEXT` 列使用 **GBK（CP936）** 等 DBCS 编码

**修复内容：**

- 从底层 ADO Recordset 按 `OleVariant` 类型正确解码窄字符与宽字符字段
- 对 `varString` 优先尝试 UTF-8，再回退到 locale ANSI 代码页（中文系统一般为 936）
- 对 ADO 误将 GBK 按 UTF-8 转成 BSTR 的 `varOleStr`，在 UTF-8 系统区域下反向还原字节再解码
- 连接串增加 `Auto Translate=False`，减少 OLE DB 自动转码干扰
- 正确映射 `NVARCHAR` / `VARCHAR` 等字段类型

### 修复 MSSQL (TCP/IP) 连接失败

使用默认驱动 **MSOLEDBSQL** 时，连接字符串中的 `Network Library=DBMSSOCN` 会导致 OLE 报错：「参数类型不正确，或不在可以接受的范围之内，或与其他参数冲突」。

**修复方式：** MSOLEDBSQL 不再附加 `Network Library` 参数；旧版 SQLOLEDB 仍保留原有写法。

### SQL Server (TCP/IP) 默认端口 1433

新建或切换到 **Microsoft SQL Server (TCP/IP)** 会话时，端口字段默认填入 **1433**。

### 左侧数据库树分组

展开数据库时：

- **表** 直接挂在数据库节点下（一级）
- **视图、存储过程、函数、触发器、事件** 归入可展开的子文件夹

默认开启 `GroupTreeObjects`。

### 集成官方中文语言包

内置官方 **35 种语言**翻译文件（含 `zh`、`zh_CN`、`zh_TW`）。偏好设置中 **Application language** 选「自动检测」时，中文 Windows 会自动显示中文界面；也可手动选择 `zh_CN: Chinese (China)`。

### Windows 源码编译脚本

提供 `scripts/setup-dev.ps1`、`scripts/build.ps1`，支持自定义 Delphi 路径（如 `D:\tools\Delphi 12.3`），使用 `dcc64` 直接编译，无需 MSBuild。

## 需要帮助？

- 网站：[pc530.com](https://pc530.com/)
- 讨论区：[pc530.com/forum](https://pc530.com/forum/)
- 缺陷反馈：[GitHub Issues](https://github.com/meta222888/HeidiSQL/issues)

## 开发环境（快速开始）

```powershell
# 1. 检测工具链、同步运行期 DLL 与语言包
.\scripts\setup-dev.ps1

# 2. 编译（需 Delphi 12.3 + madCollection）
.\scripts\build.ps1

# 3. 运行
.\out\heidisql.exe
```

### 必需工具

| 工具 | 说明 |
|------|------|
| **RAD Studio 12.3** (Delphi) | 默认 `D:\tools\Delphi 12.3` 或 `C:\Program Files (x86)\Embarcadero\Studio\23.0\` |
| **madCollection** | 可选；未安装 Delphi 包时使用内置 stub 编译 |
| **运行期 DLL** | 由 `setup-dev.ps1` 从官方便携版目录同步到 `out\` |

语言包缺失时，`setup-dev.ps1` 会自动执行 `scripts\sync-locale.ps1` 从官方 HeidiSQL v12.18 拉取翻译文件。

## 翻译贡献

界面翻译仍由官方 [Transifex](https://explore.transifex.com/heidisql/heidisql/) 维护；本 fork 通过 `sync-locale.ps1` 同步官方已编译的 `.mo` 文件。

## 许可证

基于官方 HeidiSQL，遵循 **GPL v2**。详见仓库根目录 `LICENSE` 与 `gpl.txt`。
