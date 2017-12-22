param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    #hash table to store rules, from->to
    $script:rules = @{}
}

process {
    # parse the line into an object
    # we'll parse the To side into just an array of rows
    # parse the From side into an array of arrays of cells
    [pscustomobject] @{
        From = ($in -split ' => ')[0] -split '/' | % { , ($_ -split '' |? {$_})}
        To   = ($in -split ' => ')[1] -split '/'
    } | % {
        $r = $_
        
        1..4 | % { # rotate
            #rotate = transpose + flip

            #transpose on diagonal
            0..($r.From.Length - 1) | % {
                $y = $_

                $y..($r.From.Length - 1) |? {# cant do ($y+1).. cause of powershells reverse enumerator thingies lol
                    # dont bother rotating when its equal
                    $_ -ne $y #remove it here
                } | % { 
                    $x = $_
                    # for y 0..l
                    # for x y+1..l
                    # ^ gives us the diagonal

                    #swap cells
                    $c = $r.From[$_][$y]
                    $r.From[$_][$y] = $r.From[$y][$_] 
                    $r.From[$y][$_] = $c
                }
            }

            #flip each row
            0..($r.From.Length - 1) |% {
                [Array]::Reverse($r.From[$_])
            }
            
            # output the rule
            $r | select From, To # this is a new object on the pipeline, not $r

            #and note, $r persists, so we'll rotate this same one again next time
        }
    } | % {
        # foreach rule so far, also generate the mirror
        $from = $_.From | % { 
            , $_[$_.length..0] #reverse each row
        }

        # select the two rules - the original, and the mirror
        # combine From back into a single string for easier hashing/matching
        # To remains an array of rows
        $_ | select @{n = "From"; e = {($_.From | % {$_ -join ''}) -join '/'}}, To 
        $_ | select @{n = "From"; e = {($From | % {$_ -join ''}) -join '/'}}, To 
    } | % {
        $script:rules[$_.From] = $_.To
    }
}

end { 
    #initial grid
    $grid = @(
        ".#."
        "..#"
        "###")


    if ($part -eq 1) {
        $iter = 5
    } else {
        $iter = 18
    }

    1..$iter | % {
        # how to split the grid, rules say check 2 first, otherwise do 3
        if ($grid.Count % 2 -eq 0) {
            $d = 2
        } else {
            $d = 3
        }
    
        # number of subgrids in a single dimension
        $m = $grid.Count / $d

        $newgrid = @()

        0..($m - 1) | % { # foreach row of subgrids
            $y = $_
            
            $row = ((, "") * ($d + 1)) # make an array of empty strings (and note, 2x2 -> 3x3, 3x3->4x4)

            0..($m - 1) | % { #foreach column in that row
                $x = $_
                
                # hahahahahahahahahahahahahahahaha
                # so, first time through on a say a 9x9, we need subgrid here to be the first 3x3 (from the top left)
                # to do that, we'll select the first 3 rows of grid, and for each of those rows select the first 3 columns (and join back into a string)
                # second time through, we need the top-middle grid.  x has incremented, so we'll select that subgrid this time
                $subgrid = ($grid[($y * $d)..($y * $d + ($d - 1))] | % {$_[($x * $d)..($x * $d + ($d - 1))] -join ''}) -join '/'
                
                # look up the new grid value.  $subgrid goes from being a string to being an array of rows
                $subgrid = $script:rules[$subgrid]
                
                #for each subgrid row, append it to the existing row in this row of subgrids
                0..$d | % {
                    $row[$_] += $subgrid[$_]
                }
            }

            #append the finished rows
            $newgrid += $row
        }

        # set to new grid
        $grid = $newgrid

        # put existing grid out on the pipeline (as array)
        , $grid
    } | select -last 1 | % { # pick the last grid on the pipeline
        # count the number of # characters
        $_ | % { $_ -split '' |? {$_ -eq '#'} | measure | select -expand count} | measure -sum | select -expand sum
    }
}