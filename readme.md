## Advent Of Code 2017 in powershell restricted to single pipelines wherever possible*

### to run any day:

    ./Invoke-AOCDay.ps1 -Day $Day -Part $Part

### tips/tricks so far:

#### infinite pipeline generator: (day 3 and day 5)

    & { while (<condition>) { <output-element> } } | 

either pipe to select to get your way out of it, or change the condition to something that will evaluate.  the elements coming out can be dynamic too

#### array cross product (day 2)
    $array |% {$a = $_; $array |% {$_, $x}} 

#### array operator

    , ($value -split ' ') |

will send a single value to the pipeline - an array of the elements

#### in-pipeline reverse array elements

    |% { 
        $script:rev = @() 
    } { 
        $script:rev = @($_) + $script:rev 
    } { 
        $script:rev 
    } | 

#### regex match groups to psobject

    $in |? {
        $_ -match '^(?<Name>[0-9]+) <-> (?<ChildNodeNamesString>(?:(?:[0-9]+)(?:, ){0,1})+)*$'
    } |% { 
        [pscustomobject]$matches | select Name, ChildNodeNamesString
    } | 

#### generate array of empty strings

    $array_with_x_items = (, "") * $x

#### wait for pipeline values to stop changing

    $script:StopAfterXSame = 15 # if we've seen this many elements in a row that are the same, stop the pipeline

    {
        ... | write-output # some output that may change initially but steady eventually
    } | % -Begin { 
        # wait for the values coming in on the pipeline here to 'not change' for a certain number of steps

        # create a queue at the start of this pipeline
        $script:rolling = new-object system.collections.queue 

    } -Process { # foreach element into the pipeline

        #add it to the queue
        $script:rolling.Enqueue($_)

        if ($script:rolling.Count -eq ($script:StopAfterXSame + 1)) {
            # the most recent answers
            [void]$script:rolling.Dequeue() # remove one, so we'll compare the last $X

            if (($script:rolling | select -Unique | measure).count -eq 1) {
                # see how many distinct answers there are, if 1 - then we've "settled" on the solution, otherwise keep processing
                $_ | write-output
            }
        }
    } | select -first 1 # select the first thing out of the foreach/rolling thing above

###### *I am allowing that the ./dayX.ps1 scripts are function scripts that take pipeline input - this allows for a nicer begin/process/end structure when needed and gives me the sort-of-flexibility of two pipelines, but all the algorithm work will (hopefully) be done in one
