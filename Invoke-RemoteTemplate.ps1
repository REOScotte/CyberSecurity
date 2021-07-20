<#
.SYNOPSIS
Template for a function that supports remote computers

.DESCRIPTION
Can be run locally, on a remote computer, or in an existing remote session. The script that's defined in
the end block is what will run.

.PARAMETER ComputerName
A remote computer to target

.PARAMETER Session
A PSSession object to target

.PARAMETER Variable
An example variable

.EXAMPLE
Run on Comp1 and Comp2 via ComputerName

Invoke-RemoteTemplate -ComputerName Comp1, Comp2

.EXAMPLE
Run on Comp1 and Comp2 via pipeline string objects

'Comp1', 'Comp2' | Invoke-RemoteTemplate

.EXAMPLE
Run on Comp1 and Comp2 via pipeline session objects

$sessions = New-PSSession -ComputerName Comp1, Comp2
$sessions | Invoke-RemoteTemplate

.NOTES
Author: Scott Crawford
Created: 2020-09-30
#>

function Invoke-RemoteTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Local', PositionalBinding = $false)]
    param (
        [Parameter(ParameterSetName = 'Session', Mandatory, ValueFromPipeline)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session
        ,
        [Parameter(ParameterSetName = 'Computer', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Name', 'Server', 'CN', 'PSComputerName')]
        [string[]]$ComputerName
        ,
        [string]$Variable
    )

    begin {
        # This script will run on all appropriate targets in the end block.
        $script = {
            Stop-Puppy -Name $Variable
        }

        # The end block looks for this optional postScript to call locally after $script is finished being invoked.
        $postScript = {

        }
    }

    # The process block builds a collection of targets.
    # Steps that are unique per target can be done here as well.
    process {
        foreach ($target in $Session) {
            [array]$allSessions += $target
            # Do something unique to the target
        }
        
        foreach ($target in $ComputerName) {
            [array]$allComputers += $target
            # Do something unique to the target
        }

        if (-not $Session -and -not $ComputerName) {
            # Do something locally
        }
    }

    # The end block is boilerplate and handles running $script locally or on remote computers and sessions.
    # Generally, this should not be modified.
    end {
        #region Get local variables to be imported into $script
        # Parse the Ast of the current script
        $functionAst = (Get-Command $MyInvocation.MyCommand).ScriptBlock.Ast

        # Find the begin block
        $predicate = {
            param ( [System.Management.Automation.Language.Ast] $AstObject )
            return ( $AstObject -is [System.Management.Automation.Language.NamedBlockAst] )
        }
        $beginNamedBlockAst = $functionAst.FindAll($predicate, $true) | Where-Object BlockKind -EQ 'Begin'

        # Find any variable assignments in the begin block except for $script and $postScript
        $predicate = {
            param( [System.Management.Automation.Language.Ast] $AstObject )
            return ( $AstObject -is [System.Management.Automation.Language.AssignmentStatementAst] )
        }
        $assignmentStatementAst = $beginNamedBlockAst.FindAll($predicate, $false) | Where-Object { $_.Left.Extent.Text -notin @('$script', '$postScript') }

        # Find any parameters defined in this function
        $predicate = {
            param( [System.Management.Automation.Language.Ast] $AstObject )
            return ( $AstObject -is [System.Management.Automation.Language.ParameterAst] )
        }
        # The string of .parent in wthe where predicate limits to parameters defined in the function and excludes parameters
        # defined in other param() blocks in this function. For example, the param block in the $predicate statement above.
        # If .parent (6 times) exists, then the parameter isn't in the main param block.
        $parameterAst = $functionAst.FindAll($predicate, $true) | Where-Object { -not $_.parent.parent.parent.parent.parent.parent }

        # Get the list of local variables
        $localVariables = $parameterAst.Name.Extent.Text + $assignmentStatementAst.Left.Extent.Text

        # Create a script that imports each local variable from the $using scope. The $using statements are wrapped in
        # a try/catch block since the $using scope doesn't exist when the script is executed locally and would otherwise error.
        $variableScript = 'try {`n'
        foreach ($variable in $localVariables) {
            $variableScript += "`t$variable = `$using:$($variable.Replace('$', ''))`n" 
        }
        $variableScript = '} catch {}`n'
        #endregion

        #region Import preference variables
        # This scriptblock imports all the current preferences to ensure those settings are passed to $script.
        $preferenceScript = {
            [CmdletBinding(SupportsShouldProcess)]
            param()

            try {
                $ConfirmPreference     = $using:ConfirmPreference
                $DebugPreference       = $using:DebugPreference
                $ErrorActionPreference = $using:ErrorActionPreference
                $InformationPreference = $using:InformationPreference
                $ProgressPreference    = $using:ProgressPreference
                $VerbosePreference     = $using:VerbosePreference
                $WarningPreference     = $using:WarningPreference
                $WhatIfPreference      = $using:WhatIfPreference
            } catch {}

            # Some cmdlets have issues with binding the preference variables. This ensures the defaults are set for all.
            # Confirm, Debug, Verbose, and WhatIf are special cases. Since they're switch parameters, the preference variable
            # is evaluated to determine if the switch should be set.
            $PSDefaultParameterValues = @{
                '*:ErrorAction'       = $ErrorActionPreference
                '*:InformationAction' = $InformationPreference
                '*:WarningAction'     = $WarningPreference
            }
            if ($ConfirmPreference -eq 'Low')      { $PSDefaultParameterValues += @{'*:Confirm' = $true } }
            if ($DebugPreference   -eq 'Inquire')  { $PSDefaultParameterValues += @{'*:Debug'   = $true } }
            if ($VerbosePreference -eq 'Continue') { $PSDefaultParameterValues += @{'*:Verbose' = $true } }
            if ($WhatIfPreference.IsPresent)       { $PSDefaultParameterValues += @{'*:WhatIf'  = $true } }
        }
        #endregion

        #region Assemble the 3 scripts and run it
        # The preference script and the actual script are combined into a single scriptblock.
        $totalScript = [scriptblock]::Create($variableScript + $preferenceScript.ToString() + $script.ToString())

        # Run the total script on all applicable targets - computers, sessions, or local.
        if ($allSessions) {
            Invoke-Command -Session $allSessions -ScriptBlock $totalScript -ErrorAction SilentlyContinue -ErrorVariable ErrorVar
        } elseif ($allComputers) {
            Invoke-Command -ComputerName $allComputers -ScriptBlock $totalScript -ErrorAction SilentlyContinue -ErrorVariable ErrorVar
        } else {
            & $totalScript
        }
        #endregion

        #region Handle any errors received in Invoke-Command.
        # If the error has an OriginInfo.PSComputerName, it occurred ON the remote computer so the remote error is written here as a warning.
        # If the error has a TargetObject.ComputerName, it occurred trying to connect to a session object so report the computer name.
        # If the error just has a TargetObject, it occured trying to connect to a remote computer, so report the computer name.
        # Otherwise, something strange is happening.
        foreach ($record in $ErrorVar) {
            if ($record.OriginInfo.PSComputerName) {
                Write-Warning "Error: $($record.Exception.Message) $($record.OriginInfo.PSComputerName)"
            } elseif ($record.TargetObject.ComputerName) {
                Write-Warning "Unable to connect to $($record.TargetObject.ComputerName)"
            } elseif ($record.TargetObject) {
                Write-Warning "Unable to connect to $($record.TargetObject)"
            } else {
                throw 'Unexpected error'
            }
        }
        #endregion

        # If a post script was defined in the begin block, call it locally.
        if ($postScript) {
            & $postScript
        }
    }
}
