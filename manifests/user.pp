# == Class: windows_ad
#
# Full description of windows_ad::users here.
#
# This resource allow you to add a user to a specific OU. The OU must be created. In case of the OU doesn't not exist no error will be appear
# and puppet will continue to read your manifest.
# When you do your manifest be careful to declare your OU before the user.
# A password will be automatically generated for the user, you just have to specify the length. (default set to 9 characters).
# The password will be saved locally on C:\password.txt
# When you remove a user the password.txt is not updated
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
# $ensure                -> add or delete user
# domainname,            -> the domain name like : jre.local
# $path,             -> where is located the account
# $accountname,          -> is samaccountname
# $lastname,             -> is lastname
# $firstname,            -> is firsname
# $passwordneverexpires, -> set if password never expire or expire(true/false)
# $passwordlength        -> set password length
# $enabled               -> enable account after creation (true/false)
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
#  windows_ad::user{'test':
#    ensure               => present,
#    domainname           => 'jre.local',
#    path                 => 'OU=PLOP,DC=JRE,DC=LOCAL',
#    accountname          => 'test',
#    lastname             => test,
#    firstname            => 'testtest',
#    description          => 'desc user'
#    passwordneverexpires => true,
#    passwordlength       => '15',
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
define windows_ad::user(
  $ensure               = $ensure,                # add or delete user
  $domainname           = $domainname,            # the domain name like : jre.local
  $path                 = $path,                  # where is located the account
  $accountname          = $accountname,           # is samaccountname
  $lastname             = $lastname,              # is lastname
  $firstname            = $firstname,             # is firsname
  $description          = '',                     # is description
  $passwordneverexpires = $passwordneverexpires,  # password never expire or expire(true/false)
  $passwordlength       = '9',                    # password length
  $enabled              = true,                 # enable account after creation (true/false)

# delete user
  $confirmdeletion      = false,                # delete wihtout confirmation
){
  validate_re($ensure, '^(present|absent)$', 'valid values for ensure are \'present\' or \'absent\'')
  validate_bool($passwordneverexpires)
  validate_bool($enabled)

  if($ensure == 'present'){
    $fullname = "${firstname} ${lastname}"
    if(!empty($firstname)){$fullnameparam = "-DisplayName '${firstname} ${lastname}'"}
    if(!empty($description)){$descriptionparam = "-Description '${description}'"}
    if(!empty($firstname)){$givenparam = "-GivenName '${firstname}'"}
    if(!empty($lastname)){$lastnameparam = "-SurName '${lastname}'"}

    $userprincipalname = "${accountname}@${domainname}"
    exec { "Modify User - ${accountname}":
      command     => "import-module activedirectory;Set-ADUser -identity ${accountname} ${fullnameparam} ${givenparam} ${lastnameparam} ${descriptionparam} -PasswordNeverExpires $${passwordneverexpires} -Enabled $${enabled};",
      onlyif      => "if((dsquery.exe user -samid ${accountname})){}else{exit 1}",
      provider    => powershell,
    }
    exec { "Add User - ${accountname}":
      command     => "Function New-RandomComplexPassword (){ \$Length = ${passwordlength}; \$Assembly = Add-Type -AssemblyName System.Web;\$RandomComplexPassword = [System.Web.Security.Membership]::GeneratePassword(\$Length,2);Write-Output \$RandomComplexPassword.ToString()};\$pwd=New-RandomComplexPassword;add-windowsfeature -name 'rsat-ad-powershell' -includeAllSubFeature;import-module activedirectory;New-ADUser -name '${fullname}' -DisplayName '${fullname}' -GivenName '${firstname}' -SurName '${lastname}' -Samaccountname '${accountname}' -UserPrincipalName '${userprincipalname}' -Description '${description}' -PasswordNeverExpires $${passwordneverexpires} -path '${path}' -AccountPassword (ConvertTo-SecureString \$pwd -AsPlainText -force) -Enabled $${enabled};\"${userprincipalname};\$pwd\" >> C:\\password.txt",
      onlyif      => "if((dsquery.exe user -samid ${accountname}) -or ([adsi]::Exists(\"LDAP://${path}\") -eq \$false)){exit 1}",
      provider    => powershell,
    }

  }elsif($ensure == 'absent'){
    exec { "Remove User - ${accountname}":
      command     => "import-module activedirectory;Remove-ADUser -identity ${accountname} -Confirm:$${confirmdeletion}",
      onlyif      => "if(dsquery.exe user -samid ${accountname} ){return \$true}else{exit 1}",
      provider    => powershell,
    }
  }
}