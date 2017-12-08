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
        $in -match '^(?<Name>[a-z]+) \((?<Weight>\d+)\)(?: -> ){0,1}(?<ChildNodeNamesString>(?:(?:[a-z]+)(?:, ){0,1})+)*$'
    } | % { 
        [pscustomobject]$matches | select Name, Weight, ChildNodeNamesString | add-member -MemberType ScriptProperty -name ChildNodeNames -value {        
            $this.ChildNodeNamesString -split ", "
        } -passthru 
    }

    $script:nodes[$o.name] = $o
}

end {  
    $root = $script:nodes.GetEnumerator() |? { # find the node that isnt a child of any other
        $_.Key -notin ($script:nodes.Values.ChildNodeNames)
    } | select -first 1 -expand value # only 1, help the pipeline end early and expand the object
    
    if ($part -eq 1) {
        $root.Name
    } else {
        # need to put the list of nodes in a workable order, so that we can iterate through and calcuate subweight
        $queue = new-object system.collections.queue

        # this is a modification of a breadth-first algorithm, where we'll load a queue with the root
        # loop til the queue is empty doing:
        #   pop the queue
        #   find childnodes of that element
        #   write out the element on the pipeline
        #   add them to the queue
        # pipeline on the outside now has the elements in the order we want (leaves first, root last)
        $queue.Enqueue($root)
        
        & { while ($queue.Count -ne 0) { # start generator pipeline, iterate til the queue is empty
            $queue.Dequeue() # pop the first element
        } } | % { 
            # find all the actual child node objects, add that as a property to the element and PASS IT THROUGH THE PIPELINE
            # this puts it out on the pipeline in the order we want
            $_ | add-member -MemberType NoteProperty -name ChildNodes -value ($_.ChildNodeNames | % {$script:nodes[$_]}) -passthru
            # add the childnodes to the queue
            $_.ChildNodes | ? {$_} | % { $queue.Enqueue($_) }
        } | % { 
            # reverse the output from the ordering above - now the first elements in the pipeline are the leaves of the graph and the last element is the root
            # thanks /u/ka-splam for suggestion
                $global:rev = @() 
        } { 
                $global:rev = @($_) + $rev 
        } { 
                $global:rev 
        } | %{ 
            # we can add subweight here at the same time we reference it on childnodes because we've ordered the list so that children always come before their parents
            $_ | add-member -notepropertyname Subweight -notepropertyvalue ([int]$_.weight + [int]($_.ChildNodes.Subweight | Measure -sum | select -expand Sum)) -passthru  #calculate the subweight and pass the object on
        } |? {
            ($_.ChildNodes.subweight | select -unique).count -gt 1 # find the object that has too many unique subweights [they should all be the same]
        } | select -first 1 |% { # select the first (farthest/highest leaf into the graph) we find
            $g = $_.ChildNodes | group subweight | sort-object count # find the two different subweights, first element is the broken one
            # balanced weight = its weight minus the difference in the subweights
            $g[0].group[0].weight - ($g[0].group[0].subweight - $g[1].group[0].Subweight)
        }
    } 
}