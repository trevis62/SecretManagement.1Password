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

class CommandBuilder {

    # examples
    # op item create --category=login --title='My Example Item' username=jane.doe@acme.com password=secret
    # op item edit 'My Example Item' --vault='Test' username=jane.doe@acme.com
    # op item template get Login | op item create --vault personal -

    hidden $commandArgs = [Collections.ArrayList]::new()
    hidden [string] $category
    hidden [string] $username
    hidden [string] $password

	# [bool] $UseNumbers = $false

	CommandBuilder([object] $secret, [string] $vault) {

        $this.commandArgs.Add('--vault')
        $this.commandArgs.Add($vault)

        $this.commandArgs.Add('item') | Out-Null

        if ($secret -is [string]) {
            $this.category = "password"
            $this.password = $secret
        }
        elseif ($secret -is [SecureString]) {
            $this.category = "password"
            $this.password = ConvertFrom-SecureString -SecureString $secret -AsPlainText
        }
        elseif ($Secret -is [PSCredential]) {
            $this.category = "login"
            $this.username = $secret.UserName
            $this.password = ConvertFrom-SecureString -SecureString $secret.Password -AsPlainText
        }
        else {
            throw ("Secret is unkown type {0}. It must be [string], [SecureString] or [PSCredential]" -f $secret.GetType().Name)
        }


	}

    [int] Execute() {
        # Write-Host @($this.commandArgs)

        & op @($this.commandArgs)

        return $?
    }

	static [CommandBuilder] Create($title, $secret, $vault, $item) {


		if ($item) {
    		return [EditCommandBuilder]::new($secret, $vault, $item)
        }

		return [CreateCommandBuilder]::new($title, $secret, $vault)
	}
}

class CreateCommandBuilder : CommandBuilder {

    hidden $template
    hidden [string] $data

    # op item template get Login | op item create --vault personal -

	CreateCommandBuilder($title, $secret, $vault) : base($secret, $vault) {
        $this.commandArgs.Add('create') | Out-Null

        $templ = & op item template get $this.category | ConvertFrom-Json

        $templ.fields | ForEach-Object {
            if ($_.id -eq 'username') { $_.value = $this.username }
            if ($_.id -eq 'password') { $_.value = $this.password }
        }
        
        $templ.title = $title

        $this.template = $templ
	}

    # override
    [int] Execute() {

        $this.template | ConvertTo-Json -Depth 4 | & op @($this.commandArgs) -

        return $?
    }
}

class EditCommandBuilder : CommandBuilder {

    # op item edit 'My Example Item' --vault='Test' username=jane.doe@acme.com

	EditCommandBuilder($secret, $vault, $item) : base($secret, $vault) {
        $this.commandArgs.Add('edit') | Out-Null

        $this.commandArgs.Add($item.title) | Out-Null

        if ($this.category -ieq 'login') {
            $this.commandArgs.Add("username=$($this.username)") | Out-Null
        }

        $this.commandArgs.Add("password=$($this.password)") | Out-Null

	}

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

    $item = & op item get $Name --vault $VaultName --format json 2>$null | ConvertFrom-Json

    $command = [CommandBuilder]::Create($Name, $Secret, $VaultName, $item)

    return $command.Execute()

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

