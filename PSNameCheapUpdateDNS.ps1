function Get-NameCheapDNSCredential {
    <#
    .SYNOPSIS
    Retrieves credentials for NameCheap Dynamic DNS update.

    .DESCRIPTION
    Prompts the user to enter the Dynamic DNS password and returns a hashtable containing the
    necessary information for a DNS update request.

    .PARAMETER NameCheapHost
    The subdomain or hostname for which you are updating the DNS record.

    .PARAMETER Domain
    The domain within which the host resides.

    .EXAMPLE
    $creds = Get-NameCheapDNSCredential -NameCheapHost "host" -Domain "example.com"
    This example retrieves credentials for the host "host.example.com".
    #>
    param(
        [Parameter(Mandatory = $true)]
        [Alias("Subdomain","Host")]
        [string]$NameCheapHost,
        [Parameter(Mandatory = $true)]
        [string]$NameCheapDomain
    )
    $credential = Get-Credential -UserName $NameCheapHost -Message "Enter Dynamic DNS Password"
    $NameCheapDNSCredential = @{
        NameCheapHost     = $NameCheapHost
        domain   = $NameCheapDomain
        password = $credential.Password
        ip       = $(Invoke-RestMethod "https://dynamicdns.park-your-domain.com/getip")
    }
    return $NameCheapDNSCredential
}

function Update-NameCheapDNS {
    <#
    .SYNOPSIS
    Constructs the URL for updating NameCheap DNS records based on provided credentials and IP address.
    .DESCRIPTION
    Takes credentials and an IP address to form a URI for updating DNS records via NameCheap's Dynamic DNS service.
    .PARAMETER NameCheapHost
    The subdomain or hostname for which the DNS record is updated.
    .PARAMETER Domain
    The domain within which the subdomain resides.
    .PARAMETER Password
    The secure password for the DNS update, as a SecureString.
    .PARAMETER IP
    The IP address to which the DNS record should be updated.
    .EXAMPLE
    Get-NameCheapDNSCredential | Update-NameCheapDNS 
    Constructs and prints the URL required to update the DNS record for the specified host and domain to the IP "192.0.2.1".
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Subdomain","Host")]
        [string]$NameCheapHost,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$NameCheapDomain,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [securestring]$Password,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$IP
    )
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    $NameCheapParams = @{
        host     = $NameCheapHost
        domain   = $NameCheapDomain
        password = $plainPassword
        ip       = $IP
    }
    $NameCheapQueryString = $($NameCheapParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
    $NameCheapUpdateUrl = "https://dynamicdns.park-your-domain.com/update?$NameCheapQueryString"
    $Result = invoke-RestMethod $NameCheapUpdateUrl
    if($Result.'interface-response'.ErrCount -gt 0){
        Write-error "Failed to update"
    }
    else{
        write-deebug "Update Successful"
    }
}