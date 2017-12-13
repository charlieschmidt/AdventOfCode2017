param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    # collect input
    $script:layers = @()

    if ($part -eq 1) {
        $script:property = "sum" # property to pull at the end
    } else {
        $script:property = "delay" # property to pull at the end
    }
}

process {
    # parse input
    $script:layers += , ($in -split ': ') | % {
        [pscustomobject]@{
            Layer  = [int]$_[0]
            Depth  = [int]$_[1]
            Offset = [int](($_[1] - 1) * 2) # precalculate to make it faster later
        }
    }    
}

end {  
    #3946830..4000000 |% { # cause its slow as hell :)
    0..4000000 |% { #seconds delay
        $d = $_
        $script:layers |? { 
            ($_.Layer + $d) % $_.Offset -eq 0 # if layer is a hit
        } | % { # foreach hit
            $_.Depth * $_.Layer #calculate severity
        } | measure -sum | select Count, Sum, @{n = "Delay"; e = {$d}} # sum severity, pass through count of layers hit, sum of severity, and delay
    } |? {
        $part -eq 1 -or ($part -eq 2 -and $_.count -eq 0) # if part 1, pass through (sum property), if part2 - only pass through when there are no layer hits from the previous block (delay property)
    } | select -first 1 -expand $script:property # select & expand property, select first 1 so that we end the delay pipeline at the start
}