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
    # keep track of nodes we've visted
    $seen = @{}
    
    $script:nodes.keys |? { # where node
        ($part -eq 1 -and $_ -eq 0) -or ($part -eq 2)   # if part one, only select node 0, otherwise select all nodes
    } |? { 
        $null -eq $seen[$_] # where we havn't seen this node before
    } |% { # foreach
        # create a new bfs-style queue for visiting the nodes and collecting the group for this node ($_)
        $queue = new-object system.collections.queue
        $queue.Enqueue($script:nodes[$_]) # start at this node
        
        #note the ,() construct, so the stuff that comes out of this is an array, and this is the line that puts out to the rest of the pipe
        ,(& { while ($queue.Count -ne 0) { # start generator pipeline, iterate til the queue is empty
            $queue.Dequeue() # pop the first element
        } } |? { 
            $null -eq $seen[$_.Name] # where we havn't seen this node before
        } |% {
            $_.Name | Write-Output # put the name out, since its part of this group

            $seen[$_.Name] = 1 # mark seen
        
            # foreach child node, add it to the queue to visit
            $_.ChildNodeNames |? {$_} |% {$script:nodes[$_]} |% { $queue.Enqueue($_) }
        } | sort) # stuff that comes out is are nodes in a single group, sort them
    } |% { #foreach - part1 there is only 1 object (the group, represented as an array);  part2 there are many objects (groups, each as an array)
        if ($part -eq 1) { # if part1, there is only 1 group here, so put *its* elements out individually to be counted
            $_ 
        } else { # if part 2, there are many groups and we want to know how many, so put the incoming back out an array so we just count the number of arrays
            ,$_
        }
    } | measure | select -expand count # select the count of groups or elements
}