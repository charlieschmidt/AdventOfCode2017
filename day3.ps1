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
        $length = [Math]::Ceiling([Math]::Sqrt($in)) # get a potential max side length (using the lower right corner as odd squares)
        $halflength = [Math]::Floor($length / 2)  # get the half length (potential max distance away from center cell)
        $lrc = $length * $length # get the lower right corner
        (0..3 | % { # for all 4 sides
                [pscustomobject]@{low = $lrc - $length + 1; hi = $lrc}; $lrc -= ($length - 1) # make an object that has the bounds for that side
            } |? { # where
                $_.low -lt $in -and $in -le $_.hi # the number we are looking for is between the bounds - now we know which side our value is on
           } | select @{n = "a"; e = {$halflength + [math]::max($halflength - ($_.hi - $in), $halflength - ($in - $_.low))}} # select an answer
            <#
            the answer is the original halflength (out to this layer in the sides) 
            plus the offset from the corner (which is another halflength away, minus how far *our* number is towards that corner

            Corner        center            Corner
            A---------------*-------X-------B
            <--halflength-->
            the offset is the distance from * to X, but we dont know if X is closer to A or B right away
                if we knew the closer one - C, then dist(*,X) is halflength-dist(X,C)
                halflength is constant now, so the -1 on dist(X,C) reverses closer to farther,
                so we pick max of (hl - dist(A,X), hl - dist(B,X)
            #>
            ).a
        } else {
            # set up some global variables, and tag them global cause we'll use scriptblocks later
            $global:x = 0
            $global:y = 0
            $global:grid = @{}
            $global:grid["$x,$y"] = 1
        
            # set-grid-value scriptblock
            $sg = {
                $grid["$x,$y"] = @($x - 1; $x; $x + 1) | % {
                    $ax = $_
                    @($y - 1; $y; $y + 1) | % {
                        $grid["$($ax),$($_)"]
                    } 
                } | measure -sum | select -expand sum
                $grid["$x,$y"]
            }
            # side navigation scriptblocks
            $sbs = @( {$global:x++}, {$global:y++})
            $sbs2 = @( {$global:x--}, {$global:y--})
        
            # layer to draw 
            $l = 1

            & { while ($true) { $true } } | % { # infinite pipeline constructor
                $sbs | % { # foreach of the first two side navigators
                    $f = $_
                    1..$l | % { # from 1 to the layer length
                        &$f # execute the side navigator
                        &$sg # set grid value and put it out on the pipeline
                    } 
                }
                $l++ # increment layer
                $sbs2 | % { $f = $_; 1..$l | % { &$f; &$sg } }
                $l++
            } | ? { # where (input to this is the output from the $sg function being called inside above)
                $_ -gt $in # grid value is greater than the input
            } | select -first 1 # select the first one and end the infinite pipeline
        
        
        }
    
}

end { 

}