# Create Menu for Powershell
Shows strings as a table to be selectable by navigating with arrow keys, in Powershell

<img width="370" alt="Small Example" src="https://user-images.githubusercontent.com/1894723/211035316-ec6ea332-209b-438a-908d-8d86fb9efdae.png">

## Installation

To use it in your own scripts, just load it as module, to make the function available

```ps1
Import-Module "Create-Menu" -Force
```

### without installing

```ps1
New-Module -Name "Create-Menu TUI" -ScriptBlock ([Scriptblock]::Create((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/BananaAcid/CreateMenuPS/refs/heads/main/Create-Menu/Create-Menu.ps1"))) | Out-Null
# enables New-SelectionMenu (not the Create-Menu alias)
```

## Usage

```ps1
New-SelectionMenu [-MenuOptions] <String[]> [[-Title] <Object>] [[-Selected] <Int32>] [[-Footer] <Object>] [[-SelectionCallback] <ScriptBlock>] [[-Columns] <String>] [[-MaximumColumnWidth] <String>] [[-ShowCurrentSelection] <Boolean>] [-PassThrou] [-ReturnObject] [[-ForegroundColor] {color names}] [[-ForegroundColorSelection] {color names}] [[-BackgroundColorSelection] {color names}] [[-ForegroundColorTitle] {color names}] [[-ForegroundColorFooter] {color names}] [-CleanHost] [-ClearHost] [[-FilterCallback] <Object>] [<CommonParameters>]
```
Alias: `Create-Menu`


| Parameter | Type | Description |
| :--- | :--- | :--- |
| `-MenuOptions` | `String[]` | Takes an array with selections (must be more then one). |
| `-Title` | `Null\|ScriptBlock\|String` | Takes a string or a scriptblock, use $global:varname to link to Title, Footer or SelectionCallback. |
| `-Selected` | `Null\|Int32` | Initial string to select. |
| `-Footer` | `Null\|ScriptBlock\|String` | Takes a string or a scriptblock. |
| `-SelectionCallback` | `Null\|ScriptBlock` | If you want to trigger something on selection or a key, or change the $MenuOptions/$Selection, return $False to exit. [1] |
| `-Columns` | `"Auto"\|Integer` | Define how many columns should be shown (default: "Auto"). |
| `-MaximumColumnWidth` | `"Auto"\|Integer` | The maximum amount of chars in a cell should be displayed. |
| `-ShowCurrentSelection` | `Boolean` | Shows the current selection text in full length in the console title (default: $False). |
| `-PassThrou` | `SwitchParameter` | Without, will output the index of the selection, otherwise the selected string (default: $False). |
| `-ReturnObject` | `SwitchParameter` | Returns index, string, options array, and item object (higher priority than PassThrou). |
| `-ForegroundColor` | `[Console]::ForegroundColor\|ConsoleColor` | Color for the selection (default: [Console]::ForegroundColor). |
| `-ForegroundColorSelection` | `ConsoleColor` | Color for the selection (default: Black). |
| `-BackgroundColorSelection` | `ConsoleColor` | Color for the selection (default: Cyan). |
| `-ForegroundColorTitle` | `ConsoleColor` | Color for the title (default: Cyan). |
| `-ForegroundColorFooter` | `ConsoleColor` | Color for the footer (default: Black). |
| `-CleanHost` | `SwitchParameter` | Will clear the menu after selecting from the terminal (default: False). |
| `-ClearHost` | `SwitchParameter` | Will clear the screen on start and after selecting from the terminal (default: False). |
| `-FilterCallback` | `Null\|ScriptBlock` | Allows to modify the list of strings before they are shown. [2] |

---

Color Names: `Black | DarkBlue | DarkGreen | DarkCyan | DarkRed | DarkMagenta | DarkYellow | Gray | DarkGray | Blue | Green | Cyan | Red | Magenta | Yellow | White`

**[1] SelectionCallback details:**
* **params in:** $Selection, $SelectionValue, $MenuOptions, $MenuOptionsInput, $KeyInput, $esc (char 27, ansi seq. start), $CL (ansicode to clear to end of line).
* **return:** $False to end, or array of new options and triggers re-calculation of the menu.
* **Modifiable:** $Selection to change the selection, $MenuOptions for new array of options.

**[2] FilterCallback details:**
* **params in:** $CellValue, $Current, $CurrentValue, $Selection, $SelectionValue, $MenuOptions, $MenuOptionsInput, $esc, $CL, $Row, $Column.
* **variables:** $esc = char 27, ansi seq. start; $CL = ansi seq to clear to end of line; $CellValue = the cell content.
* **return:** new value for $CellValue (if nothing/$false/$null is returned, it will not be changed).
* **Modifiable:** $MenuOptions, $Selection, $CellValue.


