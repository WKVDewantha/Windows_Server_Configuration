# Windows Server 2022 Configuration Guide

A step-by-step tutorial for configuring Windows Server 2022 with Active Directory, Group Policy, and essential services.

## 📋 Overview

This guide covers the essential configuration tasks for setting up a Windows Server 2022 environment, including corrections to common mistakes found in training materials.

### Domain Information
- **Domain Name:** `univotech.local`
- **Server Name:** `UNI-SRV01`
- **Sample IP:** `192.168.10.10`

---

## ⚠️ Important Corrections

Before following this tutorial, note these critical corrections:

| Issue | Incorrect Approach | Correct Solution |
|-------|-------------------|------------------|
| **Bulk User Import** | Missing or incomplete PowerShell script | Complete script provided with proper domain targeting |
| **Folder Redirection** | Local path used (`C:\...`) | UNC network path required (`\\ServerName\Share`) |

---

## 🚀 Configuration Steps

### 1. Basic Server Configuration

#### Step 1.1: Rename the Server
1. Open **Server Manager** → **Local Server**
2. Click on the current computer name
3. Change it to **UNI-SRV01**
4. Restart the server when prompted

#### Step 1.2: Configure Static IP
1. Open **Control Panel** → **Network and Sharing Center** → **Change adapter settings**
2. Right-click your network adapter → **Properties**
3. Select **Internet Protocol Version 4 (TCP/IPv4)** → **Properties**
4. Configure the following:
   - **IP Address:** `192.168.10.10`
   - **Subnet Mask:** `255.255.255.0`
   - **Default Gateway:** `192.168.10.1`
   - **Preferred DNS:** `192.168.10.10` (points to itself after DC promotion)

#### Step 1.3: Post-Installation Settings
1. **Enable Remote Desktop:**
   - Server Manager → Local Server → Remote Desktop → **Enabled**
2. **Disable IE Enhanced Security:**
   - Server Manager → Local Server → IE Enhanced Security Configuration
   - Set **Administrators** to **Off**
3. **Set Time Zone:**
   - Server Manager → Local Server → Time Zone
   - Example: UTC+05:30 Sri Jayawardenepura

---

### 2. Install Active Directory Domain Services (AD DS)

#### Step 2.1: Add the AD DS Role
1. Open **Server Manager** → **Manage** → **Add Roles and Features**
2. Select **Role-based or feature-based installation**
3. Choose your local server
4. Check **Active Directory Domain Services**
5. (Optional) Check **DNS Server** for lab environments
6. Click **Next** through the wizard and **Install**

#### Step 2.2: Promote to Domain Controller
1. After installation, click the **yellow warning flag** in Server Manager
2. Select **Promote this server to a domain controller**
3. Choose **Add a new forest**
4. Set **Root domain name:** `univotech.local`
5. Set the **DSRM password** (save this securely!)
6. Complete the wizard with default settings
7. Restart when prompted

---

### 3. Create OU Structure and Bulk User Creation

#### Step 3.1: Create Organizational Units
1. Open **Active Directory Users and Computers** (Run `dsa.msc`)
2. Right-click your domain (`univotech.local`)
3. Select **New** → **Organizational Unit**
4. Create the parent OU: **UNIVOTECH**
5. Inside UNIVOTECH, create these child OUs:
   - **Admins**
   - **HR**
   - **Sales**
   - **IT**

#### Step 3.2: Prepare CSV File for Bulk Import
Create a CSV file named `SalesUsers.csv` in `C:\Exam\` with this format:

```csv
FirstName	LastName	Username	Password	OU
Dinusha	Perera	dperera	P@ssw0rd!	Users
Priyantha	Fernando	pfernando	P@ssw0rd!	Users
Lakshitha	Silva	lsilva	P@ssw0rd!	Users
Chaminda	Bandara	cbandara	P@ssw0rd!	Users
Anjali	Rathnayake	arathnayake	P@ssw0rd!	Users
Sandun	Weerasinghe	sweerasinghe	P@ssw0rd!	Users
Niroshan	Fonseka	nfonseka	P@ssw0rd!	Users
Tharindu	Jayawardena	tjayawardena	P@ssw0rd!	Users
Dulari	Wickramasinghe	dwickramasinghe	P@ssw0rd!	Users
Kasun	Rajapaksa	krajapaksa	P@ssw0rd!	Users
Shamila	Gunawardena	sgunawardena	P@ssw0rd!	Users
Isuru	Zoysa	izoysa	P@ssw0rd!	Users
Sithara	Abeywickrama	sabeywickrama	P@ssw0rd!	Users
Ruwan	Dissanayake	rdissanayake	P@ssw0rd!	Users
Maheshi	Peiris	mpeiris	P@ssw0rd!	Users
Vijay	Kumar	vkumar	P@ssw0rd!	Users
Kavitha	Rajendran	krajendran	P@ssw0rd!	Users
Suresh	Chandran	schandran	P@ssw0rd!	Users
Meena	Pathmanathan	mpathmanathan	P@ssw0rd!	Users
Arjun	Sivarajah	asivarajah	P@ssw0rd!	Users

