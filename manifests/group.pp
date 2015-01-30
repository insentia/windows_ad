# == Class: windows_ad
#
# Full description of windows_ad::group here.
#
# This resource allow you to add/remove a group inside of a active directory.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  windows_ad::group{'test':
#    ensure               => present,
#    displayname          => 'Test',
#    path                 => 'OU=PLOP,DC=JRE,DC=LOCAL',
#    groupname            => 'test',
#    groupscope           => 'Universal',
#    groupcategory        => 'Security',
#    description          => 'desc group',
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
define windows_ad::group(
  $ensure           = present,         # add or delete user
  $path             = $path,           # where is located the account
  $displayname      = $displayname,    # the displayname
  $groupname        = $groupname,      # is name powersherll parameter
  $groupscope       = 'Global',        # is groupscope (DomainLocal  OR  Global  OR  Universal )
  $groupcategory    = 'Security',      # is groupcategory ( Security  OR Distribution  )
  $description      = '',              # description of group
  $confirmdeletion  = false,           # delete without confirmation
){

  validate_re($ensure, '^(present|absent)$', 'valid values for ensure are \'present\' or \'absent\'')
  validate_re($groupscope, '^(DomainLocal|Global|Universal)$', 'valid values for groupscope are \'DomainLocal\' or \'Global\' or \'Universal\'')
  validate_re($groupcategory, '^(Security|Distribution)$', 'valid values for groupcategory are \'Security\' or \'Distribution\'')

  if($ensure == 'present'){
    exec { "Add Group - ${groupname}":
      command     => "import-module activedirectory;New-ADGroup -Description '${description}' -DisplayName '${displayname}' -Name '${groupname}' -GroupCategory '${groupcategory}' -GroupScope '${groupscope}' -Path '${path}'",
      onlyif      => "\$groupname = \"${groupname}\";\$path = \"${path}\";\$oustring = \"CN=\$groupname,\$path\"; if([adsi]::Exists(\"LDAP://\$oustring\")){exit 1}",
      provider    => powershell,
    }
  }else{
    exec { "Remove Group - ${groupname}":
      command     => "import-module activedirectory;Remove-ADGroup -identity '${groupname}' -confirm:$${confirmdeletion}",
      onlyif      => "\$groupname = \"${groupname}\";\$path = \"${path}\";\$oustring = \"CN=\$groupname,\$path\"; if([adsi]::Exists(\"LDAP://\$oustring\")){}else{exit 1}",
      provider    => powershell,
    }
  }
}
