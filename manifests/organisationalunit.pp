# == Class: windows_ad
#
# Full description of windows_ad::organisationalunit here.
#
# Allow you to create organisational unit for ActiveDirectory.
#
# When you delete the OU, the OU will be set unprotected, and will delete all existing user inside
#
# === Parameters
#
# Document parameters here.
#
#
#  $ensure,              ->  # add or delete OU
#  $path,                ->  # where is located the OU - EX:DC=JRE,DC=LOCAL
#  $accountname,         ->  # is organisational name
#  $protectfordeletion   ->  # if you want to prevent accidentally deletion of your OU
#
#  #delete OU
#  $confirmdeletion      ->  # use -confirm switch of windows powershell. need to be false when automating the configuration
#
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
#  windows_ad::organisationalunit{'PLOP':
#    ensure       => absent,
#    path         => 'DC=JRE,DC=LOCAL',
#    ouName       => 'PLOP',
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
define windows_ad::organisationalunit(
  $ensure               = present,                # add or delete OU
  $path                 = $path,                  # where is located the OU - EX:DC=JRE,DC=LOCAL
  $ouName               = $accountname,           # is organisational name
  $protectfordeletion   = true,                 # protect OU against deletion only for adding, when deleting OU the protection will be automatically set to false

  #delete OU
  $confirmdeletion      = false,                # delete wihtout confirmation. If false,all existing users inside the OU will be deleted
){
  validate_re($ensure, '^(present|absent)$', 'valid values for ensure are \'present\' or \'absent\'')

  if($ensure == 'present'){
    exec { "Adding OU - ${ouName}":
      command     => "import-module activedirectory;New-ADOrganizationalUnit -Name '${ouName}' -Path '${path}' -ProtectedFromAccidentalDeletion $${protectfordeletion}",
      onlyif      => "if([adsi]::Exists(\"LDAP://OU=${ouName},${path}\")){exit 1}",
      provider    => powershell,
    }
  }elsif($ensure == 'absent'){
    exec { "Unprotecting OU - ${ouName}":
      command     => "Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion \$false -Identity \"OU=${ouName},${path}\";",
      onlyif      => "if([adsi]::Exists(\"LDAP://OU=${ouName},${path}\")){}else{exit 1}",
      provider    => powershell,
    }
    exec { "Deleting OU - ${ouName}":
      command     => "Remove-ADOrganizationalUnit -Identity \"OU=${ouName},${path}\" -Confirm:$${confirmdeletion} -Recursive;",
      onlyif      => "if([adsi]::Exists(\"LDAP://OU=${ouName},${path}\")){}else{exit 1}",
      provider    => powershell,
    }
    Exec["Unprotecting OU - ${ouName}"] -> Exec["Deleting OU - ${ouName}"]
  }
}
