param (
    [Parameter(ValueFromPipeline = $true)]
    [int]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    # how many iterations
    if ($part -eq 1) {
        # create a new list to contain the buffer values
        $script:buffer = [System.Collections.ArrayList]::new()
        [void]$script:buffer.Add(0) # insert the first
        
        $script:max = 2017
    } else {
        $script:max = 50000000
    }
}

process {
    #starting position
    $position = 0
    
    1..$script:max | % { #max iters
        # new position = position + input value, then mod to the length of the array, and add 1 (so it inserts after)
        # $_ is also the length of the array, since we have 1 eleement and start at 1 and add one each time
        $position = (($position + $in) % $_) + 1

        if ($part -eq 1) {
            #if part one, insert the iter value at the position
            [void]$script:buffer.Insert($position, $_)

            #send out the value at the next position to the pipeline
            $script:buffer[$position + 1]
        } elseif ($position -eq 1) {
            #if part two, and we just inserted at position 1, then write out the element
            #this is what was inserted /after/ position 0
            $_
        }
    } | select -last 1 #select the last thing on the pipeline
}

end {  
}