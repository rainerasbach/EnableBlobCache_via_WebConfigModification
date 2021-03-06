<#
.SYNOPSIS
    Enables and configures the SharePoint BLOB Cache. 

    based upon
    http://blog.kuppens-switsers.net/sharepoint/enabling-blob-cache-sharepoint-using-powershell/
    
.DESCRIPTION
    Enables and configures the SharePoint BLOB Cache. 

.NOTES
    File Name: Enable-BlobCache.ps1
    Author   : Bart Kuppens
    Version  : 2.0

    File Name: EnableBlobCache_via_WebConfigModification.PS1
    Author   : Rainer Asbach
    Version  : 3.0

    If you have to modify the value for the file extensions that are included in the BlobCache you can change this in the code


.PARAMETER Url
    Specifies the URL of the Web Application for which the BLOB cache should be enabled. 

.PARAMETER Location
    Specifies the location of the BLOB Cache. 	 

.EXAMPLE
    PS > .\EnableBlobCache_via_WebConfigModification.ps1 -Url http://intranet.westeros.local -Location d:\BlobCache\Intranet

   Description
   -----------
   This script enables the BLOB cache for the http://intranet.westeros.local web application and stores
   it under d:\blobcache\intranet

.ToDo
   Add a parameter for the file extensions
   Add a parameter to add or remove file extensions
   Add a parameter that shows the current values

.Versions
   3.0
     Added the option to set the file extensions
     Added the option to overwrite the settings
   3.1
     Added parameters for DisableBlobCache, BlobCacheSize,MaxAge,WebConfigModifcationOwner with proper defaults
     Added  -reset parameter to set the defaults
   
#>
param( 
   [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)] 
   [string]$Url,
   [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=1)] 
   [string]$Location="C:\BlobCache\14",
   [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=2)]
   [string]$BlobCacheMaxSizeInGB="10", 
   [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=3)] 
   [switch]$DisableBlobCache,
   [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=4)]
   [string]$MaxAgeInSeconds="86400", 
   [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=5)]
   [string]$WebConfigModificationOwner="BlobCacheMod", 
   [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=6)]
   [switch]$Reset
) 
 

 $filePath = "\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
   Add-PSSnapin Microsoft.SharePoint.PowerShell
}
 
$webApp = Get-SPWebApplication $Url

if ($Reset)
{
   $Location="C:\BlobCache\14"
   $BlobCacheMaxSizeInGB="10"
   $DisableBlobCache=$true
   $MaxAgeInSeconds="86400"
   $WebConfigModificationOwner="BlobCacheMod"
}

if ($DisableBlobCache)
{
    $BlobCacheEnabled="false"
}
else
{
    $BlobCacheEnabled="true"
}



$modifications = $webApp.WebConfigModifications | ? { $_.Owner -eq $WebConfigModificationOwner }
if ($modifications.Count -ne $null -and $modifications.Count -gt 0)
{
    Write-Host -ForegroundColor Yellow "Modifications have already been added!"
    $a= read-Host "Re-Create Entries? (Y/N)"
    if ($a -ne 'y')
    {
        break
    }

    for ($i=$modifications.count-1;$i -ge 0;$i--)
    {
        $c = ($webApp.WebConfigModifications | ? {$_.Owner -eq $WebConfigModificationOwner})[$i] 
        $r = $webApp.WebConfigModifications.Remove($c)
    }

    $webApp.update()
    $webApp.Parent.ApplyWebConfigModifications()
}
 
# Enable/Disable Blob cache
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config1.Path = "configuration/SharePoint/BlobCache" 
$config1.Name = "enabled"
$config1.Value = $BlobCacheEnabled
$config1.Sequence = 0
$config1.Owner = $WebConfigModificationOwner 
$config1.Type = 1 
 
# add max-age attribute
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config2 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config2.Path = "configuration/SharePoint/BlobCache" 
$config2.Name = "max-age"
$config2.Value = $MaxAgeInSeconds
$config2.Sequence = 0
$config2.Owner = $WebConfigModificationOwner 
$config2.Type = 1 
 
# Set the location
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config3 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config3.Path = "configuration/SharePoint/BlobCache" 
$config3.Name = "location"
$config3.Value = $Location
$config3.Sequence = 0
$config3.Owner = $WebConfigModificationOwner 
$config3.Type = 1

# Set the File Types
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config4 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config4.Path = "configuration/SharePoint/BlobCache" 
$config4.Name = "path"
$config4.Value = $FilePath
$config4.Sequence = 0
$config4.Owner = $WebConfigModificationOwner 
$config4.Type = 1

# Set the size of the BlobCache in GB
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config5 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config5.Path = "configuration/SharePoint/BlobCache" 
$config5.Name = "maxSize"
$config5.Value = $BlobCacheMaxSizeInGB
$config5.Sequence = 0
$config5.Owner = $WebConfigModificationOwner 
$config5.Type = 1
 

#Add mods to webapp and apply to web.config
$webApp.WebConfigModifications.Add($config1)
$webApp.WebConfigModifications.Add($config2)
$webApp.WebConfigModifications.Add($config3)
$webApp.WebConfigModifications.Add($config4)
$webApp.WebConfigModifications.Add($config5)
$webApp.update()
$webApp.Parent.ApplyWebConfigModifications()

#$webApp.WebConfigModifications