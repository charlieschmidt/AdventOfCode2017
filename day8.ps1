param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    $script:registers = new-object system.collections.hashtable 

    $script:maxes = @() # keep track of max registers per step for part 2
    
    $conditions = @{ # map to beautiful powershell
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
    $script:maxes += $in |? {
        $_ -match '^(?<Register>[a-z]+) (?<Operation>(?:dec|inc)) (?<Value>(?:-|[0-9])+) if (?<ConditionRegister>[a-z]+) (?<Condition>[!<>=]+) (?<ConditionValue>(?:-|[0-9])+)$'
    } | % { 
        [pscustomobject]$matches | select Register, Operation, Value, ConditionRegister, Condition, ConditionValue
    } |% {# now have a pretty object on the pipeline representing a single instruction, foreach of these...

        # initialize any registers that aren't already
        $InitRegisterSb = 'if ($script:registers.ContainsKey("{0}") -eq $false) {{$script:registers["{0}"] = 0}}'
        [ScriptBlock]::Create(($InitRegisterSb -f $_.ConditionRegister)).Invoke()
        [ScriptBlock]::Create(($InitRegisterSb -f $_.Register)).Invoke()
            
        # perform instruction
        $s = 'if ($script:registers["{0}"] {1} {2}) {{ $script:registers["{3}"] = $script:registers["{3}"] {4} {5} }} else {{ $false }} ' -f $_.ConditionRegister, $conditions[$_.Condition], $_.ConditionValue, $_.Register, $operations[$_.Operation], $_.Value
        [ScriptBlock]::Create($s).Invoke()
        
        # select new maximum in the registers
        $script:registers.values | measure -max | select -expand Maximum    
    }
}

end {  
    if ($part -eq 1) {
        $script:registers.values | measure -max | select -expand Maximum # max register value at end of instructions
    } else {
        $script:maxes | measure -max | select -expand maximum # max reigster value ever seen
    }
}