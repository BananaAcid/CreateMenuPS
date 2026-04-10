# Fix for -> Write-Error: Failed to generate the compressed file for module 'Cannot index into a null array.'.
$env:DOTNET_CLI_UI_LANGUAGE="en_US"


Test-ModuleManifest -Path ".\Create-Menu\Create-Menu.psd1"

Test-ModuleManifest -Path ".\Create-Menu\Create-Menu.psd1" | Select-Object -expandproperty exportedcommands | format-table

Write-Host "IS PROJECT URL SET?" -ForegroundColor Yellow

pause
Publish-Module -Path ".\Create-Menu" -NuGetApiKey $env:NUGET_API_KEY -Verbose

<#
# find module
Find-Module Create-Menu

# install test
Install-Module Create-Menu -Scope CurrentUser

# Import test
Import-Module Create-Menu
#>



<# 
New-ModuleManifest -Path ".\Create-Menu\Create-Menu.psd1" `
    -RootModule "Create-Menu.psm1" `
    -Author "Nabil Redmann (BananaAcid)" `
    -Description "Power up your PowerShell scripts with simple selection menus" `
    -CompanyName "Nabil Redmann" `
    -ModuleVersion "1.0.0" `
    -FunctionsToExport "*" `
    -PowerShellVersion "5.1"
#>