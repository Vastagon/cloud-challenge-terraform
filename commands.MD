# Get an account key for the ConnectionString

$cosmosDBConnectionString = (Get-AzCosmosDBAccountKey -ResourceGroupName "cosmosdbrg" -Name "vastagoncosmosdb" -Type "ConnectionStrings")."Primary SQL Connection String"
Write-Output $cosmosDBConnectionString














FUNCTIONS_WORKER_RUNTIME = ~4
WEBSITE_CONTENTSHARE = vastagon-linux-function-app
WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = DefaultEndpointsProtocol=https;AccountName=vastresumefunctionapp;AccountKey=cgLdk/5HmShC+k9lrZ27ekJryunJcnNtz/a/0wL5gUrCutTQac4/7qu4x/JH9EXapV2KA2S+pw05+AStj4knjg==;EndpointSuffix=core.windows.net

