
param(
    [Parameter(Mandatory = $true)]
    [int]$Day,
    [Parameter(Mandatory = $false)]
    [int]$Part = 1
)

process {
    get-content "Day$Day.input" | &"./day$Day.ps1" -Part $Part
}
