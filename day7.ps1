param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    $nodes = @()
}

process {
    $nodes += $in |? {
        $in -match '^(?<Node>[a-z]+) \((?<Weight>\d+)\)(?: -> ){0,1}(?<ChildNodes>(?:(?:[a-z]+)(?:, ){0,1})+)*$'
    } | % { 
        [pscustomobject]$matches
    } | select Node, Weight, @{n = "Children"; e= {$_.ChildNodes -split ", "}}
}

end { 
    $nodes |? {
        $_.Node -notin ($nodes.Children)
    } | select -expand node
}