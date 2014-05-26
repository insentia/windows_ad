# == Class: windows_ad
#
# Full description of windows_ad::groupmembers here.
#
# This resource allow you to add/remove users inside a group of a active directory.
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
#  windows_ad::groupmembers{'test':
#    ensure               => present,
#    groupname            => 'SQLAdmin',
#    members             => '"jre","test2"',
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
define windows_ad::groupmembers(
  $ensure         = $ensure,         # add or delete user
  $groupname      = $groupname,      # name of group
  $members        = $members,       # samaccountname of user

# delete user inside a group
  $confirmdeletion  = false,                # delete wihtout confirmation
){
  validate_re($ensure, '^(present|absent)$', 'valid values for ensure are \'present\' or \'absent\'')

  if($ensure == 'present'){
    exec { "Add Group Member - ${groupname}":
      command     => "import-module activedirectory;Add-ADGroupMember '${groupname}' -Member ${members}",
      onlyif      => "\$member=\$null;\$values=${members};\$split=\$values.split(',');if(dsquery.exe group -samid ${groupname}){\$allmembers = Get-ADGroupMember '${groupname}';foreach(\$value in \$split){foreach(\$allmember in \$allmembers){\$one = \$value.tolower();if(\$one -eq \$allmember.SamAccountName.tolower()){if(\$member-eq\$null){\$member='\"'+\$allmember.SamAccountName+'\"';}else{\$member+=',\"'+\$allmember.SamAccountName+'\"';}}}};if(( \$member -ne '${$members}') ){}else{exit 1}}else{exit 1}",
      provider    => powershell,
    }
  }else{
    exec { "Remove Group Member - ${groupname}":
      command     => "import-module activedirectory;Remove-ADGroupMember '${groupname}' -Member ${members} -Confirm:\$False",
      onlyif      => "\$member=\$null;\$values=${members};\$split=\$values.split(',');if((dsquery.exe group -samid ${groupname}) -and ((Get-ADGroupMember -Identity ${groupname}) -ne \$null)){\$allmembers = Get-ADGroupMember '${groupname}';foreach(\$value in \$split){foreach(\$allmember in \$allmembers){\$one = \$value.tolower();if(\$one -eq \$allmember.SamAccountName.tolower()){if(\$member-eq\$null){\$member='\"'+\$allmember.SamAccountName+'\"';}else{\$member+=',\"'+\$allmember.SamAccountName+'\"';}}}};if(( \$member -eq '${$members}') ){}else{exit 1}}else{exit 1}",
      provider    => powershell,
    }
  }
}