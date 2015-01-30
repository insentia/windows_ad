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
#    members              => '"jre","test2"',
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
  $ensure         = present,         # add or delete user
  $groupname      = $groupname,      # name of group
  $members        = $members,        # samaccountname of user

# delete user inside a group
  $confirmdeletion  = false,                # delete wihtout confirmation
){
  validate_re($ensure, '^(present|absent)$', 'valid values for ensure are \'present\' or \'absent\'')

  if($ensure == 'present'){
    exec { "Add Group Member - ${name}":
      command     => "import-module activedirectory;\$values='${members}';\$split=\$values.split(',');foreach(\$value in \$split){try{\$value = \$value.Replace('\"','');\$user = Get-ADUser \$value;}catch{\$user = \$null};if(\$user -ne \$null){Add-ADGroupMember '${groupname}' -Member \$value}}",
      onlyif      => "import-module activedirectory;\$member=\$null;\$values='${members}';\$split=\$values.split(',');try{\$group = get-adgroup '${groupname}';}catch{\$group = \$null;};foreach(\$value in \$split){try{\$value = \$value.Replace('\"','');\$user = Get-ADUser \$value}catch{\$user = \$null};if(\$group -ne \$null){if(\$user -ne \$null){foreach(\$allmember in Get-ADGroupMember '${groupname}'){\$one = \$value.tolower() -replace '\"','';if(\$one -eq \$allmember.SamAccountName.tolower()){if(\$member -eq \$null){\$member='\"'+\$allmember.SamAccountName+'\"';}else{\$member+=',\"'+\$allmember.SamAccountName+'\"';}}}if('${members}' -eq \$member){exit 1}}else{if('${members}' -match \$member){exit 1}}}else{exit 1}}",
      provider    => powershell,
    }
  }else{
    exec { "Remove Group Member - ${name}":
      command     => "import-module activedirectory;\$values='${members}';\$split=\$values.split(',');foreach(\$value in \$split){try{\$value = \$value.Replace('\"','');\$user = Get-ADUser \$value}catch{\$user = \$null};if(\$user -ne \$null){Remove-ADGroupMember '${groupname}' -Member \$value -Confirm:\$False}}",
      onlyif      => "import-module activedirectory;\$member=\$null;\$values=${members};\$split=\$values.split(',');try{\$group = get-adgroup '${groupname}';}catch{\$group = \$null;};foreach(\$value in \$split){if((\$group -ne \$null) -and ((Get-ADGroupMember -Identity ${groupname}) -ne \$null)){foreach(\$allmember in Get-ADGroupMember '${groupname}'){\$one = \$value.tolower();if(\$one -eq \$allmember.SamAccountName.tolower()){if(\$member-eq\$null){\$member='\"'+\$allmember.SamAccountName+'\"';}else{\$member+=',\"'+\$allmember.SamAccountName+'\"';}}};if('${members}' -cmatch \$member){}else{exit 1}}else{exit 1}}",
      provider    => powershell,
    }
  }
}