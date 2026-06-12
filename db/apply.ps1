param(
    [string]$Container = "leasestudy-mssql",
    [string]$SaPassword = $env:MSSQL_SA_PASSWORD
)

if ([string]::IsNullOrWhiteSpace($SaPassword)) {
    $SaPassword = "YourStrong!Passw0rd"
}

$ErrorActionPreference = "Stop"
$sqlcmd = "/opt/mssql-tools18/bin/sqlcmd"

$scripts = @(
    @{ Db = "master";       File = "/scripts/01_schema.sql" },
    @{ Db = "LeaseStudyDb"; File = "/scripts/02_master.sql" },
    @{ Db = "LeaseStudyDb"; File = "/scripts/procs/usp_CreateContract.sql" },
    @{ Db = "LeaseStudyDb"; File = "/scripts/procs/usp_CalculateLeaseFee.sql" },
    @{ Db = "LeaseStudyDb"; File = "/scripts/procs/usp_GetContractList.sql" }
)

foreach ($s in $scripts) {
    Write-Host "==> $($s.File) [$($s.Db)]" -ForegroundColor Cyan
    docker exec -e SA_PWD=$SaPassword $Container `
        $sqlcmd -S localhost -U sa -P $SaPassword -C -b -I -d $s.Db -i $s.File
    if ($LASTEXITCODE -ne 0) {
        throw "Failed: $($s.File)"
    }
}

Write-Host "=== すべてのスクリプト投入完了 ===" -ForegroundColor Green