```

#### Step 3.3: Run Bulk User Import Script
1. Open **PowerShell as Administrator**
2. Copy and run this script:

```powershell
# Updated script for univotech.local domain
Import-Csv "C:\Exam\SalesUsers.csv" | ForEach-Object {
    # Define the target OU path
    $OUPath = "OU=Sales,OU=UNIVOTECH,DC=univotech,DC=local"
    
    # Define the User Principal Name
    $UserPrincipalName = "$($_.Username)@univotech.local"
    
    New-ADUser `
        -Name "$($_.FirstName) $($_.LastName)" `
        -GivenName $_.FirstName `
        -Surname $_.LastName `
        -SamAccountName $_.Username `
        -UserPrincipalName $UserPrincipalName `
        -AccountPassword (ConvertTo-SecureString $_.Password -AsPlainText -Force) `
        -Path $OUPath `
        -Enabled $true
}
```

3. Verify users were created in **Active Directory Users and Computers**

---

### 4. Configure Group Policy Objects (GPOs)

#### Step 4.1: Configure Password Policy
1. Open **Group Policy Management** (Run `gpmc.msc`)
2. Expand **Forest** → **Domains** → **univotech.local**
3. Right-click **Default Domain Policy** → **Edit**
4. Navigate to: **Computer Configuration** → **Policies** → **Windows Settings** → **Security Settings** → **Account Policies** → **Password Policy**
5. Configure:
   - **Minimum password length:** `8 characters`
   - **Password must meet complexity requirements:** `Enabled`
   - **Maximum password age:** `90 days` (adjust as needed)

#### Step 4.2: Create UNI Security GPO
1. In Group Policy Management, right-click **Group Policy Objects** → **New**
2. Name it: **UNI Security GPO**
3. Right-click the new GPO → **Edit**

**Configure the following settings:**

##### Disable Guest Account
- Navigate to: **Computer Configuration** → **Policies** → **Windows Settings** → **Security Settings** → **Local Policies** → **Security Options**
- Find: **Accounts: Guest account status**
- Set to: **Disabled**

##### USB Lock (Disable Removable Storage)
- Navigate to: **Computer Configuration** → **Policies** → **Administrative Templates** → **System** → **Removable Storage Access**
- Find: **All Removable Storage classes: Deny all access**
- Set to: **Enabled**

##### Disable Control Panel
- Navigate to: **User Configuration** → **Policies** → **Administrative Templates** → **Control Panel**
- Find: **Prohibit access to Control Panel and PC settings**
- Set to: **Enabled**

##### Enforce Desktop Wallpaper
- Navigate to: **User Configuration** → **Policies** → **Administrative Templates** → **Desktop** → **Desktop**
- Find: **Desktop Wallpaper**
- Set to: **Enabled**
- Specify wallpaper path (e.g., `C:\Wallpapers\company_logo.jpg`)

#### Step 4.3: 🔧 CORRECTED - Folder Redirection

**⚠️ Critical:** Folder redirection MUST use a UNC network path, not a local path.

##### Prepare the Share (on server)
1. Create folder: `C:\RedirectedFolders`
2. Right-click folder → **Properties** → **Sharing** → **Advanced Sharing**
3. Check **Share this folder**
4. Share name: `RedirectedFolders`
5. Click **Permissions** → Grant appropriate groups **Change** permissions
6. On **Security** tab, ensure users have **Modify** NTFS permissions

##### Configure Folder Redirection
1. In the **UNI Security GPO** editor:
2. Navigate to: **User Configuration** → **Policies** → **Windows Settings** → **Folder Redirection** → **Desktop**
3. Right-click **Desktop** → **Properties**
4. Setting: **Basic - Redirect everyone's folder to the same location**
5. Target folder location: **Create a folder for each user under the root path**
6. Root Path: `\\UNI-SRV01\RedirectedFolders`
7. Click **OK**

#### Step 4.4: Link and Apply GPO
1. In Group Policy Management, right-click target OUs (HR, Sales, IT)
2. Select **Link an Existing GPO**
3. Choose **UNI Security GPO**
4. On client computers, run: `gpupdate /force`

---

### 5. Folder Structure and Permissions

#### Step 5.1: Create Department Folders
1. Create folder: `C:\CompanyData`
2. Inside, create subfolders:
   - `HR`
   - `Sales`
   - `IT`
   - `Admins`

#### Step 5.2: Share Department Folders
For each department folder:
1. Right-click folder → **Properties** → **Sharing** → **Advanced Sharing**
2. Check **Share this folder**
3. Share name: Use folder name (e.g., `HR`, `Sales`)
4. Click **Permissions** → Configure share permissions

#### Step 5.3: Assign NTFS Permissions
For each department folder:
1. Right-click folder → **Properties** → **Security** tab
2. Click **Edit** → **Add**
3. Configure permissions:
   - **HR folder:** Grant **HR users group** → **Modify**
   - **Sales folder:** Grant **Sales users group** → **Modify**
   - **IT folder:** Grant **IT users group** → **Full Control**
   - **Admins folder:** Grant **Domain Admins** → **Full Control**
4. Remove unnecessary permissions (like **Everyone** or **Users**)

#### Step 5.4: Enable Auditing
1. First, enable auditing in Group Policy:
   - Edit **Default Domain Policy**
   - Navigate to: **Computer Configuration** → **Policies** → **Windows Settings** → **Security Settings** → **Local Policies** → **Audit Policy**
   - Set **Audit object access** to **Success, Failure**

2. Configure folder auditing:
   - Right-click target folder (e.g., HR) → **Properties** → **Security** → **Advanced**
   - Click **Auditing** tab → **Add**
   - Select principal (e.g., **Everyone**)
   - Type: **All**
   - Configure: Check **Success** and **Failure** for:
     - Read
     - Write
     - Delete
   - Click **OK**

---

### 6. Install IIS and Host a Website

#### Step 6.1: Install IIS Role
1. Open **Server Manager** → **Manage** → **Add Roles and Features**
2. Select **Role-based or feature-based installation**
3. Choose your local server
4. Check **Web Server (IIS)**
5. Click **Add Features** when prompted
6. Complete the wizard and install

#### Step 6.2: Configure Website
1. Open **Internet Information Services (IIS) Manager**
2. Expand the server node in the left panel
3. Right-click **Sites** → **Add Website**
4. Configure:
   - **Site name:** `CompanyWebsite`
   - **Physical path:** `C:\inetpub\CompanyWebsite` (create this folder)
   - **Binding:** IP address: `192.168.10.10`, Port: `80`
5. Click **OK**

#### Step 6.3: Add Website Content
1. Navigate to `C:\inetpub\CompanyWebsite`
2. Create a simple `index.html` file:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Univotech</title>
</head>
<body>
    <h1>Welcome to Univotech Corporation</h1>
    <p>This is our internal web server.</p>
</body>
</html>
```

