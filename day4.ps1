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
        , ($in -split " ") | ? { # convert the space separated string into a pipeable array, pipe to where
            $_.Count -eq ($_ | select -Unique).Count # array elements compared to unique array elements
        } | % { # pipe to foreach, will only be 0 or 1 pipeline iterations here
            $valid++
        }
    } else {
        , ($in -split " ") | ? {  # convert the space separated string into a pipeable array
            $_.Count -eq ($_ | % {($_.tochararray() | sort) -join '' } | select -unique).Count # array elements compared to unique sorted-characted array elements
        } | % {  # pipe to foreach, will only be 0 or 1 pipeline iterations here
            $valid++ 
        }
    }
}

end { 
    $valid
}