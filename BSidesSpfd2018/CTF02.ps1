[char[]]$m = 'Bayl gubfr jub xabj gur synt{Ebg_guveGrra_Vf_Yrrg} funyy cnff'

$a = ''
foreach ($c in $m) {
    switch ($i = [int]$c) {
        {$i -gt 96 -and $i -lt 110} {$i = $i + 13; break}
        {$i -gt 109 -and $i -lt 123} {$i = $i - 13; break}
        {$i -gt 64 -and $i -lt 78} {$i = $i + 13; break}
        {$i -gt 77 -and $i -lt 91} {$i = $i - 13; break}
    }
    $a += [char]$i
}
$a

[int][char]'Z'