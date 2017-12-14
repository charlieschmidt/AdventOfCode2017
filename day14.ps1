param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    $script:hexToBin = @{
        "0" = "0000"
        "1" = "0001"
        "2" = "0010"
        "3" = "0011"
        "4" = "0100"
        "5" = "0101"
        "6" = "0110"
        "7" = "0111"
        "8" = "1000"
        "9" = "1001"
        "a" = "1010"
        "b" = "1011"
        "c" = "1100"
        "d" = "1101"
        "e" = "1110"
        "f" = "1111"
    }
}

process {
    , (0..127 | % { # generate 128 rows
        write-verbose "generating row $($_)"
        ("$in-$($_)" | ./day10.ps1 -part 2 | % { # use day10part2 as an external function
            $_ -split '' |? {$_} |% { # split the resulting string into characters, foreach character
                $script:hexToBin[$_] #lookup bin value and return
            }
        }) -join "" # join an entire row together
    }) |% { # output from previous pipeline is a single array, elements are strings (rows of 1/0s) - the maze/grid
        if ($part -eq 1) {
            $_ |% { # foreach row
                $_ -split '' |? {$_}  #split the row, select valid characters, put those individual 1 and 0 characters on the pipeline for later
            }
        } else {
            $maze = $_

            # queue for navigating sets
            $queue = new-object system.collections.queue
            
            # generate x,y starting points for every coordinate in the maze
            0..127 |% {
                $x = $_
                0..127 |? {
                    # only select those that we havnt seen and that are the start of a unique set (1s only, 0s are a wall)
                    # we will mark 1s as 0 once we have seen them
                    $maze[$_][$x] -eq "1"
                } |% {
                    #start of set
                    write-verbose "set at $x,$($_)"
                    1 # write out to pipeline that we have a set

                    # now visit the rest of this set and mark them seen

                    $queue.Enqueue(@{x = [int]$x; y = [int]$_}) #insert starting point
                
                    # navigate the set that starts at this x,y
                    & { while ($queue.Count -ne 0) { # until the queue is empty
                        $queue.Dequeue() # pop the first element
                    } } |? {
                        # only select those that we havnt seen, that are part of this set [$_ will only be connected coordinates] (1s only, 0s are a wall)
                        # we will mark 1s as 0 once we have seen them
                        $maze[$_.y][$_.x] -eq "1"
                    } |% { 
                        # still part of this set, mark seen
                        $r = $maze[$_.y].ToCharArray()
                        $r[$_.x] = "0"
                        $maze[$_.y] = $r -join ''

                        # put each of the connected coordinates on the queue to navigate
                        if ($_.x -gt 0) { $queue.Enqueue(@{x = $_.x - 1; y = $_.y}) }
                        if ($_.x -lt 127) { $queue.Enqueue(@{x = $_.x + 1; y = $_.y}) }

                        if ($_.y -gt 0) { $queue.Enqueue(@{x = $_.x; y = $_.y - 1}) }
                        if ($_.y -lt 127) { $queue.Enqueue(@{x = $_.x; y = $_.y + 1}) }
                    }
                }
            }
        }
    } | measure -sum | select -expand sum #output from part1 are the individual characters in the maze (1s and 0s); output from part2 is '1' for each set.  sum output and return
}

end {  
}