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
#
# === Copyright
#
# Copyright 2014 Jerome RIVIERE.
#
class windows_ad::conf_forest (
  #install parameters
  $domainname                = $domainname,
  $netbiosdomainname         = $netbiosdomainname,
  $domainlevel               = $domainlevel,
  $forestlevel               = $forestlevel,
  $globalcatalog             = $globalcatalog,
  $databasepath              = $databasepath,
  $logpath                   = $logpath,
  $sysvolpath                = $sysvolpath,
  $dsrmpassword              = $dsrmpassword,
  $installdns                = $installdns,
  $kernel_ver                = $kernel_ver,
  $timeout                   = 0,

){
    # If the operating is server 2012 then run the appropriate powershell commands if not revert back to the cmd commands
      if ($kernel_ver =~ /^6\.2|^6\.3/) {
        if ($installdns == 'yes'){
          # Deploy Server 2012 Active Directory
          exec { 'Config ADDS':
            command     => "Import-Module ADDSDeployment; Install-ADDSForest -Force -DomainName ${domainname} -DomainMode ${domainlevel} -DomainNetbiosName ${netbiosdomainname} -ForestMode ${forestlevel} -DatabasePath ${databasepath} -LogPath ${logpath} -NoRebootOnCompletion -SysvolPath ${sysvolpath} -SafeModeAdministratorPassword (convertto-securestring '${dsrmpassword}' -asplaintext -force) -InstallDns",
            provider    => powershell,
            onlyif      => "if((gwmi WIN32_ComputerSystem).Domain -eq \'${domainname}\'){exit 1}",
            notify      => Reboot['after dcpromo'],
            timeout     => $timeout,
          }
        }else{
          # Deploy Server 2012 Active Directory Without DNS
          exec { 'Config ADDS':
            command     => "Import-Module ADDSDeployment; Install-ADDSForest -Force -DomainName ${domainname} -DomainMode ${domainlevel} -DomainNetbiosName ${netbiosdomainname} -ForestMode ${forestlevel} -DatabasePath ${databasepath} -LogPath ${logpath} -NoRebootOnCompletion -SysvolPath ${sysvolpath} -SafeModeAdministratorPassword (convertto-securestring '${dsrmpassword}' -asplaintext -force)",
            provider    => powershell,
            onlyif      => "if((gwmi WIN32_ComputerSystem).Domain -eq \'${domainname}\'){exit 1}",
            notify      => Reboot['after dcpromo'],
            timeout     => $timeout,
          }
        }
      }else {
        # Deploy Server 2008 R2 Active Directory
        exec { 'Config ADDS 2008':
          command => "cmd.exe /c dcpromo /unattend /InstallDNS:yes /confirmGC:${globalcatalog} /NewDomain:forest /NewDomainDNSName:${domainname} /domainLevel:${domainlevel} /forestLevel:${forestlevel} /ReplicaOrNewDomain:domain /databasePath:${databasepath} /logPath:${logpath} /sysvolPath:${sysvolpath} /SafeModeAdminPassword:${dsrmpassword} /RebootOnCompletion:No",
          path    => 'C:\windows\sysnative',
          returns => [1,2,3,4],
          unless  => "sc \\\\${::fqdn} query ntds",
          notify  => Reboot['after dcpromo'],
          timeout => $timeout,
        }
      }
      reboot { 'after dcpromo':
        apply => immediately,
      }
}
