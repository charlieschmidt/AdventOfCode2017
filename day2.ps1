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
        <#
            split the input on tabs, pipe to measure
            measure the min and max values, pipe the measureresult to select
            select a new property that is the difference
            increment total by the different value
        #>
        $total += ($in -split '\t' | measure -min -max | select @{n = "d"; e = {$_.maximum - $_.minimum}}).d
    } else {
        $total += $in -split '\t' | % { # split the input on tabs, pipe to foreach (a)
            $x = $_
            $in -split '\t' |? { # resplit the input, pipe to where (b)
                $_ -ne $x -and $x % $_ -eq 0 # where (b) divides (a), pipe to foreach
            } | % {
                $x / $_ # perform division and roll that out
            } 
        } # increment total
    }
}

end { 
    $total
}