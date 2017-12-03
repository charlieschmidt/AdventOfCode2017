param (
    [Parameter(ValueFromPipeline=$true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    $total = 0
}
process 
{
    if ($part -eq 1) {
        $total += ($in -split '\t' | measure -min -max | select @{n = "d"; e = {$_.maximum - $_.minimum}}).d
    } else {
        $total += $in -split '\t' | % { $x = $_; $in -split '\t' |? {$_ -ne $x -and $x % $_ -eq 0} | % {$x / $_ } }
    }
}

end { 
    $total
}