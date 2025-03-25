# Git2OSS

**Git2OSS** 是一个用于将多个 Git 仓库批量克隆并上传至阿里云 OSS 的 PowerShell 脚本工具。

---

## 🚀 功能特性

- 支持多任务配置：一个脚本同时处理多个仓库上传。
- 自动下载 Git（通过 `gitw.ps1`）。
- 上传时忽略 `.git` 文件夹。
- 上传后自动将仓库目录加入 `.gitignore`。

---

## 🛠 使用方法

### 1. 准备环境

- Windows 系统。
- `PowerShell 5+`
- 将以下文件放入同一目录：
  - `git2oss.ps1`
  - `gitw.ps1`
  - `aliyun_ossutil.exe`
  - `config.ini`（或复制并修改 `config.sample.ini`）

---

### 2. 配置文件 `config.ini`

支持多个任务：每个任务对应一个 Git 仓库与 OSS 上传目标。

```ini
[Task-index]
Repository=https://github.com/example/index.git
Bucket=your-oss-bucket-1
Endpoint=oss-cn-beijing.aliyuncs.com
Region=cn-beijing

[Task-assets]
Repository=https://github.com/example/assets.git
Bucket=your-oss-bucket-2
Endpoint=oss-cn-shanghai.aliyuncs.com
Region=cn-shanghai

[Aliyun]
AccessKeyId=your-access-key-id
AccessKeySecret=your-access-key-secret
Proxy=
```

> ✅ `Task-*` 是任务名，可以随意命名。

---

### 3. 执行脚本

```powershell
.\git2oss.ps1
```

- 脚本将自动：
  - 检查并下载 Git（如无）。
  - 克隆所有任务中的仓库。
  - 上传至 OSS 指定 bucket。
  - 将仓库目录加入 `.gitignore`。

---

## 📝 注意事项

- `aliyun_ossutil.exe` 必须与脚本位于同一目录。
- 若 `.gitignore` 不存在将自动创建。
- 上传时 `.git` 文件夹将被忽略。
- 上传行为为覆盖（带 `--force`）。

---

## 📁 示例目录结构

```
Git2OSS\
├── aliyun_ossutil.exe
├── gitw.ps1
├── git2oss.ps1
├── config.ini
└── .gitignore
```

---

## 📦 License

MIT
