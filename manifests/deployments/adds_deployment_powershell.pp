class windows_ad::deployments::adds_deployment_powershell (
  $type,
  $domainname,
  $domainlevel,
  $netbiosdomainname,
  $forestlevel,
  $databasepath,
  $logpath,
  $sysvolpath,
  $dsrmpassword,
  $timeout,
) {

  if ($type == 'ntp') {
    $command = "Import-Module ADDSDeployment; Install-ADDSForest -Force -DomainName ${domainname} -DomainMode ${domainlevel} -DomainNetbiosName ${netbiosdomainname} -ForestMode ${forestlevel} -DatabasePath ${databasepath} -LogPath ${logpath} -SysvolPath ${sysvolpath} -SafeModeAdministratorPassword (convertto-securestring '${dsrmpassword}' -asplaintext -force) -InstallDns"
    } else  {
      $command = "Import-Module ADDSDeployment; Install-ADDSForest -Force -DomainName ${domainname} -DomainMode ${domainlevel} -DomainNetbiosName ${netbiosdomainname} -ForestMode ${forestlevel} -DatabasePath ${databasepath} -LogPath ${logpath} -SysvolPath ${sysvolpath} -SafeModeAdministratorPassword (convertto-securestring '${dsrmpassword}' -asplaintext -force)"
    }

  exec { 'Config ADDS':
    command     => $command,
    provider    => powershell,
    onlyif      => "if((gwmi WIN32_ComputerSystem).Domain -eq \'${domainname}\'){exit 1}",
    timeout     => $timeout,
  }
}
