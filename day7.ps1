param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    # collect input into a list
    $script:nodelist = @()
}

process {
    # collect input
    $script:nodelist += $in |? {
        $in -match '^(?<Name>[a-z]+) \((?<Weight>\d+)\)(?: -> ){0,1}(?<ChildNodeNamesString>(?:(?:[a-z]+)(?:, ){0,1})+)*$'
    } | % { 
        [pscustomobject]$matches # not fast, but easy and pipeable
    } | select Name, Weight, ChildNodeNamesString | add-member -MemberType ScriptProperty -name ChildNodeNames -value {        
        $this.ChildNodeNamesString -split ", "
    } -passthru 
    # node is a name/weight/childnodes
}

end {  
    #sorta cheating the single pipeline, but i need to reverse stuff in a pipeline :)
    function reverse { 
        $arr = @($input)
        [array]::reverse($arr)
        $arr
    }

    # faster lookup later, work with a hashtable from now on
    $script:nodes = new-object system.collections.hashtable
    $script:nodelist |% {$script:nodes[$_.Name] = $_}

    $root = $script:nodes.GetEnumerator() |? { # find the node that isnt a child of any other
        $_.Key -notin ($script:nodes.Values.ChildNodeNames)
    } | select -first 1 -expand value # only 1, help the pipeline end early and expand the object
    
    if ($part -eq 1) {
        $root.Name
    } else {
        # need to put the list of nodes in a workable order, so that we can iterate through and calcuate subweight
        $queue = new-object system.collections.queue

        # this is a modification of a breadth-first algorithm, where we'll load a queue with the root
        $queue.Enqueue($root)
        
        & { while ($queue.Count -ne 0) { # start inifinite pipeline, iterate til the queue is empty
            $queue.Dequeue() # pop the first element
        } } | % { 
            # find all the actual child node objects, add that as a property to the element and PASS IT THROUGH THE PIPELINE
            # this puts it out on the pipeline in the order we want
            $_ | add-member -MemberType NoteProperty -name ChildNodes -value ($_.ChildNodeNames | % {$script:nodes[$_]}) -passthru
            # add the childnodes to the queue
            $_.ChildNodes | ? {$_} | % { $queue.Enqueue($_) }
        } | Reverse | %{ # reverse the output from the ordering above - now the first elements in the pipeline are the leafs of the graph
            $_ | add-member -notepropertyname Subweight -notepropertyvalue ([int]$_.weight + [int]($_.ChildNodes.Subweight | Measure -sum | select -expand Sum)) -passthru  #calculate the subweight and pass the object on
        } |? {
            ($_.ChildNodes.subweight | select -unique).count -gt 1 # find the object that has too many unique subweights [they should all be the same]
        } | select -first 1 |% { # select the first (farthest into the graph) we find
            $g = $_.ChildNodes | group subweight | sort-object count # find the two different subweights, first element is the broken one
            $brokennode = $g[0].group[0]
            $offby = $brokennode.subweight - $g[1].group[0].Subweight # how many is it offby, 2nd element in the group is the good subweight
            $brokennode.weight - $offby # output the offby
        }
    } 
}