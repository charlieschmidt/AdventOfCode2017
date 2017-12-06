param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
}

process {
    [int[]]$m = $in -split "`t" # fill memory banks
    $x = 1 # step counter
    $s = @{} # seen configurations
    $s[$m -join ""] = $x # set seen initial
    
    & { while ($true) { # start inifinite pipeline
        $m | measure -max | select -expand maximum # get the max value
    } } | % { 
        $i = $m.IndexOf([int]$_) # get the index of that value
        $m[$i] = 0 # set to zero

        1..$_ | % { # increment the next $_ (wrapping around)
            $m[($i + $_) % $m.count]++
        }

        $m -join "" # put the new configuration out on the pipeline
    } | % {
        if ($s.ContainsKey($_)) {
            # if we've seen it before
            if ($Part -eq 1) { 
                $s.values.count # part one wants to know how many cycles to get from start to here
            } else { 
                $x - $s[$_] # part two wants to know how many cycles in from repeat to repeat
                # $x is current position, $s values are the 'when i saw it' positions
            }
        } else {
            $s[$_] = $x++ # if we havnt seen it, put it in the list with its "when i saw it"
        }
        
        #only things that come out of this block in the pipeline are $s.values.count or $x-$s[$_] above
        
    } | select -first 1 # select the first thing out of the pipe here to end the inifinite pipe. 
}

end { 
    
}