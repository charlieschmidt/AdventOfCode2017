param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    $script:A = [Int64]0
    $script:B = [Int64]0
}

process {
    #parse the input, dont need fancy objects just the values as int64s
    $in |? {
        $_ -match '^Generator (?<Name>[A|B]) starts with (?<Value>\d+)$' 
    } | % { 
        [pscustomobject]$matches | select Name, Value
    } | % { 
        Set-Variable -Scope Script -Name $_.Name -Value ([Int64]$_.Value)
    }
    
}

end {  
    # how many generator pairs do we need to make
    if ($part -eq 1) {
        $max = 40000000
    } else {
        $max = 5000000
    }

    # for part2, keep a queue of generated numbers until we have a pair
    $aqueue = new-object system.collections.queue
    $bqueue = new-object system.collections.queue

    & { while ($true) { 1 } } |% { # ifinite pipeline generator, no specific values needed, gets stopped by the select -first $max later

        #update the values in the generators
        $script:A = ($script:A * 16807) % 2147483647
        $script:B = ($script:B * 48271) % 2147483647

        if ($part -eq 1) { #if part1, just send out the new values as a pair
            , @($script:A, $script:B) #unary array operator so the array goes out as an array not as invididual elements
        } else {
            if ($script:A % 4 -eq 0) { #only build pairs from A values that are mod 4
                $aqueue.Enqueue($script:A)
            }
            if ($script:B % 8 -eq 0) {
                $bqueue.Enqueue($script:B) #only build pairs from B values that are mod 8
            }

            if ($aqueue.Count -gt 0 -and $bqueue.Count -gt 0) { #if both queues have at least 1 item (one queue will have only 1 item)
                , @($aqueue.Dequeue(), $bqueue.Dequeue()) #build a pair and send out on the pipeline (unary array operator again)
            }
        }
    } | select -first $max |? { # only select the number of pairs we need - this will stop the infinite pipeline generator above, then where:
        ($_[0] -band 65535) -eq ($_[1] -band 65535) # lower 16 bits are equal
    } | measure | select -expand count # select the number of matching pairs
    
}