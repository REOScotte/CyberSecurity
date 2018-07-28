<#
    Just a quick powershell game to practice converting between base 2, 10, and 16
    It gives a number in one of the 3 bases and prompts with a desired base

    Base 10 and 16 numbers are entered normally, leading zeros are ignored and there's not need for a prefix like 0x for hex.
    Base 2 however is a little weird. It basically copies the input scheme for BinaryBlitz - a game a friend of mine wrote.
    (https://gannebraemorr.wixsite.com/home, click Files to download Binary Blitz.exe)
    In that game, your fingers rest on the home row (asdfjkl;) and those characters toggle the corresponding bit.
    I like that input scheme, but it's tricky to simulate using PowerShell's Read-Host. But, this gets pretty close:
    You enter a string of those characters in any order and duplicates of the character cancel each other out.

    For example, all of these evaluate to 1001 0000 (144) since the first (a) and fourth (f) bit are entered.
    af
    fa
    afaa (the extra two a's cancel each other)
#>

$binColor = "Magenta"
$decColor = "Cyan"
$hexColor = "Yellow"

$ErrorActionPreference = 'SilentlyContinue'
$right = 0
$wrong = 0
$start = Get-Date

do {
    $average = ((Get-Date) - $start).TotalSeconds / ($right + $wrong)
    Write-Host "Right: $right`tWrong: $wrong`tPercent: $($right * 100 / ($right + $wrong))`tAverage: $average seconds"

    # Get the number and bases. The -Maximum parameter is exclusive, so we'll end up with 0 - 255
    # Passing the valid bases to Get-Random lets us pick two non-colliding bases at once.
    $number = Get-Random -Maximum 256
    $bases = Get-Random -InputObject 2, 10, 16 -Count 2
    $baseFrom = $bases[0]
    $baseTo = $bases[1]

    # Uncomment to force values
    # $number = 0
    # $baseFrom = 10
    # $baseTo = 16

    # Show the problem with formating that's appropriate for the different bases
    switch ($baseFrom) {
        2 {Write-Host -ForegroundColor $binColor  "Bin:" ("{0:0000 0000}" -f [int]([Convert]::ToString($number, 2)))}
        10 {Write-Host -ForegroundColor $decColor "Dec:" ([Convert]::ToString($number, 10))}
        16 {Write-Host -ForegroundColor $hexColor "Hex:" ([Convert]::ToString($number, 16)).ToUpper()}
    }

    # Store the right answer for display when wrong
    $goal = switch ($baseTo) {
        2 {"{0:0000 0000}" -f [int]([Convert]::ToString($number, 2))}
        10 {[Convert]::ToString($number, 10)}
        16 {[Convert]::ToString($number, 16).ToUpper()}
    }

    # Prompt for an answer
    $answer = switch ($baseTo) {
        2 {Write-Host -ForegroundColor $binColor "Bin: " -NoNewline; Read-Host}
        10 {Write-Host -ForegroundColor $decColor "Dec: " -NoNewline; Read-Host}
        16 {Write-Host -ForegroundColor $hexColor "Hex: " -NoNewline; Read-Host}
    }

    if ($answer -eq 'q') {break}

    # Base 2 answers require translation, so it looks at each character entered (order doesn't matter)
    # and uses xor to turn that bit on or off. So, if you put in aa, the first time the loop sees
    # the a, the 128 bit goes on. The second time it goes off. This simulates Binary Blitz input scheme.
    if ($baseTo -eq 2) {
        $b = 0
        foreach ($c in [char[]]$answer) {
            switch ($c) {
                "a" {$b = $b -bxor 128}
                "s" {$b = $b -bxor 64 }
                "d" {$b = $b -bxor 32 }
                "f" {$b = $b -bxor 16 }
                "j" {$b = $b -bxor 8  }
                "k" {$b = $b -bxor 4  }
                "l" {$b = $b -bxor 2  }
                ";" {$b = $b -bxor 1  }
            }
        }
    }

    # Initialze $a to -1 to prevent a correct answer carrying forward to the next round
    $a = -1
    switch ($baseTo) {
        2 {$a = $b}
        10 {$a = [Convert]::ToInt32($answer, 10)}
        16 {$a = [Convert]::ToInt32($answer, 16)}
    }

    if ($a -eq $number) {
        Write-Host "Good job" -ForegroundColor Green
        $right++
    } else {
        Write-Host "Moron - $goal" -ForegroundColor Red
        $wrong++
    }
} while ($answer -ne "q")
