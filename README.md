# SecretManagement extension for 1Password

This is a
[SecretManagement](https://github.com/PowerShell/SecretManagement)
extension for
[1Password](https://1password.com/).
It leverages the [`1password-cli`](https://support.1password.com/command-line/)
to interact with 1Password.

## Prerequisites

* [PowerShell](https://github.com/PowerShell/PowerShell)
* The [`1password-cli`](https://support.1password.com/command-line/) and accessible from Path
* The [SecretManagement](https://github.com/PowerShell/SecretManagement) PowerShell module

You can get the `SecretManagement` module from the PowerShell Gallery:

Using PowerShellGet v2:

```pwsh
Install-Module Microsoft.PowerShell.SecretManagement -AllowPrerelease
```

Using PowerShellGet v3:

```pwsh
Install-PSResource Microsoft.PowerShell.SecretManagement -Prerelease
```
## Installation

I have updated this module to work for my needs. The parent had not been updated to support the new version of the 1Password CLI. With 1Password8 and the new version of the CLI, everything has become simpler.
The CLI can now share authentication state with the 1Password app. Just make sure to check the "Integrate with the 1Password CLI" in the developer section of settings.

You have to install this manually for now by cloning the repository. Just copy the .psd1 and .psm1 files into a folder in your module path.
I'll try to find time to write something up and eventually automate the install or maybe a pull request back to parent if he is interested.

## Registration

Once you have it installed,
you need to register the module as an extension:

```pwsh
Register-SecretVault -Name vaultname -ModuleName SecretManagement.1Password
```

**Note**: The name you provide the `Name` parameter needs to match an existing vault in 1Password. E.g. Private.
If you want to access more than oen 1Password vault you need to register them separately with `Register-SecretVault`


### Vault parameters

There is no need for the additional parameters since we share the authentication state with the 1Password app.