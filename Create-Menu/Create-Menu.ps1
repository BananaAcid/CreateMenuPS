Function New-SelectionMenu {
    <#
        .SYNOPSIS
            Shows strings as a table to be selectable by navigating with arrow keys
    
        .DESCRIPTION
            Author: Nabil Redmann (BananaAcid)
            License: ISC
    
        .INPUTS
            array of strings
    
        .PARAMETER MenuOptions
            Value: <String[]>
            
            Takes an array with selections (must be more then one)
        .PARAMETER Title
            Value: <Null|ScriptBlock|String>

            Takes a string or a scriptblock, use $global:varname to link to Title, Footer or SelectionCallback (available vars: $Selection, $SelectionValue, $MenuOptions, $MenuOptionsInput, $esc, $CL, $global:*)
        .PARAMETER Selected
            Value: <Null|Integer>

            Initial string to select
        .PARAMETER Footer
            Value: <Null|ScriptBlock|String>

            Takes a string or a scriptblock (available vars: $Selection, $SelectionValue, $MenuOptions, $MenuOptionsInput, $esc, $CL, $global:*) 
        .PARAMETER SelectionCallback
            Value: <Null|ScriptBlock>

            If you want to trigger something on selection or a key, or change the $MenuOptions/$Selection, return $False to exit 
    
            # params in: $Selection, $SelectionValue, $MenuOptions, $MenuOptionsInput, $KeyInput, $esc (char 27, ansi seq. start), $CL (ansicode to clear to end of line)
            # return: $False to end, or array of new options and triggers re-calculation of the menu
            # Modifiable: $Selection to change the selection, $MenuOptions for new array of options (like returning an array, BUT DOES NOT re-calculate the menu)
    
        .PARAMETER Columns
            Value: <"Auto"|Integer>

            Define how many columns should be shown (default: "Auto")
        .PARAMETER MaximumColumnWidth
            Value: <"Auto"|Integer>

            The maximum amount of chars in a cell should be displayed, if to large, '...' will be appended 
            (default: "Auto" if Columns is a number, results in "20" if Columns is "Auto")
        .PARAMETER ShowCurrentSelection
            Value: <Boolean>
            Shows the current selection text in full length in the console title (default: $False)
        .PARAMETER PassThrou
            Without, will output the index of the selection, otherwise the selected string (default: $False)
        .PARAMETER ReturnObject
            Returns Selection index, SelectionValue string, MenuOptions string[] of maybe modified items, MenuOptionsInput string[] of input strings, Items object of {"Name" maybe modified,"Index","Input" originial string}  -- has a higher priority then PassThrou
        .PARAMETER ForegroundColor
            Value: <Black|ConsoleColor>
            Color for the selection (default: Black)
        .PARAMETER ForegroundColorSelection
            Value: <Black|ConsoleColor>

            Color for the selection (default: Black)
        .PARAMETER BackgroundColorSelection
            Value: <Cyan|ConsoleColor>

            Color for the selection (default: Cyan)
        .PARAMETER ForegroundColorTitle
            Value: <Cyan|ConsoleColor>

            Color for the title (default: Cyan)
        .PARAMETER ForegroundColorFooter
            Value: <Black|ConsoleColor>

            Color for the footer (default: Black)
    
        .PARAMETER ClearHost
            Value: <Boolean>

            Will clear the screen on start and after selecting from the terminal (default: False)
    
        .PARAMETER CleanHost
            Value: <Boolean>

            Will clear the menu after selecting from the terminal (default: False)
    
        .PARAMETER FilterCallback
            Value: <Null|ScriptBlock>

            Will allows to modify the list of strings before they are shown
    
            # params in: $CellValue, $Current, $CurrentValue, $Selection, $SelectionValue, $MenuOptions, $MenuOptionsInput, $esc, $CL, $Row, $Column
            #   $esc = char 27, ansi seq. start
            #   $CL = ansi seq to clear to end of line
            #   $CellValue = the cell content, the $SelectedValue with spaces around it
            # return: new value for $CellValue (if nothing/$false/$null is returned, it will not be changed)
            # Modifiable: $MenuOptions,$Selection,$CellValue
    
        .OUTPUTS
            Default is the index of the selected string, using -PassThrou it will be the selected string, using -ReturnObject it will be an object with items
    
            ReturnObject = {
                Selection = index of the selection
                SelectionValue = string of the selection
    
                MenuOptions = string[] of maybe modified items (was used for display)
                MenuOptionsInput = string[] of input strings
    
                Items = {
                    Name = maybe modified (was used for display)
                    Index = index of the item within the MenuOptions (Not MenuOptionsInput)
                    Input = originial string
                }
            }
    
        .EXAMPLE
            import-module ./create-menu.ps1
            ls | Create-Menu
                show all files as a selection and return its index upon selecting
        .EXAMPLE
            New-Module -Name "Create Menu" -ScriptBlock ([Scriptblock]::Create((New-Object System.Net.WebClient).DownloadString("https://gist.githubusercontent.com/BananaAcid/b8efca90cc6ca873fa22a7f9b98d918a/raw/Create-Menu.ps1"))) | Out-Null
            ls | Create-Menu
                show all files as a selection and return its index upon selecting. Loading from remote location.
        .EXAMPLE
            $check = Create-Menu no,yes "Want it?" 1
                Shortest version. "no" first, becuase index 0 is equal to false. the "1" selects index 1 initially
    
                Outputs on single line: `Want it? no  yes `
        .EXAMPLE
            $check = Create-Menu @("no","yes") -Title "Want it?" -Selected 1
                Longer version
        .EXAMPLE
             ls | create-menu -passthrou -T "Show Content:`n" |% {cat $_}
                Outputs a filename's contents after selecting
        .EXAMPLE
            echo "Select a letter"; $sel = @("a","b","c") | Create-Menu -PassThrou; echo "Selected: $sel"
                Usage for -MenuOptions by piping in
        .EXAMPLE
            ls ../ | Create-Menu -Title "abc`n-----"
                A simple string as title
        .EXAMPLE
            ls ../ | Create-Menu -Title {"SEL: $SelectionValue`n-----`n"}
                A scriptblock with an internal variable
        .EXAMPLE
            ls ../ | Create-Menu -Title {"SEL: $SelectionValue`n-----`n"} -ReturnObject
                A scriptblock with an internal variable, returning the selection opens
        .EXAMPLE
            ls ../ | Create-Menu -Title {Write-Host Green "SEL: $SelectionValue`n-----`n"}
                A scriptblock with colored title
        .EXAMPLE
            Create-Menu a,b -SelectionCallback {if ($KeyInput -eq 27) { return $False } }
                ESC to cancel input
        .EXAMPLE
            Create-Menu 0,1,2,3 -t {"SEL: $global:ki`n-----"} -SelectionCallback { $global:ki = $KeyInput }
                Show code of pressed key
        .EXAMPLE
            $YesNoCB = { If ($KeyInput -eq 89) { $Selection = 0 ; Return $True } If ($KeyInput -eq 78) { $Selection = 1  ; Return $True } }
            Create-Menu Y,n -SelectionCallback $YesNoCb
                Show "Y" and "n", pressing y (89) or n (78) will select the specific index, exit and show the selected
    
        .EXAMPLE
            $SpacePressed = { 
                If ($KeyInput -eq 32) {                                             # space-key
                    if ($SelectionValue -like '`* *') {                             # check if item has a '* ' prefix = is selected already
                        $MenuOptions[$Selection] = $MenuOptionsInput[$Selection]    # remove prefix by setting it to the original string
                    } Else {
                        $MenuOptions[$Selection] = '* ' + $SelectionValue           # add prefix to displayed item
                    }
                }
            }
            $ret = ls ~/ | Create-Menu -t {"Full Name: $SelectionValue`n-----`n"} -SelectionCallback $SpacePressed -MaximumColumnWidth 40 -ReturnObject
            $selected = $ret.Items |? { $_.Name -like '`* *' } |% Input             # check all items, if they had been marked (would also work: .Name -ne .Input)
            Write-Host "File Paths: ", $selected
    
                Allows to select multiple files with the space key (Keycode 32), then gets their names
    
    
        .EXAMPLE
            $names = "Tom", "Tim", "John", "Alice", "Bob", "Eve", "Adam", "Sarah", "Michael", "Jessica", "William", "Oliver", "Benjamin", "Hannah", "Kevin", "Lily", "David", "Emily", "Matthew", "Ashley", "Joseph", "James", "Laura", "Robert", "Richard", "Patricia", "Christopher", "Nicolas", "Sam", "Jennifer", "Lisa", "Brian", "Heather", "Katherine", "Julia", "Steven", "Amanda", "Rebecca", "Linda", "Daniela", "Elizabeth", "Andrew", "Stephanie", "Anthony", "Rachel", "Michelle", "Joshua", "Samantha", "Emi", "Alex", "Steven", "Amanda", "Rebecca", "Linda", "Daniel", "Elizabeth", "André", "Stephanie", "Anthony", "Rachel", "Michelle", "Joshua", "Sammy", "Amy", "Alexander", "Sammy"
            [Collections.ArrayList]$Global:Selected = @()                               # collect indexes of selected names
            Create-Menu $names `
                -Title  { "Selected Idx: $Global:selected`n-----`n" } `
                -Footer { "Selected Names: $( $Global:selected |% { $MenuOptionsInput[$_] }  )" } `
                -SelectionCallback {
                    if ($KeyInput -eq 27) { return $False }                             # exit with ESC-key
    
                    If ($KeyInput -eq 32) {                                             # select with space-key
                        if ($Global:selected -contains $Selection) {                    # the index is already selected (in the list)
                            $Global:selected.Remove($Selection)                         # remove the idx from the list
                        } 
                        Else {$Global:selected.Add($Selection) }                        # remember the idx (NOT THE NAME, but the unique idx!)
                        return $true                                                    # add and remove return false - we need to overwrite the return
                    } 
                } `
                -Filter { 
                    if ($Global:selected -contains $Current) {
                        $CellValue -Replace $CurrentValue,"$esc[4m$CurrentValue$esc[24m" # highlight selected with ansi sq for underline, BUT preserve cell value spaces
                    }
                } | Out-Null                                                            # we only want the $global:Selected, we do not care about the default output
            Write-Host "Names: ", ( $Global:selected |% { $names[$_] } )
    
                Allows to select multiple files with the space key, then gets their names. ESC will exit
                It uses an external var to keep track of selecting and unselecting, and uses the -Filter to modify the items
    
        .EXAMPLE
            $num = Create-Menu (1..10) `
                -Title "Select a number:" `
                -Filter { $CellValue -Replace $CurrentValue,"<$CurrentValue>" } `
                -Clean `
                -PassThrou
            Write-Host "You selected: ", $num
    
                Show a selection of numbers and reformat them. After selection, the menu will vanish and at its place show the selected number
                
                How?
                -Clean = Menu will vanish after selection
                -PassThrou = return the selected value, not index
    
        .NOTES
            Based on: https://community.spiceworks.com/scripts/show/4785-create-menu-2-0-arrow-key-driven-powershell-menu-for-scripts
    #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True ,Mandatory=$True )][Alias("Options")][String[]]$MenuOptions,
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][Object]$Title = $Null,
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][Alias("Index")][int]$Selected = $Null,

        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][Object]$Footer = $Null,
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][Alias("CB", "CallbackSelection")][ScriptBlock]$SelectionCallback = $Null,
                                            
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][String]$Columns = "Auto",
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][String]$MaximumColumnWidth = "Auto",
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][bool]$ShowCurrentSelection = $False,
        
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][switch]$PassThrou = $False,
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][switch]$ReturnObject = $False,
        
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][Alias("c")][ConsoleColor]$ForegroundColor = [ConsoleColor]::Black,
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][Alias("cs")][ConsoleColor]$ForegroundColorSelection = [ConsoleColor]::Black,
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][Alias("csb")][ConsoleColor]$BackgroundColorSelection = [ConsoleColor]::Cyan,
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][Alias("ct")][ConsoleColor]$ForegroundColorTitle = [ConsoleColor]::Yellow,
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][Alias("cf")][ConsoleColor]$ForegroundColorFooter = [ConsoleColor]::Green,
        
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][switch]$CleanHost = $False,
        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][switch]$ClearHost = $False,

        [Parameter(ValueFromPipeline=$False,Mandatory=$False)][Alias('Filter')][Object]$FilterCallback = $Null
    )

    # in case items were pipelined
    $all = @($Input)
    If ($all) {
        $MenuOptions = [array]$all
    }

    $MenuOptionsInput = $MenuOptions.psobject.copy() # | ConvertTo-Json -depth 100 | ConvertFrom-Json
    $MaxValue = $MenuOptions.count-1
    If ($Selected) { $Selection = $Selected } else { $Selection = 0 }
    $EnterPressed = $False
    $WindowTitleBackup = $Host.UI.RawUI.WindowTitle
    $RowQty = 0

    $outputBuffer = "" # contains output

    If ($Columns -eq "Auto") {
        If ($MaximumColumnWidth -eq "Auto") {
            $MaximumColumnWidth = 20
        }

        $WindowWidth = $Host.UI.RawUI.BufferSize.Width
        $Columns = [Math]::Floor($WindowWidth / ([int]$MaximumColumnWidth +2))
    }
    Else {
        If ($MaximumColumnWidth -eq "Auto") {
            $MaximumColumnWidth = [Math]::Floor(($Host.UI.RawUI.BufferSize.Width - [int]$Columns) / [int]$Columns)
        }
    }
        
    $MenuListing = @()
    Function New-MenuListing($MenuOptions) {
        If ([int]$Columns -gt $MenuOptions.count) {
            $Columns = $MenuOptions.count
        }

        $RowQty = ([Math]::Ceiling(($MaxValue +1) / [int]$Columns))

        # This loop is used to format the menu listing into a
        # two-dimensional array, where each row is a column in the
        # final menu listing. The outer loop iterates over the columns
        # while the inner loop iterates over the rows of the column.
        # The inner loop fetches the menu options for each column and
        # then formats them to fit within the maximum column width.
        # The formatted menu options are stored in the $MenuListing array.
        For ($i=0; $i -lt $Columns; $i++) {
                
            $ScratchArray = @()

            For ($j=($RowQty*$i); $j -lt ($RowQty*($i+1)); $j++) {

                $ScratchArray += $MenuOptions[$j]
            }

            $ColWidth = ($ScratchArray |Measure-Object -Maximum -Property length).Maximum

            If ($ColWidth -gt [int]$MaximumColumnWidth) {
                $ColWidth = [int]$MaximumColumnWidth-1
            }

            For ($j=0; $j -lt $ScratchArray.count; $j++) {
                
                If (($ScratchArray[$j]).length -gt $([int]$MaximumColumnWidth -2)) {
                    $ScratchArray[$j] = $($ScratchArray[$j]).Substring(0,$([int]$MaximumColumnWidth-2))
                    $ScratchArray[$j] = "$($ScratchArray[$j])…"
                }
                Else {
                    For ($k=$ScratchArray[$j].length; $k -lt $ColWidth; $k++) {
                        $ScratchArray[$j] = "$($ScratchArray[$j]) "
                    }
                }
                
                $ScratchArray[$j] = " $($ScratchArray[$j]) "
            }
            $MenuListing += $ScratchArray
        }
        return $MenuListing, $Columns, $RowQty
    }

    Function New-TextBlock ($Block, $BlockName, $ForegroundColor = -1, $Selection, $MenuOptions, $MenuOptionsInput, $esc, $CL) {
        $retBuffer = ""
        if ($Block) {
            if ($Block -is [String]) {
                $retBuffer += ConvertTo-CreateMenuAnsiColorString $Block -ForegroundColor $ForegroundColor
            }
            else {
                $retBuffer += Invoke-Command -ScriptBlock { param($Selection, $SelectionValue, $MenuOptions, $MenuOptionsInput, $esc, $CL) # supply usable variables

                    # in module fix
                    try { $sbStr = Get-Variable -Name "Block" -Scope 1 -ValueOnly ; $Block = [scriptblock]::Create($sbStr) } 
                    catch { }
                    
                    Invoke-Command -ScriptBlock $Block *>&1 -OutVariable Lines | Out-Null
                    $retBuffer += ConvertTo-CreateMenuAnsiColorString $Lines -ForegroundColor $ForegroundColor  # manual color

                    return $retBuffer
                } -ArgumentList $Selection, $MenuOptions[$Selection], $MenuOptions, $MenuOptionsInput, $esc, $CL
            }
        }
        return $retBuffer | ForEach-Object { "$CL$_" }   #! ALWAYS clean the line before using
    }

    Function CleanHost {
        $Host.UI.RawUI.CursorPosition = @{x=0; y=$Host.UI.RawUI.CursorPosition.Y - $bufferHeight}
        Write-Host ("$CL`n" *( $bufferHeight)).Trim()
        $Host.UI.RawUI.CursorPosition = @{x=0; y=$Host.UI.RawUI.CursorPosition.Y - $bufferHeight}
    }
    
    
    
    
    
    $MenuListing, $Columns, $RowQty = New-MenuListing $MenuOptions
    
    [Console]::CursorVisible = $False


    $bufferHeight = 0
    $bufferHeightBackup = 0

    $esc = [char]27
    $CL = "$esc[0;0m$esc[0J"

    $topBufferHeight = -1

    
    if ($ClearHost) {
        [Console]::Clear()
    }
    
    While ($True) {
        $outputBuffer = ""
        $bufferHeightBackup = $bufferHeight
        
        If ($ShowCurrentSelection) {
            $Host.UI.RawUI.WindowTitle = "CURRENT SELECTION: $($MenuOptions[$Selection])"
        }

        # set cursor back to beginning of output (top of screen has to be processed at least once)
        if ($topBufferHeight -ge 0 -and ($DebugPreference -ne 'Continue') ) {
            $Host.UI.RawUI.CursorPosition = @{x=0; y=$Host.UI.RawUI.CursorPosition.Y  - $topBufferHeight}
        }


        # generate output

        $outputBuffer += New-TextBlock $Title "title-block" $ForegroundColorTitle  $Selection $MenuOptions $MenuOptionsInput $esc $CL

        # output selections
        For ($i=0; $i -lt $RowQty; $i++) {

            For ($j=0; $j -le (($Columns-1)*$RowQty);$j+=$RowQty) {

                $value = $MenuListing[$i+$j]

                if ($null -ne $FilterCallback) {
                    $MenuOptions,$Selection,$CellValue = Invoke-Command -ScriptBlock { param($CellValue, $Current, $CurrentValue, $Selection, $SelectionValue, $MenuOptions, $MenuOptionsInput, $esc, $CL, $Row, $Column)
                        
                        # in module fix
                        try { $sbStr = Get-Variable -Name "FilterCallback" -Scope 1 -ValueOnly ; $FilterCallback = [scriptblock]::Create($sbStr) } 
                        catch { }

                        $CellValue = . $FilterCallback
                        
                       Return $MenuOptions, $Selection, $CellValue
                    } -ArgumentList $value, ($i+$j), $MenuOptions[$i+$j] , $Selection, $MenuOptions[$Selection], $MenuOptions, $MenuOptionsInput, $esc, $CL, $i, $j

                    $value = if ($CellValue) { $CellValue } else { $value }
                }

                # is end of line
                If ($j -eq (($Columns-1)*$RowQty)) {
                    If (($i+$j) -eq $Selection){
                        $outputBuffer += ConvertTo-CreateMenuAnsiColorString "$($value)$CL`n" -BackgroundColor $BackgroundColorSelection -ForegroundColor $ForegroundColorSelection
                    } Else {
                       $outputBuffer += ConvertTo-CreateMenuAnsiColorString "$($value)`n" -ForegroundColor $ForegroundColor
                    }
                # is in row
                } Else {
                    If (($i+$j) -eq $Selection) {
                        $outputBuffer += ConvertTo-CreateMenuAnsiColorString "$($value)" -BackgroundColor $BackgroundColorSelection -ForegroundColor $ForegroundColorSelection
                    } Else {
                        $outputBuffer += ConvertTo-CreateMenuAnsiColorString "$($value)" -ForegroundColor $ForegroundColor
                    }
                }
                
            }
        }

        $outputBuffer += New-TextBlock $Footer "footer-block" $ForegroundColorFooter   $Selection $MenuOptions $MenuOptionsInput $esc $CL


        $outputBuffer += " " # prevents line jumping

        # do positioning

        $bufferHeight = ($outputBuffer | Measure-Object -Line).lines
        $currentBufferHeight = $Host.UI.RawUI.BufferSize.Height

        If ($bufferHeight -gt $currentBufferHeight) {
            throw "Menu too tall to fit in buffer. Increase buffer height. (Window height)"
        }

        Write-Host $outputBuffer

        $topBufferHeight = $bufferHeight  # back to start line
        if ($bufferHeight -lt $bufferHeightBackup) { # rows changed inbetween
            Write-Host ("$CL`n" *( $bufferHeightBackup - $bufferHeight)).Trim()
            $topBufferHeight = $bufferHeightBackup
        }

        # $Host.UI.RawUI.CursorPosition = @{x=0; y=$Host.UI.RawUI.CursorPosition.Y - $topBufferHeight}


        if ($EnterPressed) {
            If ($ClearHost) {
                [Console]::Clear()
            }

            Break
        }

        $KeyInput = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").virtualkeycode

        Switch ($KeyInput) {
            13 { #Enter
                # ignore empty fields
                If ($MenuOptions[$Selection]) {
                    $EnterPressed = $True

                    # set title to before menu
                    If ($ShowCurrentSelection) {
                        $Host.UI.RawUI.WindowTitle = $WindowTitleBackup
                    }

                    If ($ClearHost) {
                        [Console]::Clear()
                    }

                    if ($CleanHost) {
                        CleanHost
                    }

                    $returnContent = $null
                    
                    If ($ReturnObject) {

                        $items = @()

                        For ($i=0; $i -lt $MenuOptions.length; $i++) {
                            $items += @{
                                "Name" = $MenuOptions[$i];
                                "Index" = $i;
                                "Input" = $MenuOptionsInput[$i];
                            }
                        }

                        $returnContent = @{
                            "Selection" = $Selection;
                            "SelectionValue" = $MenuOptions[$Selection];
                            "MenuOptions" = $MenuOptions;
                            "MenuOptionsInput" = $MenuOptionsInput;
                            "Items" = $items;
                        }
                    }
                    ElseIf ($PassThrou) {
                        $returnContent = $MenuOptions[$Selection]
                    }
                    Else {
                        $returnContent = $Selection
                    }
                    # $Host.UI.RawUI.CursorPosition = @{x=0; y=$Host.UI.RawUI.CursorPosition.Y  + $BufferHeight}
                    [Console]::CursorVisible = $true

                    Return $returnContent
                }

                Break
            }

            37 { #Left
                If ($Selection -ge $RowQty){
                    $Selection -= $RowQty
                } Else {
                    $Selection += ($Columns-1)*$RowQty
                }
                Break
            }

            38 { #Up
                If ((($Selection+$RowQty)%$RowQty) -eq 0) {
                    # If the selection is at the start of a row, move to the last item in the row
                    $Selection += $RowQty - 1
                } Else {
                    $Selection -= 1
                }
                Break
            }

            39{ #Right
                # If the selection is at the end of a row, move to the previous row
                # by subtracting the number of columns minus one multiplied by the row quantity
                # Otherwise, move to the next item in the row
                If ([Math]::Ceiling($Selection/$RowQty) -eq $Columns -or ($Selection/$RowQty)+1 -eq $Columns){
                    $Selection -= ($Columns-1)*$RowQty
                } Else {
                    $Selection += $RowQty
                }
                Break
            }

            40 { #Down
                If ((($Selection+1)%$RowQty) -eq 0 -or $Selection -eq $MaxValue){
                    $Selection = ([Math]::Floor(($Selection)/$RowQty))*$RowQty
                } Else {
                    $Selection += 1
                }
                Break
            }

            Default {
            }
        }

        if ($SelectionCallback -ne $Null) {
            # return new MenuOptions, if you want
            $ret,$sel,$res = Invoke-Command -ScriptBlock { param($Selection, $SelectionValue, $MenuOptions, $MenuOptionsInput, $KeyInput, $esc, $CL)
                
                # in module fix, replace wiht localized script block
                try { $sbStr = Get-Variable -Name "SelectionCallback" -Scope 1 -ValueOnly ; $SelectionCallback = [scriptblock]::Create($sbStr) } 
                catch { }
                
                $res = . $SelectionCallback

                Return $MenuOptions, $Selection, $res
            } -ArgumentList $Selection, $MenuOptions[$Selection], $MenuOptions, $MenuOptionsInput, $KeyInput, $esc, $CL

            If ($sel -is [Int]) {
                $Selection = $sel
            }

            If ($res -eq $False) {
                $EnterPressed = $True

                # set title to before menu
                If ($ShowCurrentSelection) {
                    $Host.UI.RawUI.WindowTitle = $WindowTitleBackup
                }
            }

            ElseIf ($ret -is [Array]) {
                $MenuOptions = $ret
                $MenuListing, $Columns, $RowQty = New-MenuListing $MenuOptions
            }
        }

    }
}






