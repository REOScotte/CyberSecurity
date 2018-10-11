<#
    Silly game to practice memorizing the positions of letters (a=1, b=2, etc.)
    It prompts with a math problem using letters in place of numbers. The answer
    is a letter as well. All answers are single character a-z. This limits the
    possible problems, especially around division where only whole number answers work.
#>

while ($true) {
    $opp = Get-Random -Minimum 1 -Maximum 5
    do {
        $one = Get-Random -Minimum 1 -Maximum 27
        $two = Get-Random -Minimum 1 -Maximum 27
        switch ($opp) {
            1 {$sign = '+'; $answer = $one + $two}
            2 {$sign = '-'; $answer = $one - $two}
            3 {$sign = '*'; $answer = $one * $two}
            4 {$sign = '/'; $answer = $one / $two}
        }
    } until ($answer -lt 27 -and $answer -gt 0 -and [int]$answer -eq $answer)

    $oneLetter = [char]($one + 64)
    $twoLetter = [char]($two + 64)
    $answerLetter = [char]($answer + 64)

    $problem = (Read-Host -Prompt "What is $oneLetter $sign $twoLetter").ToUpper()

    if ($problem -eq $answerLetter) {
        Write-Host -ForegroundColor Green "Yay! You're a genious!"
    } else {
        Write-Host -ForegroundColor Yellow "Moron. The answer was $answerLetter"
    }
}