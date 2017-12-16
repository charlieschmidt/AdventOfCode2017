param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
   
}

process {
    # set up initial state
    $programs = @("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p")

    # keep track of orders we've seen before
    $seen = @()

    # set max permutations
    if ($part -eq 1) {
        $max = 0
    } else {
        $max = 1000000000
    }

    0..$max | % {
        # check and see if we've seen current state before
        $p = $programs -join ''

        if ($p -in $seen) {
            $seen[$max % $_] #if we have, return the state that is congurant with the max state
        } else {
            #otherwise, perform the dance

            $seen += $p # add this state to the seen ones

            $in -split ',' | % { # foreach step in the dance
                switch -regex ($_) {
                    # find the step
                    '^s(?<X>\d+)' { 
                        # take the end of the array and move it to the beginning
                        $programs = $programs[(-1 * $matches.X)..-1] + $programs[0..($programs.Length - $matches.X - 1)]
                    }
                    '^x(?<A>\d+)\/(?<B>\d+)$' {
                        # swap two indexes
                        $x = $programs[$matches.A]
                        $programs[$matches.A] = $programs[$matches.B]
                        $programs[$matches.B] = $x
                    }
                    '^p(?<A>[a-p]+)\/(?<B>[a-p]+)$' { 
                        # swap two programs
                        $a = $programs.IndexOf($matches.A)
                        $b = $programs.IndexOf($matches.B)
                        $x = $programs[$a]
                        $programs[$a] = $programs[$b]
                        $programs[$b] = $x
                    }
                }
            }

            if ($_ -eq $max) { # if we're at the max, and we didn't encounter a cycle in the seen array, then write out where we are
                $programs -join ''
            }
            
        }
    } | select -first 1 # select the first output to end the iterations early
}

end {  
    
}