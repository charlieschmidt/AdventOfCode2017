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
        (0..3 | % {[pscustomobject]@{low = $lrc - $length + 1; hi = $lrc}; $llc -= ($length - 1)} |? {$_.low -lt $in -and $in -le $_.hi} | select @{n = "a"; e = {$halflength + [math]::max($halflength - ($_.hi - $in), $halflength - ($in - $_.low))}}).a
    } else {
        $grid = @{}

        $x = 0
        $y = 0
        $grid["$x,$y"] = 1
        
        $max = 1
        
        1..10 | % { 
            1..$_ | % {
                $x++
                $r = $grid["$($x-1),$($y-1)"] + `
                    $grid["$($x-1),$($y)"] + `
                    $grid["$($x-1),$($y+1)"] + `
                    $grid["$($x),$($y-1)"] + `
                    $grid["$($x),$($y+1)"] + `
                    $grid["$($x+1),$($y-1)"] + `
                    $grid["$($x+1),$($y)"] + `
                    $grid["$($x+1),$($y+1)"] 
                if ($r -gt $in) {
                    write-output $r
                    break
                }
                $grid["$x,$y"] = $r
                #write-output "$x,$y = $r"
            }
            1..$_ | % {
                $y++
                $r = $grid["$($x-1),$($y-1)"] + `
                    $grid["$($x-1),$($y)"] + `
                    $grid["$($x-1),$($y+1)"] + `
                    $grid["$($x),$($y-1)"] + `
                    $grid["$($x),$($y+1)"] + `
                    $grid["$($x+1),$($y-1)"] + `
                    $grid["$($x+1),$($y)"] + `
                    $grid["$($x+1),$($y+1)"] 
                if ($r -gt $in) {
                    write-output $r
                    break
                }
                $grid["$x,$y"] = $r
                #write-output "$x,$y = $r"
            }
            $max++

            1..$_ | % {
                $x--
                $r = $grid["$($x-1),$($y-1)"] + `
                    $grid["$($x-1),$($y)"] + `
                    $grid["$($x-1),$($y+1)"] + `
                    $grid["$($x),$($y-1)"] + `
                    $grid["$($x),$($y+1)"] + `
                    $grid["$($x+1),$($y-1)"] + `
                    $grid["$($x+1),$($y)"] + `
                    $grid["$($x+1),$($y+1)"] 
                if ($r -gt $in) {
                    write-output $r
                    break
                }
                $grid["$x,$y"] = $r
                #write-output "$x,$y = $r"
            }

            foreach ($i in 1..$max) {
                $y--
                $r = $grid["$($x-1),$($y-1)"] + `
                    $grid["$($x-1),$($y)"] + `
                    $grid["$($x-1),$($y+1)"] + `
                    $grid["$($x),$($y-1)"] + `
                    $grid["$($x),$($y+1)"] + `
                    $grid["$($x+1),$($y-1)"] + `
                    $grid["$($x+1),$($y)"] + `
                    $grid["$($x+1),$($y+1)"] 
                if ($r -gt $in) {
                    write-output $r
                    break
                }
                $grid["$x,$y"] = $r
                #write-output "$x,$y = $r"
            }

            $max++
        }
        
    }
    
}

end { 

}