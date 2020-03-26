<#
.SYNOPSIS
Gets functions that are defined in a .ps1 file

.DESCRIPTION
Uses the Abstract Syntax Tree to parse a .ps1 file looking for root level functions.

.PARAMETER Path
The path to a .ps1 file

.EXAMPLE
Find all functions defined in all subfolders of current location

Get-ChildItem *.ps1 -Recurse | Get-DefinedFunction

.NOTES
Author: Scott Crawford
#>

function Get-DefinedFunction {
    [CmdletBinding()]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if (Test-Path -Path $_) {$true} else {
                    throw "The path '$_' is not an existing .ps1 file."
                }
            })]
        [string[]]$Path
    )

    process {
        try {
            $fileContent = Get-Content -Path $Path
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($fileContent, [ref]$null, [ref]$null)
            $allFunctions = $ast.FindAll( {$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true)
            $rootFunctions = $allFunctions | Where-Object {-not $_.Parent.Parent.Parent}

            Write-Output $rootFunctions.Name

        } catch {
            Write-Error $Error[0]
        }
    }
}
