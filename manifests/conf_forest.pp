# Class: windows_ad
#
# Full description of windows_ad::conf_forest here.
#
# This class allow you to configure/unconfigure a windows domain forest
#
# When you use this class please use it with windows_ad directly. see the readme file.
#
# === Parameters
#
#
# === Examples
#
#  class{'windows_ad::conf_forest':
#    ensure                    => present,
#    domainname                => 'jre.local',
#    netbiosdomainname         => 'jre',
#    domainlevel               => '6',
#    forestlevel               => '6',
#    globalcatalog             => 'yes',
#    databasepath              => 'c:\\windows\\ntds',
#    logpath                   => 'c:\\windows\\ntds',
#    sysvolpath                => 'c:\\windows\\sysvol',
#    dsrmpassword              => $dsrmpassword,
#    installdns                => 'yes',
#    localadminpassword        => 'password',
#    force                     => true,
#    forceremoval              => true,
#    uninstalldnsrole          => 'yes',
#    demoteoperationmasterrole => true,
#  }
#
# === Authors
#
# Jerome RIVIERE (www.jerome-riviere.re)
# Karol Kozakowski <cosaquee@gmail.com>
#
# === Copyright
#
# Copyright 2014 Jerome RIVIERE.
# Copyright 2017 Karol Kozakowski <cosaquee@gmail.com>
#
class windows_ad::conf_forest (
  $ensure,
  $domainname,
  $netbiosdomainname,
  $domainlevel,
  $forestlevel,
  $globalcatalog,
  $databasepath,
  $logpath,
  $sysvolpath,
  $dsrmpassword,
  $installdns,
  $kernel_ver,
  $configureflag,
  $localadminpassword,
  $force,
  $forceremoval,
  $uninstalldnsrole,
  $demoteoperationmasterrole,
  $timeout,
){
  validate_bool($configureflag)
  if ($configureflag == true){
    if $force { $forcebool = 'true' } else { $forcebool = 'false' }
    if $forceremoval { $forceboolremoval = 'true' } else { $forceboolremoval = 'false' }
    if $demoteoperationmasterrole { $demoteoperationmasterrolebool = 'true' } else { $demoteoperationmasterrolebool = 'false' }

    # If the operating is server 2012 or 2016 then run the appropriate powershell commands if not revert back to the cmd commands
    if ($ensure == 'present') {
      if ($kernel_ver =~ /^6\.2|^6\.3|^10\.0/) {
        if ($installdns == 'yes'){
          # Deploy Server 2016 Active Directory
          class { 'windows_ad::deployments::adds_deployment_powershell':
            type              => 'ntp',
            domainname        => $domainname,
            domainlevel       => $domainlevel,
            netbiosdomainname => $netbiosdomainname,
            forestlevel       => $forestlevel,
            databasepath      => $databasepath,
            logpath           => $logpath,
            sysvolpath        => $sysvolpath,
            dsrmpassword      => $dsrmpassword,
            timeout           => $timeout
          }
        } else{
          class { 'windows_ad::deployments::adds_deployment_powershell':
            type              => '',
            domainname        => $domainname,
            domainlevel       => $domainlevel,
            netbiosdomainname => $netbiosdomainname,
            forestlevel       => $forestlevel,
            databasepath      => $databasepath,
            logpath           => $logpath,
            sysvolpath        => $sysvolpath,
            dsrmpassword      => $dsrmpassword,
            timeout           => $timeout
          }
        }
      }else {
        # Deploy Server 2008 R2 Active Directory
        exec { 'Config ADDS 2008':
          command => "cmd.exe /c dcpromo /unattend /InstallDNS:yes /confirmGC:${globalcatalog} /NewDomain:forest /NewDomainDNSName:${domainname} /domainLevel:${domainlevel} /forestLevel:${forestlevel} /ReplicaOrNewDomain:domain /databasePath:${databasepath} /logPath:${logpath} /sysvolPath:${sysvolpath} /SafeModeAdminPassword:${dsrmpassword}",
          path    => 'C:\windows\sysnative',
          unless  => "sc \\\\${::fqdn} query ntds",
          timeout => $timeout,
        }
      }
    }else{ #uninstall AD
      if ($kernel_ver =~ /^6\.2|^6\.3|^10\.0/) {
        if($localadminpassword != ''){
          exec { 'Uninstall ADDS':
            command     => "Import-Module ADDSDeployment;Uninstall-ADDSDomainController -LocalAdministratorPassword (ConvertTo-SecureString \'${localadminpassword}\' -asplaintext -force) -Force:$${forcebool} -ForceRemoval:$${forceboolremoval} -DemoteOperationMasterRole:$${demoteoperationmasterrolebool} -SkipPreChecks",
            provider    => powershell,
            onlyif      => "if((gwmi WIN32_ComputerSystem).Domain -eq 'WORKGROUP'){exit 1}",
            timeout     => $timeout,
          }
          if($uninstalldnsrole == 'yes'){
            exec { 'Uninstall DNS Role':
            command   => "Import-Module ServerManager; Remove-WindowsFeature DNS -Restart",
            onlyif    => "Import-Module ServerManager; if (@(Get-WindowsFeature DNS | ?{\$_.Installed -match \'true\'}).count -eq 0) { exit 1 }",
            provider  => powershell,
            }
          }
        }
      }else{
        # uninstall Server 2008 R2 Active Directory -> not tested
        exec { 'Uninstall ADDS 2008':
          command => "cmd.exe /c dcpromo /forceremoval",
          path    => 'C:\windows\sysnative',
          unless  => "sc \\\\${::fqdn} query ntds",
          timeout => $timeout,
        }
      }
    }
  }
}
