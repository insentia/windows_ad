##
##
##
class windows_ad (
  ### part install AD
  $install                   = 'present',
  $installmanagementtools    = true,
  $installsubfeatures        = false,
  $restart                   = false,

  ### Part Configure AD - Global
  $configure                 = 'present',
  $domain                    = 'forest',
  $domainname                = undef,                # FQDN
  $netbiosdomainname         = undef,                # FQDN

  #level AD
  $domainlevel               = '6',                   # Domain level {4 - Server 2008 R2 | 5 - Server 2012 | 6 - Server 2012 R2}
  $forestlevel               = '6',                   # Domain level {4 - Server 2008 R2 | 5 - Server 2012 | 6 - Server 2012 R2}

  $installdns                = 'yes',                 # Add DNS Server Role
  $globalcatalog             = 'yes',                 # Add Global Catalog functionality
  $kernel_ver                = $::kernelversion,

  # Installation Directories
  $databasepath              = 'c:\\windows\\ntds',   # Active Directory database path
  $logpath                   = 'c:\\windows\\ntds',   # Active Directory log path
  $sysvolpath                = 'c:\\windows\\sysvol', # Active Directory sysvol path

  $dsrmpassword              = undef,

  ### Part Configure AD - Forest

  #uninstall forest
  $localadminpassword        = undef,
  $force                     = 'true',
  $forceremoval              = 'true',
  $uninstalldnsrole          = 'yes',
  $demoteoperationmasterrole = 'true',
  
  ### Part Configure AD - Other
  $secure_string_pwd         = undef,
  $installtype               = undef,          # New domain or replica of existing domain {replica | domain} 
  $domaintype                = undef,          # Type of domain {Tree | Child | Forest} (New domain tree in an existing forest, child domain, or new forest)
  $sitename                  = undef,          # Site Name 

) {

  # when present install process will be set. if already install nothing done
  # when absent uninstall will be launch
  validate_re($install, '^(present|absent)$', 'valid values for install are \'present\' or \'absent\'')
  # when present configure process will be done. if already configure nothing done
  # absent don't do anything right now
  validate_re($configure, '^(present|absent)$', 'valid values for configure are \'present\' or \'absent\'')

  class{'windows_ad::install': 
    ensure                 => $install,
	installmanagementtools => $installmanagementtools,
	installsubfeatures     => $installsubfeatures,
	restart                => $restart,
  }
  
  class{'windows_ad::conf_forest': 
    ensure                    => $configure,
    domainname                => $domainname,
    netbiosdomainname         => $netbiosdomainname,
    domainlevel               => $domainlevel,
    forestlevel               => $forestlevel,
    globalcatalog             => $globalcatalog,
    databasepath              => $databasepath,
    logpath                   => $logpath,
    sysvolpath                => $sysvolpath,
    dsrmpassword              => $dsrmpassword,
    installdns                => $installdns,
    kernel_ver                => $kernel_ver,
	localadminpassword        => $localadminpassword,
    force                     => $force,
    forceremoval              => $forceremoval,
    uninstalldnsrole          => $uninstalldnsrole,
	demoteoperationmasterrole => $demoteoperationmasterrole,
  }
  if($install == 'present'){
    Class['windows_ad::install'] -> Class['windows_ad::conf_forest']
  }else{
    if($configure == present){
      fail('You can\'t desactivate the Role ADDS without uninstall ADDSControllerDomain first')
    }else{
      Class['windows_ad::conf_forest'] -> Class['windows_ad::install']
    }
  }
  
}