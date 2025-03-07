$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new("cert.pem")

$store = Get-Item -LiteralPath Cert:\LocalMachine\TrustedPeople
$store.Open('ReadWrite')
$store.Add($cert)
$store.Dispose()

$store = Get-Item -LiteralPath Cert:\LocalMachine\Root
$store.Open('ReadWrite')
$store.Add($cert)
$store.Dispose()
