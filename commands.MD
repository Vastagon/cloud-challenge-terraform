# Get an account key for the ConnectionString

$cosmosDBConnectionString = (Get-AzCosmosDBAccountKey -ResourceGroupName "cosmosdbrg" -Name "vastagoncosmosdb" -Type "ConnectionStrings")."Primary SQL Connection String"
Write-Output $cosmosDBConnectionString
