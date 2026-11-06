param([Parameter(Mandatory = $true)][string]$InnoCompiler)
$ErrorActionPreference = 'Stop'
$InnoCompiler = (Resolve-Path -LiteralPath $InnoCompiler).Path
$python = (Get-Command python.exe -ErrorAction Stop).Source
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$app = Join-Path $PSScriptRoot 'app'
$setup = Join-Path $PSScriptRoot 'setup'
$build = Join-Path $PSScriptRoot 'build'
$pdf = Join-Path $app 'vendor\PDFsharp-1.50.5147\lib\net20\PdfSharp.dll'
$icon = Join-Path $app 'assets\mustek-scanner-app-icon.ico'
$zadig = Join-Path $PSScriptRoot 'downloads\zadig-2.9.exe'
if (-not (Test-Path -LiteralPath $pdf) -or -not (Test-Path -LiteralPath $zadig)) {
    throw 'Run Restore-Dependencies.ps1 before building setup.'
}
if ((Get-FileHash -LiteralPath $zadig).Hash.ToLowerInvariant() -ne '4ecaa95df3da3621486a043aef8b3050b8bafe7c901402871e816229ef82039b') {
    throw 'Unexpected Zadig binary.'
}
$signature = Get-AuthenticodeSignature -LiteralPath $zadig
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Akeo Consulting') {
    throw 'Invalid Zadig signature.'
}
& $python (Join-Path $PSScriptRoot 'prepare_payload.py')
if ($LASTEXITCODE -ne 0) { throw 'Scanner payload preparation failed.' }

$compilerOptions = @('/nologo', '/target:winexe', '/platform:x64', '/optimize+', '/codepage:65001', '/langversion:5',
    ('/win32manifest:' + (Join-Path $app 'app.manifest')), '/reference:System.dll', '/reference:System.Core.dll',
    '/reference:System.Drawing.dll', '/reference:System.Windows.Forms.dll', '/reference:System.Xml.dll')
& $compiler @compilerOptions ('/out:' + (Join-Path $build 'MustekStudio.exe')) `
    ('/win32icon:' + $icon) ('/resource:' + $icon + ',MustekStudio.AppIcon') `
    /reference:System.IO.Compression.dll ('/reference:' + $pdf) ('/resource:' + $pdf + ',Portable.PdfSharp.dll') `
    ('/resource:' + (Join-Path $build 'payload.zip') + ',Portable.payload.zip') `
    ('/resource:' + (Join-Path $build 'manifest.tsv') + ',Portable.manifest.tsv') `
    ('/resource:' + (Join-Path $build 'version.txt') + ',Portable.version.txt') `
    ('/resource:' + (Join-Path $build 'defaults.xml') + ',Portable.defaults.xml') `
    (Join-Path $app 'ScannerCore.cs') (Join-Path $app 'MustekStudio.cs') (Join-Path $app 'Appearance.cs') `
    (Join-Path $app 'RuntimePackage.cs') (Join-Path $app 'AppUpdate.cs') (Join-Path $app 'AssemblyInfo.cs')
if ($LASTEXITCODE -ne 0) { throw 'Application build failed.' }

& $compiler @compilerOptions ('/out:' + (Join-Path $build 'ScannerConnection.exe')) (Join-Path $setup 'ScannerConnection.cs')
if ($LASTEXITCODE -ne 0) { throw 'Scanner connection assistant build failed.' }
& $InnoCompiler (Join-Path $setup 'MustekStudio.iss')
if ($LASTEXITCODE -ne 0) { throw 'Installer build failed.' }
$root = Split-Path -Parent $PSScriptRoot
$output = Join-Path $root 'MustekStudio-Setup.exe'
$hash = (Get-FileHash -LiteralPath $output).Hash.ToLowerInvariant()
($hash + '  MustekStudio-Setup.exe') | Set-Content -LiteralPath (Join-Path $root 'Setup-SHA256.txt') -Encoding ASCII
$version = (Get-Item -LiteralPath $output).VersionInfo.ProductVersion.Trim()
@($version, $hash) | Set-Content -LiteralPath (Join-Path $root 'update.txt') -Encoding ASCII
Write-Output ('Setup: ' + $output)
