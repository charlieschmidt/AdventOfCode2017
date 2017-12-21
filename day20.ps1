param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$in,
    [Parameter(Position = 1)]
    [int]$part = 1
)

begin {
    $script:particles = @() # hold all the particles
    $script:i = 0 #particle name
}

process {
    $script:particles += $in |? {
        #parse the particle string
        $_ -match '^p=<(?<PX>[ -]?\d+),(?<PY>[ -]?\d+),(?<PZ>[ -]?\d+)>, v=<(?<VX>[ -]?\d+),(?<VY>[ -]?\d+),(?<VZ>[ -]?\d+)>, a=<(?<AX>[ -]?\d+),(?<AY>[ -]?\d+),(?<AZ>[ -]?\d+)>$'
    } | % { 
        #convert to a psobject, add a Name and Status property
        [pscustomobject]$matches | select @{n = "Name"; e = {$script:i}}, PX, PY, PZ, VX, VY, VZ, AX, AY, AZ, @{n = "Status"; e = {1}}
    } | % {
        #convert all property types to integers (powershell regex will default to them as strings during the conversions above)
        $_.PSObject.Properties | % {$_.Value = [int]$_.Value}

        # increment name
        $script:i++

        # add a method to perform a step on this particle
        $_ | Add-Member -MemberType ScriptMethod -Name Step -Value {
            $this.vx += $this.ax
            $this.px += $this.vx
            $this.vy += $this.ay
            $this.py += $this.vy
            $this.vz += $this.az
            $this.pz += $this.vz
        }

        # add a property representing the current manhattan distance from 0,0,0
        $_ | Add-Member -MemberType ScriptProperty -Name D -Value {
            [Math]::Abs($this.PX) + [Math]::Abs($this.PY) + [Math]::Abs($this.PZ)
        }

        # acceleration as manhattan distance [this is static, since A* dont change with each step]
        $_ | Add-Member -MemberType ScriptProperty -Name AM -Value {
            [Math]::Abs($this.AX) + [Math]::Abs($this.AY) + [Math]::Abs($this.AZ)
        }

        # vel as manhattan distance [this isn't static, as V* change by A* each step, but is still needed for sorting in part1 to differentiate between particles with the same accel]
        $_ | Add-Member -MemberType ScriptProperty -Name VM -Value {
            [Math]::Abs($this.VX) + [Math]::Abs($this.VY) + [Math]::Abs($this.VZ)
        }

        # current position as comparable string
        $_ | Add-Member -MemberType ScriptProperty -Name P -Value {
            $this.PX,$this.PY,$this.PZ -join ","
        }

        $_ # back on the pipeline to go into $script:particles
    }
}
        

end {
    1..1000 | % { #for some silly max number of steps (we wont perform this many steps, just an upper bound)
        $script:particles | % { # step each particle
            $_.Step()
        }

        if ($part -eq 1) {
            # sorta cheating, since we only need 1 iteration to find this, but to keep with the single pipeline idea
            # this sorts the partciles by manhattan acceleration ascending then manhattan velocity ascending and selects the first one
            # the particle with the "slowest" manhattan acceleration will be the one that is closest to the origin the long term
            # any with the same manhattan acceleration - the one with the "slowest" [initial, but it changes linerally after that so its ok] manhattan velocity will be slowest/closest in the long term
            # so put the name out on the pipeline
            $script:particles | sort AM, VM | select -first 1 -expand Name 
        } else {
            # resolve collisions
            $script:particles |? {      # foreach particle
                $_.Status -eq 1         # that is still alive
            } | group P |? {            # group those by position.  # NOTE: this also 'stalls' the pipeline, group will collect the entire entry pipeline before outputting anything, so we can set Status later in this pipeline without affecting the where clause above
                $_.Count -gt 1          # select only groups that have more than 1 particle in them (a collision)
            } | % {                     # for each of those groups
                $_.Group | % {          # for each of the particles in that group
                    $_.Status = 0       # set it to dead
                }
            }

            # count the partciles still alive and put that number out on the pipeline
            $script:particles |? {
                $_.Status -eq 1
            } | measure | select -expand count
        }
    } | % -Begin { 
        # ok now we do something "clever" and basically wait for the numbers coming in on the pipeline here to 'not change' for a certain number of steps
        # the idea being, that after some limited number of steps, the "answer" wont change any longer.
        # in part1, the answer /never/ changes, so this isn't needed, but still gets applied
        # in part2, the answer is the number of surviving particles - so what we're doing is iterating until it "looks like" all collisions have been resolved an no more
        # will happen.

        # create a queue at the start of this pipeline
        $script:rolling = new-object system.collections.queue 
    } -Process { # foreach element into the pipeline (element = potential answer)
        $script:rolling.Enqueue($_) # add it to the queue
        if ($script:rolling.Count -eq 16) {
            # if we have 16 potential answers, the most recent 16 answers
            [void]$script:rolling.Dequeue() # remove one, so we'll compare the last 15
            if (($script:rolling | select -Unique | measure).count -eq 1) {
                # see how many distinct answers there are, if 1 - then we've "settled" on the solution, otherwise keep processing
                $_ | write-output
            }
        }
    } | select -first 1 # select the first thing out of the foreach/rolling thing above, so that it stops and the initial 0..1000 stops
}
