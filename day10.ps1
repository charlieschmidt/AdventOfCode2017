param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
}

process {
    $data = 0..255 # initial data set up
    $skip = 0
    $pos = 0

    if ($part -eq 1) {
        $limit = 1 # part1 iterates only once
        $lengths = $in -split ',' |? {$_} # part1 uses the input as csv lengths
        
    } else {
        $limit = 64 # part2 iterates 64 times
        $lengths = @([int[]][System.Text.Encoding]::ASCII.GetBytes($in)) + @(17,31,73,47,23) # special modification to input for part2
    }

    1..$limit | % {
        $lengths |% {
            $l = [int]$_
            $slice = ($data + $data)[$pos..($pos + $l - 1)] # get the array slice, we do $data+$data so we can wraparound and keep the same order
            
            0..($l - 1) | % { # for 0 to this length
                $data[($pos + $_) % $data.length] = $slice[($l - 1 - $_) % $data.length]  # set the data at that element to the opposite in the slice
            }

            $pos = ($pos + ($l + $skip++)) % $data.length # increment position

            ,$data # write out the data at this point
        }
    } | select -last 1 |% { # select the last output (either the only output for part1, or the 64th for part2)
        if ($part -eq 1) {
            $x = 1 # multiplier increment
            $_ | select -first 2 |% { # for the data input, take the first two elements
                $x = $x * $_ # *=
                $x
            } | select -last 1 | write-output # write it out (skipping the first output)
        } else { 
            #part 2
            (0..15 |% { # 16 sets
                $s = $_ # which set
                $x = $data[$s * 16] # first index of set
                1..15 |% { # rest of the 15 indexes of this set
                    $x = $x -bxor $data[$s * 16 + $_] # ^= with the new inedx
                } 
                '{0:x2}' -f $x # hex format
            }) -join '' # join outputs
        }
    }
    


}

end {
}