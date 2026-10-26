# Verify local endpoints directly, regardless of system HTTP proxy settings.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$localHandler = [System.Net.Http.HttpClientHandler]::new()
$localHandler.UseProxy = $false
$localClient = [System.Net.Http.HttpClient]::new($localHandler)
$localClient.Timeout = [TimeSpan]::FromSeconds(10)
# Vite's HTML fallback expects an Accept header, as sent by browsers and curl.
$localClient.DefaultRequestHeaders.Accept.ParseAdd('*/*')

function Get-LocalResponse([string]$Address) {
    $response = $localClient.GetAsync($Address).GetAwaiter().GetResult()
    try {
        $response.EnsureSuccessStatusCode() | Out-Null
        return [pscustomobject]@{
            Status = [int]$response.StatusCode
            Body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            ContentType = $response.Content.Headers.ContentType.MediaType
        }
    } finally { $response.Dispose() }
}

try {
    $frontPage = Get-LocalResponse 'http://127.0.0.1:5735/'
    if ($frontPage.Status -ne 200 -or $frontPage.Body -notmatch '<html') {
        throw 'Frontend did not return an HTML page.'
    }
    Write-Output 'PASS: Frontend serves HTML.'

    $readyResponse = Get-LocalResponse 'http://127.0.0.1:5734/ready'
    if ($readyResponse.Status -ne 204) { throw 'API readiness check failed.' }
    Write-Output 'PASS: API is ready.'

    $specResponse = Get-LocalResponse 'http://127.0.0.1:5734/api/avatar/spec'
    $avatarSpec = $specResponse.Body | ConvertFrom-Json
    if ($avatarSpec.parts.eyes -ne 'EyeType' -or -not $avatarSpec.values.EyeType.HEART) {
        throw 'Avatar customization options are missing.'
    }
    Write-Output 'PASS: API returns customization options.'

    $avatarResponse = Get-LocalResponse 'http://127.0.0.1:5734/api/avatar?eyes=HEART'
    if ($avatarResponse.ContentType -ne 'image/svg+xml') {
        throw 'Avatar endpoint returned the wrong content type.'
    }
    [xml]$avatarXml = $avatarResponse.Body
    if ($avatarXml.DocumentElement.LocalName -ne 'svg' -or
        $avatarXml.DocumentElement.NamespaceURI -ne 'http://www.w3.org/2000/svg') {
        throw 'Avatar endpoint did not return a valid SVG image.'
    }
    Write-Output 'PASS: Avatar generation returns valid SVG.'

    $proxyResponse = Get-LocalResponse 'http://127.0.0.1:5735/api/avatar/spec'
    $proxySpec = $proxyResponse.Body | ConvertFrom-Json
    if (-not $proxySpec.values.EyeType.HEART) { throw 'Frontend-to-API routing failed.' }
    Write-Output 'PASS: Frontend routes requests to the API.'
    Write-Output 'All 5 deployment checks passed.'
} finally { $localClient.Dispose() }
