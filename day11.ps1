param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
}

process {
    # set initial coords
    $x = 0
    $y = 0
    $z = 0

    $in -split ',' | % { # foreach movement
        switch ($_) { # cube coord logic from: https://www.redblobgames.com/grids/hexagons/#coordinates-cube
            "n" {
                $y++
                $z--
            }
            "ne" {
                $z--
                $x++
            }
            "nw" {
                $y++
                $x--
            }
            "s" {
                $y--
                $z++
            }
            "se" {
                $y--
                $x++
            }
            "sw" {
                $x--
                $z++
            }
        }

        ([math]::Abs($x) + [math]::Abs($y) + [math]::Abs($z)) / 2 | write-output # current distance from center: https://www.redblobgames.com/grids/hexagons/#distances-cube

    } | tee-object -variable d | select -last 1 | % {  # tee the output (all the distances) to a pipeline and a collecting variable 'd';  in the pipeline select the last element
        if ($part -eq 1) {
            $_ # output that element (last/final distance)
        } else {
            $d | measure -max | select -expand maximum # output the max distance, which have been accumulating in $d via tee-object
        }
    }
}

end {
}