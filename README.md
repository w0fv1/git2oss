# Git2OSS

一个简单的 PowerShell 工具，用于自动将 Git 仓库克隆并上传到阿里云 OSS 存储。

## 功能说明

- 自动检查和下载 Git（如果系统中未安装 Git）
- 自动从指定的仓库地址克隆代码
- 将克隆的仓库内容上传到指定的阿里云 OSS Bucket
- 支持通过配置文件管理项目参数

## 准备工作

### 环境依赖

- PowerShell 5.0 或以上
- 阿里云 `ossutil` 工具（[官方下载地址](https://help.aliyun.com/document_detail/120075.html)）

### 项目结构

```plaintext
项目目录
├── git2oss.ps1
├── gitw.ps1
├── aliyun_ossutil.exe
├── config.ini (需要用户创建)
└── config.sample.ini
```

### 配置文件

首次使用时，复制 `config.sample.ini` 为 `config.ini`，然后修改其中的内容。

配置示例如下：

```ini
[Git]
Repository=https://github.com/your-username/your-repo.git

[OSS]
Bucket=your-oss-bucket-name

[Aliyun]
AccessKeyId=your-access-key-id
AccessKeySecret=your-access-key-secret
Endpoint=oss-cn-region.aliyuncs.com
Proxy=  ; 可选配置，留空表示不使用代理
```

## 使用方法

1. 首次使用前确保 `aliyun_ossutil.exe` 和 `gitw.ps1` 放置在项目目录中。
2. 根据上述说明配置好 `config.ini` 文件。
3. 在 PowerShell 中进入项目目录，执行以下命令：

```powershell
.\git2oss.ps1
```

脚本会自动完成仓库克隆并上传至 OSS。

## 注意事项

- 务必妥善保管你的阿里云 AccessKey，不要公开至公共场合。
- 如果你使用了代理，请确保你的代理服务可用。

## 问题反馈

如在使用过程中遇到问题，请在本仓库 issue 区反馈，或者联系项目维护者。