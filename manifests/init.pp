#
# Help can be found in readme.rd for a global help
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
class windows_ad (
  ### part install AD
  $install                   = $windows_ad::params::install,
  $installmanagementtools    = $windows_ad::params::installmanagementtools,
  $installsubfeatures        = $windows_ad::params::installsubfeatures,
  $restart                   = $windows_ad::params::restart,
  $installflag               = $windows_ad::params::installflag,        # Flag to bypass the install of AD if desired

  ### Part Configure AD - Global
  $configure                 = $windows_ad::params::configure,
  $domain                    = $windows_ad::params::domain,
  $domainname                = $windows_ad::params::domainname,          # FQDN
  $netbiosdomainname         = $windows_ad::params::netbiosdomainname,   # FQDN
  $configureflag             = $windows_ad::params::configureflag,       # Flag to bypass the configuration of AD if desired
  #level AD
  $domainlevel               = $windows_ad::params::domainlevel,         # Domain level {4 - Server 2008 R2 | 5 - Server 2012 | 6 - Server 2012 R2}
  $forestlevel               = $windows_ad::params::forestlevel,      # Domain level {4 - Server 2008 R2 | 5 - Server 2012 | 6 - Server 2012 R2},

  $installdns                = $windows_ad::params::installdns,                 # Add DNS Server Role
  $globalcatalog             = $windows_ad::params::globalcatalog,                 # Add Global Catalog functionality
  $kernel_ver                = $windows_ad::params::kernel_ver,

  # Installation Directories
  $databasepath              = $windows_ad::params::databasepath,   # Active Directory database path
  $logpath                   = $windows_ad::params::logpath,   # Active Directory log path
  $sysvolpath                = $windows_ad::params::sysvolpath, # Active Directory sysvol path

  $dsrmpassword              = $windows_ad::params::dsrmpassword,

  ### Part Configure AD - Forest

  #uninstall forest
  $localadminpassword        = $windows_ad::params::localadminpassword,
  $force                     = $windows_ad::params::force,
  $forceremoval              = $windows_ad::params::forceremoval,
  $uninstalldnsrole          = $windows_ad::params::uninstalldnsrole,
  $demoteoperationmasterrole = $windows_ad::params::demoteoperationmasterrole,

  ### Part Configure AD - Other
  $secure_string_pwd         = $windows_ad::params::secure_string_pwd,
  $installtype               = $windows_ad::params::installtype,          # New domain or replica of existing domain {replica | domain}
  $domaintype                = $windows_ad::params::domaintype,          # Type of domain {Tree | Child | Forest} (New domain tree in an existing forest, child domain, or new forest)
  $sitename                  = $windows_ad::params::sitename,          # Site Name

  ### Define Hiera hashes
  $groups                    = $windows_ad::params::groups,
  $groups_hiera_merge        = $windows_ad::params::groups_hiera_merge,
  $users                     = $windows_ad::params::users,
  $users_hiera_merge         = $windows_ad::params::users_hiera_merge,
  $usersingroup              = $windows_ad::params::usersingroup,
  $usersingroup_hiera_merge  = $windows_ad::params::usersingroup_hiera_merge,

  $timeout                   = $windows_ad::params::timeout
) inherits windows_ad::params {
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
    timeout                   => $timeout
  }
  if($installflag or $configureflag){
    if($install == 'present'){
      anchor{'windows_ad::begin':} -> Class['windows_ad::install'] -> Class['windows_ad::conf_forest'] -> anchor{'windows_ad::end':} -> Windows_ad::Organisationalunit <| |> -> Windows_ad::Group <| |> -> Windows_ad::User <| |> -> Windows_ad::Group_members <| |>
    }else{
      if($configure == present){
        fail('You can\'t desactivate the Role ADDS without uninstall ADDSControllerDomain first')
      }else{
        anchor{'windows_ad::begin':} -> Class['windows_ad::conf_forest'] -> Class['windows_ad::install'] -> anchor{'windows_ad::end':}
      }
    }
  }else{
    anchor{'windows_ad::begin':} -> Windows_ad::Organisationalunit <| |> -> Windows_ad::Group <| |> -> Windows_ad::User <| |> -> Windows_ad::Group_members <| |> -> anchor{'windows_ad::end':}
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
    create_resources('windows_ad::group_members',$usersingroup_real)
  }
}
