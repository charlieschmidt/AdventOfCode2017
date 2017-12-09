param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
}

process {
    $garbage = $false # are we in garbage?
    $skip = $false # should we skip the next character?
    $depth = 0
    
    $in -split '' | ?{$_} | % { # split and ignore empties
        if ($skip) { $skip = $false } # skip character if set
        elseif ($_ -eq '!') { $skip = $true } # set to skip next character
        elseif ($garbage -eq $true -and $_ -ne '>') { if ($part -eq 2) { 1 } } # if in garbage section and not end-of-garbage (then character is garbage, keep track of those for part 2)
        elseif ($_ -eq '<') { $garbage = $true } # start of garbage
        elseif ($_ -eq '>') { $garbage = $false } # end of garbage
        elseif ($_ -eq '{') { $depth++ } # start of group, increment depth
        elseif ($_ -eq '}') { if ($part -eq 1) { $depth }; $depth--} #end of group, write out score and decrement depth
        
    } | measure -sum | select -expand sum # sum outputs - for part1 these are scores, for part2 it is a count of garbage characters
}

end {
}