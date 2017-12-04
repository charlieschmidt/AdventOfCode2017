param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    $valid = 0
}

process {
    if ($part -eq 1) {
        $in | ? {$words = $_ -split " "; $words.Count -eq ($words | select -Unique).Count} | % { $valid++ }
    } else {
        $in | ? {$words = $_ -split " " | % { ($_.tochararray() | sort) -join '' } ; $words.Count -eq ($words | select -Unique).Count} | % { $valid++}        
    }
}

end { 
    $valid
}