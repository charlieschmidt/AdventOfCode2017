    param (
        [Parameter(ValueFromPipeline = $true)]
        [int]$in,
        [Parameter(Position = 1)]
        [int]$part = 1
    )

    begin {
    }

    process {
        if ($part -eq 1) {
            $length = [Math]::Ceiling([Math]::Sqrt($in))
            $halflength = ($length / 2) - .5
            $lrc = $length * $length
            (0..3 | % {[pscustomobject]@{low = $lrc - $length + 1; hi = $lrc}; $lrc -= ($length - 1)} |? {$_.low -lt $in -and $in -le $_.hi} | select @{n = "a"; e = {$halflength + [math]::max($halflength - ($_.hi - $in), $halflength - ($in - $_.low))}}).a
        } else {
            $global:x = 0
            $global:y = 0
            $global:grid = @{}
            $global:grid["$x,$y"] = 1
            
            $sg = {
                $grid["$x,$y"] = @($x - 1; $x; $x + 1) | % {
                        $ax = $_
                        @($y - 1; $y; $y + 1) | % {
                            $grid["$($ax),$($_)"]
                        } 
                    } | measure -sum | select -expand sum
                $grid["$x,$y"]
            }
            $sbs = @( {$global:x++}, {$global:y++})
            $sbs2 = @( {$global:x--}, {$global:y--})
            
            $maxsidelength = 10
            $l = 1
            0..($maxsidelength / 2) | % {
                $sbs | % { $f = $_; 1..$l | % { &$f; &$sg } }
                $l++
                $sbs2 | % { $f = $_; 1..$l | % { &$f; &$sg } }
                $l++
            } | ? { $_ -gt $in} | select -first 1
            
        }
        
    }

    end { 

    }