[CmdletBinding()]
param(
    [string]$BackendBaseAddress = "http://127.0.0.1:8080",

    [string]$InferenceBaseAddress = "http://127.0.0.1:8000",

    [string]$ImagePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-HealthRequest {
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [string]$ExpectedStatus
    )

    $response = Invoke-RestMethod `
        -Uri $Uri `
        -Method Get `
        -TimeoutSec 30

    if ($response.status -ne $ExpectedStatus) {
        throw "Expected status '$ExpectedStatus' from '$Uri', but received '$($response.status)'."
    }

    Write-Host "$Uri -> $ExpectedStatus" -ForegroundColor Green
}

function Get-ImageContentType {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        ".png" {
            return "image/png"
        }

        ".jpg" {
            return "image/jpeg"
        }

        ".jpeg" {
            return "image/jpeg"
        }

        default {
            throw "Only PNG and JPEG images are supported."
        }
    }
}

Write-Host "Checking inference liveness..."

Invoke-HealthRequest `
    -Uri "$($InferenceBaseAddress.TrimEnd('/'))/health/live" `
    -ExpectedStatus "healthy"

Write-Host "Checking backend liveness..."

Invoke-HealthRequest `
    -Uri "$($BackendBaseAddress.TrimEnd('/'))/health/live" `
    -ExpectedStatus "healthy"

Write-Host "Checking backend readiness..."

Invoke-HealthRequest `
    -Uri "$($BackendBaseAddress.TrimEnd('/'))/health/ready" `
    -ExpectedStatus "ready"

if ([string]::IsNullOrWhiteSpace($ImagePath)) {
    Write-Host "No image supplied. Analysis verification skipped."
    exit 0
}

if (-not (Test-Path -LiteralPath $ImagePath -PathType Leaf)) {
    throw "The image file does not exist: $ImagePath"
}

$resolvedImagePath = (Resolve-Path -LiteralPath $ImagePath).Path
$contentType = Get-ImageContentType -Path $resolvedImagePath
$responsePath = [System.IO.Path]::GetTempFileName()

try {
    Write-Host "Running backend analysis..."

    & curl.exe `
        --max-time 60 `
        --silent `
        --show-error `
        --fail-with-body `
        -X POST `
        "$($BackendBaseAddress.TrimEnd('/'))/api/v1/analyses" `
        -F "image=@$resolvedImagePath;type=$contentType" `
        --output $responsePath

    if ($LASTEXITCODE -ne 0) {
        throw "The analysis request failed with curl exit code $LASTEXITCODE."
    }

    $response = Get-Content `
        -LiteralPath $responsePath `
        -Raw |
        ConvertFrom-Json

    if ([string]::IsNullOrWhiteSpace($response.model.id)) {
        throw "The analysis response does not contain a model identifier."
    }

    if ([string]::IsNullOrWhiteSpace($response.model.category)) {
        throw "The analysis response does not contain a model category."
    }

    if ($response.decision -notin @("normal", "anomalous")) {
        throw "The analysis response contains an unsupported decision."
    }

    if ($null -eq $response.heatmap) {
        throw "The analysis response does not contain a heatmap."
    }

    if ($response.heatmap.contentType -ne "image/png") {
        throw "The heatmap content type is not image/png."
    }

    if ($response.heatmap.width -le 0 -or $response.heatmap.height -le 0) {
        throw "The heatmap dimensions are invalid."
    }

    try {
        $heatmapBytes = [Convert]::FromBase64String(
            $response.heatmap.dataBase64
        )
    }
    catch {
        throw "The heatmap does not contain valid Base64 data."
    }

    if ($heatmapBytes.Length -eq 0) {
        throw "The decoded heatmap is empty."
    }

    Write-Host "Analysis verification succeeded." -ForegroundColor Green
    Write-Host "  Model: $($response.model.id)"
    Write-Host "  Category: $($response.model.category)"
    Write-Host "  Score: $($response.score)"
    Write-Host "  Threshold: $($response.threshold)"
    Write-Host "  Decision: $($response.decision)"
    Write-Host "  Processing time: $($response.processingTimeMs) ms"
    Write-Host "  Trace ID: $($response.traceId)"
    Write-Host "  Heatmap: $($response.heatmap.width)x$($response.heatmap.height) PNG"
    Write-Host "  Heatmap bytes: $($heatmapBytes.Length)"
}
finally {
    Remove-Item `
        -LiteralPath $responsePath `
        -Force `
        -ErrorAction SilentlyContinue
}