param (
    [Parameter(ValueFromPipeline = $true)]
    [int]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    $ins = @()
}

process {
    $ins += $in # just collect from the original get-content pipeline   
}

end { 
    $p = 0

    & { while ($p -lt $ins.count) { $p } } | % {  # infinite pipeline generator, outputs current position
        $p = $_ + $ins[$_]  # set position to new value (current plus offset)
        if ($part -eq 2 -and $ins[$_] -ge 3) { $ins[$_]-- } else { $ins[$_]++ }    # increment or decrement the offset in the instruction array
        1   # put something out on the pipeline so we can measure
        
    } | measure | select -expand count
}