#### Step 6.4: Test the Website
1. Open a web browser
2. Navigate to: `http://192.168.10.10`
3. You should see your website

---

## 🔍 Testing and Verification

### Test Checklist
- [ ] Server has correct name: `UNI-SRV01`
- [ ] Static IP configured: `192.168.10.10`
- [ ] Domain controller promotion successful
- [ ] OU structure created correctly
- [ ] Bulk users imported into Sales OU
- [ ] Password policy enforced (8 characters minimum)
- [ ] GPO settings applied correctly
- [ ] Folder redirection using UNC path
- [ ] Department folders accessible via network shares
- [ ] NTFS permissions working correctly
- [ ] File auditing enabled and logging
- [ ] IIS website accessible

### Common Troubleshooting

**Issue: Users can't log in**
- Verify accounts are enabled in AD
- Check password policies aren't too restrictive
- Ensure DNS is resolving correctly

**Issue: GPO not applying**
- Run `gpupdate /force` on client
- Check GPO is linked to correct OU
- Verify no conflicting policies
- Use `gpresult /r` to check applied policies

**Issue: Folder redirection not working**
- Verify UNC path is correct: `\\ServerName\ShareName`
- Check share and NTFS permissions
- Ensure network connectivity between client and server
- Review GPO settings for folder redirection

**Issue: Can't access network shares**
- Verify share permissions are configured
- Check NTFS permissions on folders
- Ensure firewall allows file sharing
- Test with UNC path: `\\UNI-SRV01\ShareName`


**Created for:** Windows Server 2022 Practice Lab  
**Domain:** univotech.local  
**Last Updated:** 2025
