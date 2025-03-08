Function Test-IsDelegatable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $UserName
    )

    $NOT_DELEGATED = 0x00100000

    $searcher = [ADSISearcher]"(&(objectClass=user)(objectCategory=person)(sAMAccountName=$UserName))"
    $res = $searcher.FindOne()
    if (-not $res) {
        Write-Error -Message "Failed to find user '$UserName'"
    }
    else {
        $uac = $res.Properties.useraccountcontrol[0]
        $memberOf = @($res.Properties.memberof)

        $isSensitive = [bool]($uac -band $NOT_DELEGATED)
        $isProtectedUser = [bool]($memberOf -like 'CN=Protected Users,*').Count

        -not ($isSensitive -or $isProtectedUser)
    }
}

Test-IsDelegatable -UserName username
