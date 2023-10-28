using namespace Microsoft.PowerShell.SecretManagement

function Test-SecretVault {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$VaultName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [hashtable]$AdditionalParameters
    )

    if (-not $VaultName) { throw '1Password: You must specify a Vault Name to test' }

    Write-Verbose "SecretManagement: Testing Vault ${VaultName}"

    $vaults = & op --format json vault list 2>$null | ConvertFrom-Json

    Write-Verbose $Vaults

    $vaults.name -contains $VaultName
}

function Get-SecretInfo {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$VaultName,
        [Parameter()]
        [string]$Filter,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )

    $json = & op --format json items list  --categories Login,Password --vault $VaultName

    $items = $json | ConvertFrom-Json

    if (-Not [string]::IsNullOrEmpty($Filter))
    {
        $items = $items | Where-Object title -like $Filter
    }

    $keyList = [Collections.ArrayList]::new()

    foreach ($item in $items) {
        Write-Verbose $item.title

        $type = switch ($item.category) {
            'LOGIN' { [SecretType]::PSCredential }
            'PASSWORD' { [SecretType]::SecureString }
            Default { [SecretType]::Unknown }
        }

        $si = [SecretInformation]::new($item.title, $type, $VaultName)
    
        $si
    }
}

function Get-Secret {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [string]$Filter,
        [Parameter()]
        [string]$VaultName,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )

    $item = & op --format json item get $Name --fields label=username,label=password --vault $VaultName | ConvertFrom-Json


    $output = $null

    # item[0] is username
    Write-Verbose $item[0]
    
    if ($item[0].id -ine "username") {
        throw "First item returned from 1Password is not user name. It should be. Please run with -Verbose"
    }

    $username = $item[0].value

    # item[1] is password
    Write-Verbose $item[1]

    if ($item[1].id -ine "password") {
        throw "Second item returned from 1Password is not password. It should be. Please run with -Verbose"
    }

    if ( -not [string]::IsNullOrEmpty($item[1].value) ) {
        [securestring] $secureStringPassword = ConvertTo-SecureString $item[1].value -AsPlainText -Force
    }

    [PSCredential]::new($username, $secureStringPassword)
}

function Set-Secret {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [object]$Secret,
        [Parameter()]
        [string]$VaultName,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )

    throw "Not implemented yet!"

}

function Remove-Secret {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [string]$VaultName,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )

    throw "Not implemented yet!"
}
