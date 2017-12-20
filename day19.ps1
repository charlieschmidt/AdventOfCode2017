param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    # hold the maze
    $script:maze = @()
}

process {
    # surround the actual maze data in empty spaces, so we don't have to do any bounds checking in the logic below
    $script:maze += " $in "
}

end { 
    # add spacing row at the start and end
    $sp = " " * $script:maze[0].Length
    $script:maze = ,$sp + $script:maze + ,$sp
    
    #starting position
    $y = 1
    $x = $script:maze[$y].IndexOf("|")

    #start on y axis, headed down
    $axis = 0
    $axes = @("y", "x")
    $direction = 1
    
    #first next character
    $next = $script:maze[$y + 1][$x]
    
    #answers
    $steps = 0
    $string = ""
    
    & { while ($next -ne ' ') { 
        $true
    } } | % {
        $steps++
        switch -regex ($next) {
            '[A-Z]' {
                #found a character, add it to the string
                $string += $next
            }

            '\+' {
                #change direction!

                # set new axis
                $axis = ($axis + 1) % 2

                # see what direction to go on that new axis
                $tryx = $x 
                $tryy = $y

                # try to go on the axis in the positive direction
                set-variable -name "try$($axes[$axis])" -Value ((get-variable -name $axes[$axis]).Value + 1)

                if ($script:maze[$tryy][$tryx] -ne ' ') {
                    #if it isnt an empty character, go that direction
                    $direction = 1
                } else {
                    #otherwise go the other way
                    $direction = -1
                }
            }
        }

        # move as configured by axis/direction
        set-variable -name $axes[$axis] -Value ((get-variable -name $axes[$axis]).Value + $direction)

        # get the next character
        $next = $script:maze[$y][$x]

        # write output to select whenever this ends
        if ($part -eq 1) {
            $string
        } else {
            $steps
        }
    } | select -last 1

}