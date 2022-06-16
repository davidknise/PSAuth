# PSAuth

Cmdlets for saving and reading secrets to and from files using DPAPI.

## Installing

To make the cmdlets in this module always available to you on your machine, do the following:

1. Clone the repo to a folder within your %PSModulePath%.

```
git clone https://securitytools.visualstudio.com/DefaultCollection/SecurityIntegration/_git/PSAuth
```

2. Open up your **PowerShell Profile file** and add the following line:

```
Import-Module 'PSAuth'
```

3. Restart PowerShell.

### Installation Tips

To see what folders are on your PSModulePath:

```
Write-Host $env:PSModulePath
```

All folders within that path will be accessible. As long as the module and the folder have the same name, `Import-Module` can be called with just the folder/module name for any module within the PSModulePath.

To find your **PowerShell Profile file**:

The default location for this is `C:\Users\%USERNAME%\Documents\WindowsPowerShell\profile.ps1`. If the file does not exist, you may create it. This file is automatically run by PowerShell when a new PowerShell session is created, such as opening a new PowerShell prompt.

## Usage

Getting saved credentials:

```
Get-ProtectedData -Path 'C:\Temp\PathToProtectedData.data'
```

Saving new credentials:

```
$data = Read-Host -AsSecureString
<Your Data>
Set-ProtectedData -Path 'C:\Temp\PathToProtectedData.data' -Data $data [-Force]
```
If you do not supply the values, you will be prompted for them:

```
Set-ProtectedData
Path to protected file: <Your Path>
Data to protected: <Your Data>
```
