. $PSScriptRoot\Create-Menu.ps1

New-Alias -Name "Create-Menu" -Value "New-SelectionMenu"

Export-ModuleMember -Function 'New-SelectionMenu' -Alias 'Create-Menu'