Import-Module ActiveDirectory
function Get-UserInfo
{
    <# 
    .SYNOPSIS 
        This function will get information about user account.
 
    .DESCRIPTION 
        This function will get information about user password expiration date or last password change.

    .PARAMETER Username
         Specifies the username.
  
    .EXAMPLE 
        PS C:\> Get-UserPasswordInfo -Username foo
        This command gets basic and password information for 'foo' user.
 
    .NOTES
        Author:       Daniel Schwitzgebel
        Created:      07/08/2014
        Modified:     14/04/2020
        Version:      2.0.2   
#>

    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()] 
    param ( 
        [Parameter(Mandatory)] 
        [String]
        $Username
    )
    
    process
    {
        try
        {
            $getADUserProperties = @(
                'PasswordExpired',
                'PasswordNeverExpires',
                'BadPwdCount',
                'PasswordLastSet',
                'lastBadPasswordAttempt',
                'LockedOut',
                'LastLogon',
                'SID',
                'l',
                'Comment'
            )

            $usrInfo = Get-ADUser -Identity $Username -Properties $getADUserProperties
        }
        catch
        {
            throw 'User not found in Active Directory.'
        }

        $maxPswAgeTime = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
        $minPswAgeTime = (Get-ADDefaultDomainPasswordPolicy).MinPasswordAge
        $pswLockoutThreshold = (Get-ADDefaultDomainPasswordPolicy).LockoutThreshold
        $usrLastLogon = [DateTime]::FromFileTime($usrInfo.LastLogon)
      
        [PSCustomObject]@{
            Username   = $Username
            Name       = "$($usrInfo.GivenName) $($usrInfo.Surname)"
            SID        = $usrInfo.SID
            Location   = $usrInfo.l
            Department = $usrInfo.Comment
            LastLogon  = $usrLastLogon
            LockedOut  = $usrInfo.LockedOut
        }

        [PSCustomObject]@{
            PasswordLastSet        = $usrInfo.PasswordLastSet
            PasswordExpired        = $usrInfo.PasswordExpired
            PasswordExpirationDate = ($usrInfo.PasswordLastSet + $maxPswAgeTime)
            lastBadPasswordAttempt = $usrInfo.lastBadPasswordAttempt
            PasswordChangeable     = ($usrInfo.PasswordLastSet).AddDays($minPswAgeTime.TotalDays)
            PasswordBadCount       = "$($usrInfo.BadPwdCount) of $pswLockoutThreshold"
            PasswordNeverExpires   = $usrInfo.PasswordNeverExpires
        }
    }
}