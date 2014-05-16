class windows_ad::conf_forest (
  $ensure             = 'present',
  $domainname         = $domainname,
  $netbiosdomainname  = $netbiosdomainname,
  $domainlevel        = $domainlevel,
  $forestlevel        = $forestlevel,
  $globalcatalog      = $globalcatalog,
  $databasepath       = $databasepath,
  $logpath            = $logpath,
  $sysvolpath         = $sysvolpath,
  $dsrmpassword       = $dsrmpassword,
  $installdns         = $installdns,
  $kernel_ver         = $kernel_ver,
  $timeout            = 0,
  
  #removal
  $localadminpassword = undef, #admin password required for removal
  $force              = $force,
  $forceremoval       = $forceremoval,
  $uninstalldnsrole   = $uninstalldnsrole,
) {
  if $force { $_force = 'true' } else { $_force = 'false' }
  if $forceremoval { $_forceremoval = 'true' } else { $_forceremoval = 'false' }

  # If the operating is server 2012 then run the appropriate powershell commands if not revert back to the cmd commands
  if ($ensure == 'present') {  
    if ($kernel_ver =~ /^6\.2|^6\.3/) {
      if ($installdns == 'yes'){
        # Deploy Server 2012 Active Directory
        exec { 'Config ADDS':
          command     => "Import-Module ADDSDeployment; Install-ADDSForest -Force -DomainName ${domainname} -DomainMode ${domainlevel} -DomainNetbiosName ${netbiosdomainname} -ForestMode ${forestlevel} -DatabasePath ${databasepath} -LogPath ${logpath} -SysvolPath ${sysvolpath} -SafeModeAdministratorPassword (convertto-securestring '${dsrmpassword}' -asplaintext -force) -InstallDns",
          provider    => powershell,
          onlyif      => '$_domain = (gwmi WIN32_ComputerSystem).Domain;if ($_domain -ne ${domainname}){exit 1}',
          timeout     => $timeout,
        }
      }
      else{
        # Deploy Server 2012 Active Directory Without DNS
        exec { 'Config ADDS':
          command     => "Import-Module ADDSDeployment; Install-ADDSForest -Force -DomainName ${domainname} -DomainMode ${domainlevel} -DomainNetbiosName ${netbiosdomainname} -ForestMode ${forestlevel} -DatabasePath ${databasepath} -LogPath ${logpath} -SysvolPath ${sysvolpath} -SafeModeAdministratorPassword (convertto-securestring '${dsrmpassword}' -asplaintext -force)",
          provider    => powershell,
          onlyif      => '$_domain = (gwmi WIN32_ComputerSystem).Domain;if ($_domain -ne ${domainname}){exit 1}',
          timeout     => $timeout,
        }
      }
    } else {
      # Deploy Server 2008 R2 Active Directory
      exec { 'Config ADDS 2008':
        command => "cmd.exe /c dcpromo /unattend /InstallDNS:yes /confirmGC:${globalcatalog} /NewDomain:forest /NewDomainDNSName:${domainname} /domainLevel:${domainlevel} /forestLevel:${forestlevel} /ReplicaOrNewDomain:domain /databasePath:${databasepath} /logPath:${logpath} /sysvolPath:${sysvolpath} /SafeModeAdminPassword:${dsrmpassword}",
        path    => 'C:\windows\sysnative',
        unless  => "sc \\\\${::fqdn} query ntds",
        timeout => $timeout,
      }
    }
  }else{ #uninstall AD
    if ($kernel_ver =~ /^6\.2|^6\.3/) {
      exec { 'Uninstall ADDS':
        command     => "Import-Module ServerManager;Import-Module ADDSDeployment; Uninstall-ADDSDomainController -LocalAdministratorPassword (convertto-securestring '${localadminpassword}' -asplaintext -force) -Force:$${_force} -ForceRemoval:$${_forceremoval} -DemoteOperationMasterRole:\$true -SkipPreChecks",
        provider    => powershell,
        onlyif      => "$_domain = (gwmi WIN32_ComputerSystem).Domain;if ($_domain -eq ${domainname}){exit 1}",
        timeout     => $timeout,
      }
      if($uninstalldnsrole == 'yes'){
	    exec { 'Uninstall DNS Role':
          command   => "Import-Module ServerManager; Remove-WindowsFeature DNS -Restart:\$true",
          onlyif    => "Import-Module ServerManager; if (@(Get-WindowsFeature DNS | ?{\$_.Installed -match \'true\'}).count -eq 0) { exit 1 }",
          provider  => powershell,
        }
      }
    }else{
      # uninstall Server 2008 R2 Active Directory -not tested
      exec { 'Uninstall ADDS 2008':
        command => "cmd.exe /c dcpromo /forceremoval",
        path    => 'C:\windows\sysnative',
        unless  => "sc \\\\${::fqdn} query ntds",
        timeout => $timeout,
      }
	}
  }
}