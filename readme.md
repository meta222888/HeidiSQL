![](https://img.shields.io/github/license/HeidiSQL/HeidiSQL.svg?style=flat)
![](https://img.shields.io/github/release/HeidiSQL/HeidiSQL.svg?style=flat)
![](https://img.shields.io/github/languages/top/HeidiSQL/HeidiSQL.svg?style=flat)
![](https://img.shields.io/github/languages/code-size/HeidiSQL/HeidiSQL.svg?style=flat)

# HeidiSQL

HeidiSQL 是一款图形化数据库管理工具，支持 [MariaDB](http://www.mariadb.org/)、[MySQL](http://www.mysql.com/)、[Microsoft SQL Server](http://www.microsoft.com/sql/)、[PostgreSQL](http://www.postgresql.org/)、[SQLite](https://www.sqlite.org/)、[Interbase](https://www.embarcadero.com/de/products/interbase) 和 [Firebird](https://firebirdsql.org/)。你可以浏览和编辑数据、管理表/视图/存储过程/触发器/计划事件，并将结构或数据导出到 SQL 文件、剪贴板或其他服务器。更多功能见[官网介绍](https://www.heidisql.com/#featurelist)，截图见[这里](https://www.heidisql.com/screenshots.php)。

本仓库为 [meta222888/HeidiSQL](https://github.com/meta222888/HeidiSQL) fork，在官方版本基础上包含以下针对 SQL Server 的修复与改进。

## 本 Fork 的修复

### 修复 MSSQL 查询结果中文乱码

通过 ADO 连接 SQL Server 时，原先使用 `AsString` / `AsAnsiString` 读取字段，在 Windows 开启 UTF-8 区域设置、或 `VARCHAR` 列使用 GBK 等 DBCS 编码时，中文会显示为乱码。

**修复方式：** 从底层 ADO Recordset 的 `OleVariant` 按类型解码——`varOleStr` 按 Unicode 处理，`varString` 使用系统 ANSI 代码页（如 CP936）转换；并正确区分 `NVARCHAR` / `VARCHAR` 等宽字符与窄字符字段类型。

相关提交：`820c2654`

### 修复 MSSQL (TCP/IP) 连接失败

使用默认驱动 **MSOLEDBSQL** 时，连接字符串中的 `Network Library=DBMSSOCN` 会导致 OLE 报错：「参数类型不正确，或不在可以接受的范围之内，或与其他参数冲突」。

**修复方式：** MSOLEDBSQL 不再附加 `Network Library` 参数（TCP 为默认协议）；旧版 SQLOLEDB 仍保留原有写法。

相关提交：`ae524122`

### SQL Server (TCP/IP) 默认端口 1433

新建或切换到 **Microsoft SQL Server (TCP/IP)** 会话时，端口字段默认填入 **1433**（不再默认为 0）。

## 需要帮助？

- 使用说明：[在线帮助](https://www.heidisql.com/help.php)
- 提问讨论：[官方论坛](https://www.heidisql.com/forum.php)
- 缺陷反馈：[GitHub Issues](https://github.com/HeidiSQL/HeidiSQL/issues)

## 开发环境（快速开始）

### 一键脚本

在仓库根目录用 PowerShell 执行：

```powershell
# 1. 检测工具链、同步 out\ 运行期 DLL
.\scripts\setup-dev.ps1

# 2. 编译（需已安装 Delphi 12.3 + madExcept）
.\scripts\build.ps1

# 3. 启动（优先 out\heidisql.exe，否则用已安装版本）
.\scripts\run.ps1
```

在 Cursor / VS Code 中也可通过任务面板运行：**HeidiSQL: 初始化开发环境**、**HeidiSQL: 编译**、**HeidiSQL: 运行**。

### 必需工具

| 工具 | 路径 / 说明 |
|------|-------------|
| **RAD Studio 12.3** (Delphi) | 默认 `C:\Program Files (x86)\Embarcadero\Studio\23.0\` |
| **madExcept** | 默认 `C:\Program Files (x86)\madCollection\` |
| **HeidiSQL 运行期 DLL**（可选） | `winget install HeidiSQL.HeidiSQL`，由 `setup-dev.ps1` 同步到 `out\` |

未安装 Delphi 时，`setup-dev.ps1` 会提示下载地址；`run.ps1` 仍可启动官方安装版用于对比测试。

### 手动编译（官方流程）

非 Windows 平台请查看官方 [`lazarus`](https://github.com/HeidiSQL/HeidiSQL/tree/lazarus) 分支。

也可在 RAD Studio 中打开 `packages\Delphi12.3\heidisql.groupproj`，或使用官方 `build.php`（需 PHP）。

Windows 版本需要 **Delphi 12.1** 或更高版本。较旧的 Delphi 大概率无法编译；Lazarus 等免费编译器目前无法编译本分支。

1. 安装 Delphi 后，在 `components` 目录编译并安装 SynEdit、VirtualTreeView 的运行时与设计时包。
2. 安装 [madExcept](http://madshi.net/madCollection.exe)。
3. 编译资源文件（`*.rc`），或执行 `php build.php`（官方 CI 脚本）。
4. 输出在 `out\heidisql.exe`。

## 翻译贡献

如需参与界面翻译，请在 [Transifex](https://explore.transifex.com/heidisql/heidisql/) 注册并加入对应语言项目。

## 向官方贡献

- 官方仓库仅接受缺陷修复类 Pull Request，不接受新功能。
- PR 中请附上对应的 issue 编号。

## Icons8 版权

2019 年 1 月加入 `TImageCollection` 的图标版权归 [Icons8](https://icons8.com) 所有，经 Ansgar 特别授权仅用于 HeidiSQL 项目，请勿挪作他用。

[![Embarcadero logo.](https://www.heidisql.com/images/made-with-delphi.png)](https://www.embarcadero.com/de/case-study/heidisql-case-study)
