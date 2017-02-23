class windows_ad::params {
  $install                   = 'present'
  $installmanagementtools    = true
  $installsubfeatures        = false
  $restart                   = false
  $installflag               = true
  $configure                 = 'present'
  $domain                    = 'forest'
  $domainname                = undef
  $netbiosdomainname         = undef
  $configureflag             = true
  $domainlevel               = '6'
  $forestlevel               = '6'
  $installdns                = 'yes'
  $globalcatalog             = 'yes'
  $kernel_ver                = $::kernelversion
  $databasepath              = 'c:\\windows\ntds'
  $logpath                   = 'c:\\windows\ntds'
  $sysvolpath                = 'c:\\windows\sysvol'
  $dsrmpassword              = undef

  $localadminpassword        = undef
  $force                     = true
  $forceremoval              = true
  $uninstalldnsrole          = 'yes'
  $demoteoperationmasterrole = true

  $secure_string_pwd         = undef
  $installtype               = undef
  $domaintype                = undef
  $sitename                  = undef

  $groups                    = undef
  $groups_hiera_merge        = true
  $users                     = undef
  $users_hiera_merge         = true
  $usersingroup              = undef
  $usersingroup_hiera_merge  = true

  $timeout                   = 240
}
