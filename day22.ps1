    param (
        [Parameter(ValueFromPipeline = $true)]
        [string]$in,
        [Parameter(Position = 1)]
        [int]$part = 1
    )

    begin {
        $script:grid = @{}
        $script:row = 0
    }

    process {
        # load the lines into the grid hash, keys are "#x#", values the cell state
        # top left of input is 0,0, but we compute center for starting later
        $x = 0
        $in -split '' |? {$_} | % {
            $script:grid["{0}x{1}" -f $x, $script:row] = $_
            $x++
        }
        $script:row++
    }

    end {
        $x = $y = ($script:row-1) / 2 # current location to center
        $d = 0 # direction, 0 - up, 1 - right, 2 - down, 3 - left

        if ($part -eq 1) {
            $bursts = 10000
        } else {
            $bursts = 10000000
        }

        1..$bursts | % {
            $c = "{0}x{1}" -f $x, $y # format coordinate key

            if ($part -eq 1) {
                switch ($script:grid[$c]) {
                    $null {
                        $d = ($d + 3) % 4 # turn left
                        $script:grid[$c] = '#'
                        1
                    }
                    '.' {
                        $d = ($d + 3) % 4 # turn left
                        $script:grid[$c] = '#'
                        1
                    }
                    '#' {
                        $d = ($d + 1) % 4 # turn right
                        $script:grid[$c] = '.'
                    }
                }
            } else {
                switch ($script:grid[$c]) {
                    $null {
                        $d = ($d + 3) % 4 # turn left
                        $script:grid[$c] = 'W'
                    }
                    '.' {
                        $d = ($d + 3) % 4 # turn left
                        $script:grid[$c] = 'W'
                    }
                    'W' {
                        # no turn
                        $script:grid[$c] = '#'
                        1
                    }
                    '#' {
                        $d = ($d + 1) % 4 # turn right
                        $script:grid[$c] = 'F'
                    }
                    'F' {
                        $d = ($d + 2) % 4 # turn around
                        $script:grid[$c] = '.'
                    }
                }
            }

            switch ($d) {
                0 { $y-- }
                1 { $x++ }
                2 { $y++ }
                3 { $x-- }
            }
            
        } | measure | select -expand count
    }