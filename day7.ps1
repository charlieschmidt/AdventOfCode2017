param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    $script:nodes = @()
}

process {
    $script:nodes += $in |? {
        $in -match '^(?<Name>[a-z]+) \((?<Weight>\d+)\)(?: -> ){0,1}(?<ChildNodeNames>(?:(?:[a-z]+)(?:, ){0,1})+)*$'
    } | % { 
        [pscustomobject]$matches
    } | select Name, Weight, ChildNodeNames | add-member -MemberType ScriptProperty -name ChildNodeNamesSplit -value {        
        $this.ChildNodeNames -split ", "
    } -passthru 
}

end { 
    write-verbose "Finding root node"
    $root = $script:nodes |? {
        $_.Name -notin ($script:nodes.ChildNodeNamesSplit)
    } | select -first 1
    
    write-verbose "$root"
    if ($part -eq 1) {
        $root.Name
    } else {
        $queue = new-object system.collections.queue
        $queue.Enqueue($root)
        $ordered = @()
        write-verbose "Ordering nodes"
        $i = 0
        while ($queue.Count -ne 0) {
            $ele = $queue.Dequeue()
            
            $ele | add-member -MemberType NoteProperty -name ChildNodes -value ($ele.ChildNodeNamesSplit | % {$cn = $_; $script:nodes |? {$_.Name -eq $cn}})
            write-verbose "ordered $($ele.name) $i"
            $i++
            $ordered += $ele
            $ele.ChildNodes | ? {$_} | % { $queue.Enqueue($_) }
        } 
        
        write-verbose "Reversing"
        [array]::Reverse($ordered)
        $i = 0
        write-verbose "Calculating subweights"
        $ordered | % { 
            $v = [int]$_.weight + [int]($_.ChildNodes.Subweight | Measure -sum | select -expand Sum)
            $_ | add-member -notepropertyname Subweight -notepropertyvalue $v

            write-verbose "subweight $($_.name) $($_.subweight)  $i"
            $i++
        }
        write-verbose "Finding unbalanced nodes"
        $script:nodes |? {
            ($_.ChildNodes.subweight | select -unique).count -gt 1
        } | select -first 1 | % {
            $g = $_.ChildNodes | group subweight | sort-object count
            $brokennode = $g[0].group[0]
            $offby = $brokennode.subweight - $g[1].group[0].Subweight
            $brokennode.weight - $offby
        }
    } 
}