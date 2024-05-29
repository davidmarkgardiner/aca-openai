


Invoke-RestMethod -Uri $uri -Method Post -Body $json -ContentType "application/json" -Headers $authHeader

Error from server (InternalError): error when creating ".": Internal error occurred: failed calling webhook "default.v1api20220301.serverfarms.web.azure.com": failed to call webhook: the server could not find the requested resource