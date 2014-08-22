#
# Help can be found in readme.rd for a global help
#
# === Authors
#
# Jerome RIVIERE (www.jerome-riviere.re)
#
# === Copyright
#
# Copyright 2014 Jerome RIVIERE.
#
class windows_ad (
  ### part install AD
  $install                   = 'present',
  $installmanagementtools    = true,
  $installsubfeatures        = false,
  $restart                   = false,
  $installflag               = true,                 # Flag to bypass the install of AD if desired

  ### Part Configure AD - Global
  $configure                 = 'present',
  $domain                    = 'forest',
  $domainname                = undef,                # FQDN
  $netbiosdomainname         = undef,                # FQDN
  $configureflag             = true,                 # Flag to bypass the configuration of AD if desired

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
  $force                     = true,
  $forceremoval              = true,
  $uninstalldnsrole          = 'yes',
  $demoteoperationmasterrole = true,

  ### Part Configure AD - Other
  $secure_string_pwd         = undef,
  $installtype               = undef,          # New domain or replica of existing domain {replica | domain}
  $domaintype                = undef,          # Type of domain {Tree | Child | Forest} (New domain tree in an existing forest, child domain, or new forest)
  $sitename                  = undef,          # Site Name

  ### Define Hiera hashes
  $groups                    = undef,
  $groups_hiera_merge        = true,
  $users                     = undef,
  $users_hiera_merge         = true,
  $usersingroup              = undef,
  $usersingroup_hiera_merge  = true,
) {
  # when present install process will be set. if already install nothing done
  # when absent uninstall will be launch
  validate_re($install, '^(present|absent)$', 'valid values for install are \'present\' or \'absent\'')
  # when present configure process will be done. if already configure nothing done
  # absent don't do anything right now
  validate_re($configure, '^(present|absent)$', 'valid values for configure are \'present\' or \'absent\'')
  validate_bool($configureflag)
  validate_bool($installflag)
  
  class{'windows_ad::install':
    ensure                 => $install,
    installmanagementtools => $installmanagementtools,
    installsubfeatures     => $installsubfeatures,
    restart                => $restart,
    installflag            => $installflag,
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
    configureflag             => $configureflag,
  }
  if($installflag or $configureflag){
    if($install == 'present'){
      anchor{'windows_ad::begin':} -> Class['windows_ad::install'] -> Class['windows_ad::conf_forest'] -> anchor{'windows_ad::end':} -> Windows_ad::Organisationalunit <| |> -> Windows_ad::Group <| |> -> Windows_ad::User <| |> -> Windows_ad::Groupmembers <| |>
    }else{
      if($configure == present){
        fail('You can\'t desactivate the Role ADDS without uninstall ADDSControllerDomain first')
      }else{
        anchor{'windows_ad::begin':} -> Class['windows_ad::conf_forest'] -> Class['windows_ad::install'] -> anchor{'windows_ad::end':} 
      }
    }
  }else{
    anchor{'windows_ad::begin':} -> Windows_ad::Organisationalunit <| |> -> Windows_ad::Group <| |> -> Windows_ad::User <| |> -> Windows_ad::Groupmembers <| |> -> anchor{'windows_ad::end':}
  }

  if type($groups_hiera_merge) == 'string' {
    $groups_hiera_merge_real = str2bool($groups_hiera_merge)
  } else {
    $groups_hiera_merge_real = $groups_hiera_merge
  }
  validate_bool($groups_hiera_merge_real)

  if $groups != undef {
    if $groups_hiera_merge_real == true {
      $groups_real = hiera_hash('windows_ad::groups')
    } else {
      $groups_real = $groups
    }
    validate_hash($groups_real)
    create_resources('windows_ad::group',$groups_real)
  }

  if type($users_hiera_merge) == 'string' {
    $users_hiera_merge_real = str2bool($users_hiera_merge)
  } else {
    $users_hiera_merge_real = $users_hiera_merge
  }
  validate_bool($users_hiera_merge_real)

  if $users != undef {
    if $users_hiera_merge_real == true {
      $users_real = hiera_hash('windows_ad::users')
    } else {
      $users_real = $users
    }
    validate_hash($users_real)
    create_resources('windows_ad::user',$users_real)
  }

  if type($usersingroup_hiera_merge) == 'string' {
    $usersingroup_hiera_merge_real = str2bool($usersingroup_hiera_merge)
  } else {
    $usersingroup_hiera_merge_real = $usersingroup_hiera_merge
  }
  validate_bool($usersingroup_hiera_merge_real)

  if $usersingroup != undef {
    if $usersingroup_hiera_merge_real == true {
      $usersingroup_real = hiera_hash('windows_ad::usersingroup')
    } else {
      $usersingroup_real = $usersingroup
    }
    validate_hash($usersingroup_real)
    create_resources('windows_ad::groupmembers',$usersingroup_real)
  }
}