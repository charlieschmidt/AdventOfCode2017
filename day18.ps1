param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    # program instructions
    $script:p = @()

    # initial registers for both programs
    $script:registers = @(
        @{"p" = [long]0}
        @{"p" = [long]1}         
    )

    #totally cheating, but saves me a stupid check & init later
    @("a", "b", "f", "i") |% {
        $script:registers[0][$_] = [long]0
        $script:registers[1][$_] = [long]0
    }
}

process {
    #collect instructions
    $script:p += $in
}

end {
    #current program position
    $positions = @(0, 0)
    #program rcv queues
    $queues = @(
        new-object system.collections.queue
        new-object system.collections.queue
    )
    #program waiting
    $waiting = @($false,$false)
    
    #part 1, what was sent last
    $snd = $null
    #part 2, how many snd commands
    $sends = @(0,0)

    & { while ($true) { 
        $true
    } } | % {
        0..1 | % { # for each program
            $program = $_
            
            switch -regex ($script:p[$positions[$program]]) { #get instruction at this program's position in the instructionlist
                '^set (?<Register>[a-z]) (?<Value>[a-z])$' {
                    $script:registers[$program][$matches.Register] = $script:registers[$program][$matches.Value]
                }
                '^set (?<Register>[a-z]) (?<Value>-?\d+)$' {
                    $script:registers[$program][$matches.Register] = [int]$matches.Value
                }
                '^add (?<Register>[a-z]) (?<Value>[a-z])$' {
                    $script:registers[$program][$matches.Register] += $script:registers[$program][$matches.Value]
                }
                '^add (?<Register>[a-z]) (?<Value>-?\d+)$' {
                    $script:registers[$program][$matches.Register] += [int]$matches.Value
                }
                '^mul (?<Register>[a-z]) (?<Value>[a-z])$' {
                    $script:registers[$program][$matches.Register] *= $script:registers[$program][$matches.Value]
                }
                '^mul (?<Register>[a-z]) (?<Value>-?\d+)$' {  
                    $script:registers[$program][$matches.Register] *= [int]$matches.Value
                }
                '^mod (?<Register>[a-z]) (?<Value>[a-z])$' {
                    $script:registers[$program][$matches.Register] = $script:registers[$program][$matches.Register] % $script:registers[$program][$matches.Value]
                }
                '^mod (?<Register>[a-z]) (?<Value>-?\d+)$' {
                    $script:registers[$program][$matches.Register] = $script:registers[$program][$matches.Register] % [int]$matches.Value
                }
                '^jgz (?<Register>[a-z]) (?<Offset>[a-z])$' {
                    if ($script:registers[$program][$matches.Register] -gt 0) {
                        $positions[$program] += $script:registers[$program][$matches.Offset]
                        #backtrack one for increment later
                        $positions[$program]--
                    }
                }
                '^jgz (?<Register>[a-z]) (?<Offset>-?\d+)$' {
                    if ($script:registers[$program][$matches.Register] -gt 0) {
                        $positions[$program] += $matches.Offset
                        #backtrack one for increment later
                        $positions[$program]--
                    }
                }
                '^jgz (?<Value>-?\d+) (?<Offset>[a-z])$' {
                    if ($matches.Value -gt 0) {
                        $positions[$program] += $script:registers[$program][$matches.Offset]
                        #backtrack one for increment later
                        $positions[$program]--
                    }
                }
                '^jgz (?<Value>-?\d+) (?<Offset>-?\d+)$' {
                    if ($matches.Value -gt 0) {
                        $positions[$program] += $matches.Offset
                        #backtrack one for increment later
                        $positions[$program]--
                    }
                }
                '^snd (?<Register>[a-z])$' {
                    if ($part -eq 1) {
                        #keep track of last sent
                        $snd = $script:registers[$program][$matches.Register]
                    } else {
                        #keep track of how many sends from each program
                        $sends[$program]++
                        #put data in /other/ program's queue
                        $queues[($program + 1) % 2].Enqueue($script:registers[$program][$matches.Register])
                    }
                }
                '^snd (?<Value>-?\d+)$' {
                    if ($part -eq 1) {
                        #keep track of last sent
                        $snd = $matches.Value
                    } else {
                        #keep track of how many sends from each program
                        $sends[$program]++
                        #put data in /other/ program's queue
                        $queues[($program + 1) % 2].Enqueue($matches.Value)
                    }
                }
                '^rcv (?<Register>[a-z])$' {
                    if ($part -eq 1) {
                        #if part 1, keep track of first nonzero receive command, write out last sent - pipeline ends after this
                        if ($script:registers[$program][$matches.Register] -ne 0) {
                            $snd # PIPELINE OUTPUT
                        }
                    } else {
                        #if part2,  
                        if ($queues[$program].Count -gt 0) { #receive from the queue if possible,
                            $script:registers[$program][$matches.Register] = $queues[$program].Dequeue()
                            #set no longer waiting
                            $waiting[$program] = $false
                        } else { #else set waiting
                            $waiting[$program] = $true
                            if ($waiting[($program + 1) % 2] -eq $true) {
                                #but if the other program is also waiting, then we're deadlocked, so write out part2's answer (sends by program 1)
                                $sends[1] # PIPELINE OUTPUT
                            }
                            # backtrack for position increment
                            $positions[$program]--
                        }
                    }
                }
            }
            # advance program position
            $positions[$program]++
        }
    } | select -first 1
}