## Example

### More examples and up-to-date in the module

```ps1
Get-Help Create-Menu -Detailed
```

### Simple

```ps1
$check = Create-Menu no,yes "Want it?`n" 1

echo ("you " + ($check ? "do" : "do not") + " want it")
```

### Show menu and replace with result

Show a selection of numbers and reformat them. After selection, the menu will vanish and at its place show the selected number

**How?**
- `-Clean` -> Menu will vanish after selection
- `-PassThrou` -> return the selected value, not index

```ps1
$num = Create-Menu (1..10) `
    -Title "Select a number:" `
    -Filter { $CellValue -Replace $CurrentValue,"<$CurrentValue>" } `
    -Clean `
    -PassThrou

Write-Host "You selected: ", $num
```

### Multi selection - simple

Allows to select multiple files with the space key (Keycode 32), then gets their names

```ps1
$SpacePressed = { 
    If ($KeyInput -eq 32) {                                             # space-key
        if ($SelectionValue -like '`* *') {                             # check if item has a '* ' prefix = is selected already
            $MenuOptions[$Selection] = $MenuOptionsInput[$Selection]    # remove prefix by setting it to the original string
        } Else {
            $MenuOptions[$Selection] = '* ' + $SelectionValue           # add prefix to displayed item
        }
    }
}

$ret = ls ~/ | Create-Menu -Title {"Full Name: $SelectionValue`n-----`n"} -SelectionCallback $SpacePressed -MaximumColumnWidth 40 -ReturnObject

$selected = $ret.Items |? { $_.Name -like '`* *' } |% Input             # check all items, if they had been marked (would also work: .Name -ne .Input)

Write-Host "File Paths: ", $selected
```

### multi selection

Allows to select multiple files with the space key, then gets their names. ESC will exit

It uses an external var to keep track of selecting and unselecting, and uses the -Filter to modify the items

```ps1
$names = "Tom", "Tim", "John", "Alice", "Bob", "Eve", "Adam", "Sarah", "Michael", "Jessica", "William", "Oliver", "Benjamin", "Hannah", "Kevin", "Lily", "David", "Emily", "Matthew", "Ashley", "Joseph", "James", "Laura", "Robert", "Richard", "Patricia", "Christopher", "Nicolas", "Sam", "Jennifer", "Lisa", "Brian", "Heather", "Katherine", "Julia", "Steven", "Amanda", "Rebecca", "Linda", "Daniela", "Elizabeth", "Andrew", "Stephanie", "Anthony", "Rachel", "Michelle", "Joshua", "Samantha", "Emi", "Alex", "Steven", "Amanda", "Rebecca", "Linda", "Daniel", "Elizabeth", "André", "Stephanie", "Anthony", "Rachel", "Michelle", "Joshua", "Sammy", "Amy", "Alexander", "Sammy"

[Collections.ArrayList]$Global:Selected = @()                               # collect indexes of selected names

Create-Menu $names `
    -Title  { "Selected Idx: $Global:Selected`n-----`n" } `
    -Footer { "Selected Names: $( $Global:Selected |% { $MenuOptionsInput[$_] }  )" } `
    -SelectionCallback {
        if ($KeyInput -eq 27) { return $False }                             # exit with ESC-key

        If ($KeyInput -eq 32) {                                             # select with space-key
            if ($Global:Selected -contains $Selection) {                    # the index is already selected (in the list)
                $Global:Selected.Remove($Selection)                         # remove the idx from the list
            } 
            Else {$Global:Selected.Add($Selection) }                        # remember the idx (NOT THE NAME, but the unique idx!)
            return $true                                                    # add and remove return false - we need to overwrite the return
        } 
    } `
    -FilterCallback { 
        if ($Global:Selected -contains $Current) {
            $CellValue -Replace $CurrentValue,"$esc[4m$CurrentValue$esc[24m" # highlight selected with ansi sq for underline, BUT preserve cell value spaces
        }
    } | Out-Null                                                            # we only want the $global:Selected, we do not care about the default output

Write-Host "Names: ", ( $Global:Selected |% { $names[$_] } )
```
<img width="1159" height="119" alt="Multiselection Example" src="https://github.com/user-attachments/assets/9d2a9285-f123-487b-aca3-5dda758d948e" />

## Info

Based on https://gist.github.com/BananaAcid/b8efca90cc6ca873fa22a7f9b98d918a/
