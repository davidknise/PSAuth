Add-Type -Assembly System.Security

Function Get-ProtectedData
{
    <#
    .PARAMETER Path
    The file path of the DPAPI encrypted file to read. This file must have been encrypted by the current user on the same machine.

    .PARAMETER Raw
    By default, a SecureString of the data is output. Passing -Raw will output the raw data.
    #>
    Param
    (
        [Parameter(ParameterSetName = 'Object')]
        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'String')]
        [String] $Path,

        [Parameter(ParameterSetName = 'Object')]
        [Switch] $Object,

        [Parameter(ParameterSetName = 'SecureString')]
        [Switch] $SecureString,

        [Parameter(ParameterSetName = 'String')]
        [Switch] $Raw
    )

    if ([String]::IsNullOrWhiteSpace($Path))
    {
        $Path = Read-Host -Prompt 'Path to protected file'
    }

    if (-not (Test-Path -Path $Path -PathType 'Leaf'))
    {
        throw [System.FileNotFoundException] "ProtectedData file does not exist: $Path"
    }

    [byte[]] $fileBytes = Get-Content -Path $Path -AsByteStream

    try
    {
        Write-Verbose "Decrypting file: $Path"
        $rawBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($fileBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)    
    }
    catch [Exception]
    {
        Write-Error 'Unable to decrypt the contents of the file. Be sure that the file is a DPAPI encrypted file to which the current user has access.'
        throw $_
    }

    $rawString = [System.Text.Encoding]::ASCII.GetString($rawBytes)

    if ($Object.IsPresent)
    {
        $obj = $rawString | ConvertFrom-Json -Depth 10
        Write-Output $obj
    }
    elseif ($SecureString.IsPresent)
    {
        $secureString = ConvertTo-SecureString -String $rawString -AsPlainText -Force
        Write-Output $secureString
    }
    elseif ($String.IsPresent)
    {
        Write-Output $rawString
    }
    else
    {
        throw 'Auth output type not defined.'    
    }
}

Function Set-ProtectedData
{
    Param
    (
        [Parameter(ParameterSetName = 'Object')]
        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'String')]
        [String] $Path,

        [Parameter(ParameterSetName = 'Object')]
        [Object] $Object,

        [Parameter(ParameterSetName = 'SecureString')]
        [SecureString] $SecureString,

        [Parameter(ParameterSetName = 'String')]
        [String] $String,

        [Parameter(ParameterSetName = 'Prompt')]
        [Switch] $Prompt,

        [Parameter(ParameterSetName = 'Object')]
        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'String')]
        [Switch] $Force
    )

    if ([String]::IsNullOrWhiteSpace($Path))
    {
        $Path = Read-Host -Prompt 'Path to protected file'
    }

    if (Test-Path -Path $Path -PathType 'Leaf')
    {
        if (-not $Force.IsPresent)
        {
            throw [System.ArgumentException] "The protected file path already exists: $Path. To overwrite this file, use -Force."
        }
    }

    if ($Object)
    {
        $String = $Object | ConvertTo-Json
    }    
    elseif ($Prompt.IsPresent)
    {
        $SecureString = Read-Host -Prompt 'Data to protect' -AsSecureString
    }

    if ($SecureString)
    {
        $rawBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        $String = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($rawBstr)
    }

    $rawBytes = [System.Text.Encoding]::ASCII.GetBytes($String)

    try
    {
        Write-Verbose 'Encrypting data...'
        $protectedBytes = [System.Security.Cryptography.ProtectedData]::Protect($rawBytes, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)    
    }
    catch [Exception]
    {
        Write-Error 'Unable to encrypt the data. [Security.Crytography.ProtectedData]::Protect() failed.'
        throw $_
    }

    Write-Verbose "Saving data to file: $Path"
    Set-Content -Path $Path -AsByteStream -Value $protectedBytes -Force
    Write-Verbose "Protected file saved: $Path"
}

Export-ModuleMember -Function @(
    'Get-ProtectedData',
    'Set-ProtectedData'
)