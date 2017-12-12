param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    # collect input into a hash
    $script:nodes = new-object system.collections.hashtable
}

process {
    # collect input
    $o = $in |? {
        $in -match '^(?<Name>[0-9]+) <-> (?<ChildNodeNamesString>(?:(?:[0-9]+)(?:, ){0,1})+)*$'
    } | % { 
        [pscustomobject]$matches | select Name, ChildNodeNamesString | add-member -MemberType ScriptProperty -name ChildNodeNames -value {        
            $this.ChildNodeNamesString -split ", "
        } -passthru 
    }

    $script:nodes[$o.name] = $o
}

end {  
    $queue = new-object system.collections.queue

    $queue.Enqueue($script:nodes["0"])
    $seen = @{}
    
    & { while ($queue.Count -ne 0) { # start generator pipeline, iterate til the queue is empty
        $queue.Dequeue() # pop the first element
    } } | % { 
        if ($null -eq $seen[$_.Name]) {
            $seen[$_.Name] = 1
            $_.Name | Write-Output
            $_ | add-member -MemberType NoteProperty -name ChildNodes -value ($_.ChildNodeNames | % {$script:nodes[$_]})
        
            $_.ChildNodes | ? {$_ -and $seen[$_.Name] -ne 1} | % { $queue.Enqueue($_) }
        }
    } | select -unique | measure | select -expand count
}