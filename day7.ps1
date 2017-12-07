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
        $in -match '^(?<Name>[a-z]+) \((?<Weight>\d+)\)(?: -> ){0,1}(?<ChildNodes>(?:(?:[a-z]+)(?:, ){0,1})+)*$'
    } | % { 
        [pscustomobject]$matches
    } | select Name, Weight, ChildNodes | add-member -MemberType ScriptProperty -name ChildNodeNames -value {        
        $this.ChildNodes -split ", "
    } -passthru | add-member -MemberType ScriptProperty -name Children -value {
        $this.ChildNodeNames | % {$cn = $_; $script:nodes |? {$_.Name -eq $cn}}
    } -passthru | add-member -MemberType ScriptProperty -name Parent -value {
        $script:nodes |? {$_.ChildNodeNames -contains $this.Name}
    } -PassThru -Force | add-member  -MemberType ScriptProperty -name Subweight -value {
        if ($null -eq $this.Children) {
            [int]$this.Weight
        } elseif ($null -ne $this.SubweightValue) {
            [int]$this.SubweightValue
        } else {
            [int]$this.Weight + [int]($this.Children | % {$_.Subweight} | measure -sum | select -expand sum)
        }
        #
    } -PassThru -Force
    
}

end { 
    #need bfs probably, or convert array to graph and graph logic, ugh?
    if ($part -eq 1) {
        $script:nodes |? {
            $_.Name -notin ($script:nodes.ChildNodeNames)
        } | select -expand Name
    } else {
        $script:nodes| add-member -MemberType ScriptProperty -name Depth -value {
            if ($null -eq $this.Parent) {
                0
            } else {
                1 + [int]$this.Parent.Depth
            }
        } -passthru
        <*
        write-host 'here'
        $script:nodes |? { 
            $null -ne $_.ChildNodes
        } | % {
            $_ | Add-Member -NotePropertyName "SubweightValue" -NotePropertyValue ($_.Subweight) -PassThru
        }| % {
            write-verbose ("{0} has {1} nodes and {2} sw" -f $_.name, $_.childnodenames.count, $_.subweightvalue)
            $_
        } | ? {
            write-verbose ("{0} has {1} nodes and {2} sw {3}" -f $_.name, $_.childnodenames.count, $_.subweightvalue, (($_.Children.SubweightValue | select -unique) -join ','))
            #$_
            ($_.Children.SubweightValue | select -unique | measure | select -expand count) -ne 1
        } |% {
            $_
        } #|% { $_ }#>
            <#| % {
            $g = $_.children | group subweight | sort count
            $g
            $brokennode = $g[0].group[0]
            $brokennode
            $offby = $brokennode.subweight - $g[1].group[0].Subweight
            $offby
            $brokennode.weight - $offby
        }#>

            <#
        $nodes | select *, @{n = "Subweight"; e = {
                $me = $_
                $_.Weight + ($me.children | % {$cn = $_; $nodes |? {$_.node -eq $cn} | select -expand subweight | measure -sum | select -expand sum})
            }
        }#>
        
        }
}