## Advent Of Code 2017 in powershell restricted to single pipelines wherever possible*

### to run any day:

    ./Invoke-AOCDay.ps1 -Day $Day -Part $Part

### tips/tricks so far:

#### infinite pipeline generator: (day 3 and day 5)

    & { while ($true) { $true } } | 

either pipe to select to get your way out of it, or change the condition to something that will evaluate.  the elements coming out can be dynamic too

#### array cross product (day 2)
    $array |%{$a = $_; $array |% {$_,$x}} 

#### array operator

    , ($value -split ' ') |

will send a single value to the pipeline - an array of the elements

###### *I am allowing that the ./dayX.ps1 scripts are function scripts that take pipeline input - this allows for a nicer begin/process/end structure when needed and gives me the sort-of-flexibility of two pipelines, but all the algorithm work will (hopefully) be done in one
