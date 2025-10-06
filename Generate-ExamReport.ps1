# ============================================
# UNC Limited / Univotec - Exam Report Script
# Generates HTML report of server configuration
# ============================================

# Output path
$ReportPath = "C:\ExamReport.html"

# Collect basic system information
$ComputerInfo = Get-ComputerInfo | Select-Object CsName, WindowsVersion, OsName, OsArchitecture, CsDomain, TimeZone, CsManufacturer, CsModel
$NetworkInfo  = Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress, PrefixLength, DefaultGateway
$DNSInfo      = Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, ServerAddresses

# Active Directory Information (if available)
Try {
    Import-Module ActiveDirectory -ErrorAction Stop
    $DomainInfo  = Get-ADDomain | Select-Object DNSRoot, DomainMode, Forest, ForestMode
    $Users       = Get-ADUser -Filter * -Properties * | Select-Object Name, SamAccountName, Enabled, PasswordLastSet, PasswordNeverExpires
    $OUs         = Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
    $Groups      = Get-ADGroup -Filter * | Select-Object Name, GroupScope, GroupCategory
}
Catch {
    Write-Host "AD Module not found or not a domain controller. Skipping AD checks..."
    $DomainInfo = $null; $Users = $null; $OUs = $null; $Groups = $null
}

# Group Policy Information
Try {
    $GPOs = Get-GPO -All | Select-Object DisplayName, CreationTime, ModificationTime, GpoStatus
}
Catch {
    $GPOs = $null
}

# IIS Website Info
Try {
    Import-Module WebAdministration -ErrorAction Stop
    $Sites = Get-Website | Select-Object Name, State, PhysicalPath, BindingInformation
}
Catch {
    $Sites = $null
}

# Generate HTML sections
$HTML = @"
<html>
<head>
<title>Windows Server 2022 Exam Report</title>
<style>
body { font-family: Arial; margin: 20px; background: #f8f9fa; }
h2 { color: #003366; border-bottom: 2px solid #003366; padding-bottom: 4px; }
table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
th { background: #003366; color: white; }
</style>
</head>
<body>
<h1>UNC Limited / Univotec Exam Report</h1>
<p>Generated on $(Get-Date)</p>
<hr/>
<h2>1. System Information</h2>
$($ComputerInfo | ConvertTo-Html -Fragment)

<h2>2. Network Configuration</h2>
$($NetworkInfo | ConvertTo-Html -Fragment)

<h2>3. DNS Settings</h2>
$($DNSInfo | ConvertTo-Html -Fragment)

<h2>4. Active Directory Domain</h2>
$($DomainInfo | ConvertTo-Html -Fragment)

<h2>5. Organizational Units</h2>
$($OUs | ConvertTo-Html -Fragment)

<h2>6. Users</h2>
$($Users | ConvertTo-Html -Fragment)

<h2>7. Groups</h2>
$($Groups | ConvertTo-Html -Fragment)

<h2>8. Group Policies</h2>
$($GPOs | ConvertTo-Html -Fragment)

<h2>9. IIS Websites</h2>
$($Sites | ConvertTo-Html -Fragment)

</body>
</html>
"@

# Write report to disk
$HTML | Out-File -FilePath $ReportPath -Encoding UTF8
Write-Host "Exam report generated successfully at $ReportPath" -ForegroundColor Green