Function ConvertTo-CreateMenuAnsiColorString {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$InputString,
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor,
        [Parameter(Mandatory=$false)]
        [string]$BackgroundColor,
        [Parameter(Mandatory=$false)]
        [string[]]$Styles
    )
    
    $esc = [char]27 # using char 27 instead of string "`e" because not using `e makeis it PS 5.1 compatible

    $ansiColors = @{
        # Powershell defined ones, 0-15
        Black = 0; DarkBlue = 4; DarkGreen = 2; DarkCyan = 6; DarkRed = 1; DarkMagenta = 5; DarkYellow = 3; Gray = 7; DarkGray = 8; Blue = 12; Green = 10; Cyan = 14; Red = 9; Magenta = 13; Yellow = 11; White = 15;
    }
    $fgColor = $ansiColors[$ForegroundColor]
    $bgColor = $ansiColors[$BackgroundColor]

    $ansiStyles = @{ Normal = 0; Bold = 1; Dim = 2; Italic = 3; Underline = 4; Blink = 5; RapidBlink = 6; Reverse = 7; Hidden = 8; }
    if ($Styles) {
        $styleSequence = $Styles | ForEach-Object { "$esc[{0}m" -f $ansiStyles[$_] }
    }

    if ("$fgColor" -and "$bgColor") {
        return "$styleSequence$esc[38;5;{0};48;5;{1}m{2}$esc[0m" -f $fgColor, $bgColor, $InputString
    } elseif ("$fgColor") {
        return "$styleSequence$esc[38;5;{0}m{1}$esc[0m" -f $fgColor, $InputString
    } elseif ("$bgColor") {
        return "$styleSequence$esc[48;5;{0}m{1}$esc[0m" -f $bgColor, $InputString
    } elseif ($Styles) {
        return "$styleSequence$InputString$esc[0m"
    } else {
        return $InputString
    }
}
