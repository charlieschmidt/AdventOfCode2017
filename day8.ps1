param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    # collect input into a hash
    $script:registers = new-object system.collections.hashtable
    $script:instructions = @()
    $conditions = @{
        "<" = "-lt"
        ">" = "-gt"
        "!=" = "-ne"
        "==" = "-eq"
        "<=" = "-le"
        ">=" = "-ge"
    }
    $operations = @{
        "inc" = "+"
        "dec" = "-"
    }
}

process {
    # collect input
    $o = $in |? {
        $in -match '^(?<Register>[a-z]+) (?<Operation>(?:dec|inc)) (?<Value>(?:-|[0-9])+) if (?<ConditionRegister>[a-z]+) (?<Condition>[!<>=]+) (?<ConditionValue>(?:-|[0-9])+)$'
    } | % { 
        [pscustomobject]$matches | select Register, Operation, Value, ConditionRegister, Condition, ConditionValue
    }

    $script:registers[$o.Register] = 0
    $script:instructions += $o
}

end {  
    $script:instructions |% {
        $s = '$script:registers["{0}"] {1} {2}' -f $_.ConditionRegister, $conditions[$_.Condition], $_.ConditionValue
        if ([ScriptBlock]::Create($s).Invoke()) {
            $s2 = '$script:registers["{0}"] = $script:registers["{0}"] {1} {2}' -f $_.Register, $operations[$_.Operation], $_.Value
            [ScriptBlock]::Create($s2).Invoke()
        }
    } 
    $script:registers.values | measure -max | select -expand Maximum
}