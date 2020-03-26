$Sides = 100
$Trials = 100000
$Total = 0

for ($t = 1; $t -le $Trials; $t++) {
    for ($r = 1; $r -le $Sides; $r++) {
        $Roll = Get-Random -Minimum 1 -Maximum ($Sides + 1)
        if ($Roll -le $r) {
            $Total += $r
            break
        }
    }
}
$Total / $Trials
