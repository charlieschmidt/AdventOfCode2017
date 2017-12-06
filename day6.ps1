param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    $c = 0
}

process {
    [int[]]$m = $in -split "`t" # fill memory banks
    $x = 1

    $s = @{
        $in = $x
    }
$s
    $m
$done = $false
    & { while ($done -eq $false) { $true } } | % { 
        $c++
        [int]$maxvalue = $m | measure -max | select -expand maximum
        $maxindex = $m.IndexOf($maxvalue)
        # write-host "index: $maxindex $maxvalue"
        $m[$maxindex] = 0
        for ($i = 1; $i -le $maxvalue; $i++) {
            $m[($maxindex + $i) % $m.count]++
        }
        if ($s.ContainsKey($m -join "`t")) {
            $x - $s[$m -join "`t"]
            #    $m
            $done = $true
        } 
        $s[$m -join "`t"] = $x
        #$s
        $x++
        1
    } 
    
    
       # $m
        $c
        $s.Values | measure -max
}

end { 
    
}