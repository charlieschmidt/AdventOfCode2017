param (
    [Parameter(ValueFromPipeline=$true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

process 
{
    $offset = 1
    if ($part -eq 2) {
        $offset = $in.length / 2
    }

    0..$in.length |? { # iterate the string indexes, pipe to where
        $in[$_] -eq $in[($_ + $offset) % $in.length] # value at index is equal to value at index + offset (modulo length to wrap around)
    } | % { # foreach from the where
        [string]$in[$_] # output the value at that index (cast to string so the integer cast later isnt performed on a char)
    } | measure -sum | select -expand sum # sum them up
}