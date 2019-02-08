$ScancodeMap = $null
if (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout\' -Name 'Scancode Map' -ErrorAction SilentlyContinue) {
    $ScancodeMap = Get-ItemPropertyValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -Name 'Scancode Map'
} else {
    $ScancodeMap = [byte[]]0 * 12
}

$Chunks = [System.Collections.Generic.List[array]]::new()
for ($i = 0; $i -lt $ScancodeMap.Count; $i += 4) {
    $Chunk = [System.Byte[]]::new(4)
    $Chunk = $ScancodeMap[$i..($i + 3)]
    $Chunks.Add($Chunk)
}

$LengthOfData = $Chunks[2][0]
$Chunks[3][0] = 0
$Chunks[3]

$NewScancodeMap = $null
foreach ($Chunk in $Chunks) {
    [byte[]]$NewScancodeMap += $Chunk
}

Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout\' -Name 'Scancode Map' -Value $NewScancodeMap

#     padding       length   to from  to from padding
#00000000 00000000 03000000 00003A00 3A004600 00000000
#$ScancodeMap.Count
#[Convert]::ToString($ScancodeMap[14], 16)

[console]::ReadKey()
