[CmdletBinding(DefaultParameterSetName = 'None')]
Param(
    [String] [Parameter(Mandatory = $true)] $serviceUri,   
	[int] [Parameter(Mandatory = $true)] $validResponseStatus,   
	[int] [Parameter(Mandatory = $true)] $retries
	[int] [Parameter(Mandatory = $true)] $waitingTime
)

Set-StrictMode -Version 3

$i = 0
While ($i -le $retries) 
{
	Try 
	{
		Write-Host "Querying $serviceUri"
		$request = [System.Net.WebRequest]::Create($serviceUri)
		$response = $request.GetResponse()
		$status = [int]$response.StatusCode
		$response.Close()
		Write-Host "Response status is $status"
		
		If ($status -eq $validResponseStatus) 
		{
			Write-Host "The application responded with the expected status"
			$i = retries
		}
		Else 
		{
			Write-Host "The application responded with status $status,  $validResponseStatus was expected"
			if ($i -eq $retries) 
			{
				throw [System.Net.WebException]  "Status $status is not valid for a valid response of the application"
			}
			Start-Sleep -m $waitingTime
		}
	}	
	Catch [Exception] 
	{
		Write-Host "Something unexpected happened"
		Write-host $_.Exception.Message
		if ($i -eq $retries) 
		{
			Throw $_.Exception
		}
		Start-Sleep -m $waitingTime
	}
	$i++
}