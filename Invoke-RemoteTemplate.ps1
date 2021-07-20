function Invoke-RemoteTemplate {
    [CmdletBinding()]
    param(
        $Name = 'Bob',
        $New = 'asdf'
    )

    begin {
        $bob = 4

        #This script will be run in the end block on the appropriate targets 
        $script = {
            $VerbosePreference = $using:VerbosePreference

            $age = 1
            "$Name is $age"
            "Bob is $bob"

            $env:computername

            $VerbosePreference
        }

        $postScript = {
        }
    }

    process {

    }

    end {
        $functionAst = (Get-Command $MyInvocation.MyCommand).ScriptBlock.Ast

        $predicate = {
            param ( [System.Management.Automation.Language.Ast] $AstObject )
            return ( $AstObject -is [System.Management.Automation.Language.NamedBlockAst] )
        }
        $beginNamedBlockAst = $functionAst.FindAll($predicate, $true) | Where-Object BlockKind -EQ 'Begin'

        $predicate = {
            param( [System.Management.Automation.Language.Ast] $AstObject )
            return ( $AstObject -is [System.Management.Automation.Language.AssignmentStatementAst] )
        }
        $assignmentStatementAst = $beginNamedBlockAst.FindAll($predicate, $false) | Where-Object { $_.Left.Extent.Text -notin @('$script', '$postScript') }

        $predicate = {
            param( [System.Management.Automation.Language.Ast] $AstObject )
            return ( $AstObject -is [System.Management.Automation.Language.ParameterAst] )
        }
        $parameterAst = $functionAst.FindAll($predicate, $true) | Where-Object { -not $_.parent.parent.parent.parent.parent.parent }

        $localVariables = $parameterAst.Name.Extent.Text + $assignmentStatementAst.Left.Extent.Text

        $variableScript = ''
        foreach ($variable in $localVariables) {
            $variableScript += "$variable = `$using:$($variable.Replace('$', ''))`n" 
        }
        
        $vs = [scriptblock]::Create($variableScript + $script.ToString())

        Invoke-Command -ComputerName dc -ScriptBlock $vs
    }
}

Invoke-RemoteTemplate -Name asdf
