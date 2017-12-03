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

    0..$in.length |? {$in[$_] -eq $in[($_ + $offset) % $in.length]} | % {[string]$in[$_]} | measure -sum | select -expand sum
}