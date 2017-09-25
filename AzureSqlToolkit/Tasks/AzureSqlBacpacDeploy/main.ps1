[CmdletBinding(DefaultParameterSetName = 'None')]
Param(
    [String] [Parameter(Mandatory = $true)] $ConnectedServiceNameSelector,   
    [String] [Parameter(Mandatory = $true)] $ConnectedServiceNameARM, 
    [string] [Parameter(Mandatory = $true)] $ResourceGroup,
	[string] [Parameter(Mandatory = $true)] $SqlServer,
	[string] [Parameter(Mandatory = $true)] $SqlUsername,
	[string] [Parameter(Mandatory = $true)] $SqlPassword,
	[string] [Parameter(Mandatory = $true)] $DatabaseName,
	[string] [Parameter(Mandatory = $true)] $StorageKeyType,
	[string] [Parameter(Mandatory = $true)] $StorageKey,
	[string] [Parameter(Mandatory = $true)] $BacpacFile,
	[string] $Edition,
	[string] $ServiceObjective
)

Import-Module Azure #-ErrorAction SilentlyContinue

Set-StrictMode -Version 3

Try
{
	# Convert password
	$secureAdminPassword = $SqlPassword | ConvertTo-SecureString -AsPlainText -Force

	# Import bacpac
	Write-Output "Initialize bacpac import from $BacpacFile to database $DatabaseName on server $SqlServer"
	$importRequest = New-AzureRmSqlDatabaseImport `
		-ResourceGroupName $ResourceGroup `
		-ServerName $SqlServer `
		-DatabaseName $DatabaseName `
		-DatabaseMaxSizeBytes "262144000" `
		-StorageKeyType $StorageKeyType `
		-StorageKey $StorageKey `
		-StorageUri $BacpacFile `
		-Edition $Edition `
		-ServiceObjectiveName $ServiceObjective `
		-AdministratorLogin $SqlUsername `
		-AdministratorLoginPassword $secureAdminPassword

	# Check import status and wait for the import to complete
	Write-Output "Launch restore of bacpac file"
	$importStatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
	[Console]::Write("Importing")
	while ($importStatus.Status -eq "InProgress")
	{
		$importStatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
		[Console]::Write(".")
		Start-Sleep -s 10
	}
	[Console]::WriteLine("")
	$importStatus    
}
Catch [Exception]
{
    if($_.Exception.Message) 
    {
        Write-Error ($_.Exception.Message)
    }
    else 
    {
        Write-Error ($_.Exception)
    }
    throw
}
Finally
{

}

Write-Verbose "Leaving script"