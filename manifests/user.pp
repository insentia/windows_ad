# == Class: windows_ad
#
# Full description of windows_ad::users here.
#
# This resource allow you to add a user to a specific OU. The OU must be created. In case of the OU doesn't not exist no error will be appear
# and puppet will continue to read your manifest.
# You can specify a password if you want.
# A password will be automatically generated for the user if you don't specify one, you just have to specify the length. (default set to 9 characters).
# The password will be saved locally on C:\users.xml
# When you remove a user the users.xml is updated
#
# === Parameters
#
# $ensure                -> add or delete user
# domainname,            -> the domain name like : jre.local
# $path,                 -> where is located the account
# $accountname,          -> is samaccountname
# $lastname,             -> is lastname
# $firstname,            -> is firstname
# $fullname,             -> is fullname displayname
# $emailaddress          -> is email
# $passwordneverexpires, -> set if password never expire or expire(true/false)
# $passwordlength        -> set password length
# $enabled               -> enable account after creation (true/false)
# $password              -> fill a specific password. If you don't specify a password will be generated
# $xmlpath               -> must contain the full path, and the name of the file. Default value C:\\users.xml
#
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
#    password             => 'M1Gr3atP@ssw0rd',
#    emailaddress         => 'test@jre.local',
#    fullname             => 'the test',
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
  $ensure               = present,                            # add or delete user
  $domainname           = $domainname,                        # the domain name like : jre.local
  $path                 = $path,                              # where is located the account
  $accountname          = $accountname,                       # is samaccountname
  $lastname             = '',                                 # is lastname
  $firstname            = '',                                 # is firstname
  $fullname             = '',                                 # is fullname
  $emailaddress         = '',                                 # email address
  $description          = '',                                 # is description
  $passwordneverexpires = true,                               # password never expire or expire(true/false)
  $passwordlength       = 9,                                  # password length
  $enabled              = true,                               # enable account after creation (true/false)
  $password             = '',                                 # password to set to the account. Default autogenerating
  $writetoxmlflag       = true,                               # Flag that makes writing to the users.xml optional
  $xmlpath              = 'C:\\users.xml',                    # file where to save user info. Default set to C:\\users.xml

# delete user
  $confirmdeletion      = false,                              # delete wihtout confirmation
){
  validate_re($ensure, '^(present|absent)$', 'valid values for ensure are \'present\' or \'absent\'')
  validate_bool($passwordneverexpires)
  validate_bool($enabled)
  validate_bool($writetoxmlflag)

  if($passwordlength <= 7){
    fail("The password length must be, at least, set to 8 characters for ${accountname}")
  }

  if(empty($fullname) and empty($lastname) and empty($firstname)){
    fail('fullname or lastname or firstname must be provided')
  }
  $modify = false     # will be implement later for modify password. not used for now
  if ($writetoxmlflag == true){
    if (!defined(File[$xmlpath])){
      file{"$xmlpath":
        content => template('windows_ad/xml.erb'),
        replace => no,
      }
    }
  }
  if($ensure == 'present'){
    if(empty($fullname)){
      if(empty($lastname) and !empty($firstname)){
        $fullnamevalue = $firstname
      }
      if(!empty($lastname) and empty($firstname)){
        $fullnamevalue = $lastname
      }
      if(!empty($lastname) and !empty($firstname)){
        $fullnamevalue = "${firstname} ${lastname}"
      }
    }else{
      $fullnamevalue = $fullname
    }

    if(!empty($emailaddress)){$emailaddressparam = "-EmailAddress '$emailaddress'"}
    if(!empty($fullnamevalue)){$fullnameparam = "-DisplayName '$fullnamevalue'"}
    if(!empty($description)){$descriptionparam = "-Description '${description}'"}
    if(!empty($firstname)){$givenparam = "-GivenName '${firstname}'"}
    if(!empty($lastname)){$lastnameparam = "-SurName '${lastname}'"}

    if(empty($password)){
    $pwd = get_random_password($passwordlength)
    }else{
      $regex = validate_password($password)
      if($regex){
        $pwd = $password
      }else{
        warning('Password is not compliant with complexity policy')
        warning('One integer, one upper, one lower character, one special character, minimun 8 characters long')
        warning('So we will generate one for you ...')
        $pwd = get_random_password($passwordlength)
      }
    }

    $userprincipalname = "${accountname}@${domainname}"
    exec { "Delete User Desc - ${accountname}":
      command     => "import-module activedirectory;\$user = Get-ADUser -Identity '${accountname}' -Properties Description;Set-ADUser -identity ${accountname} -Remove @{description=\$user.description}",
      onlyif      => "\$user = Get-ADUser -Identity '${accountname}' -Properties *;if((dsquery.exe user -samid ${accountname}) -and ('${description}' -ne \$user.Description -and \$user.Description -ne \$null)){}else{exit 1}",
      provider    => powershell,
    }
    exec { "Modify User - ${accountname}":
      command     => "import-module activedirectory;Set-ADUser -identity ${accountname} ${fullnameparam} ${givenparam} ${lastnameparam} ${descriptionparam} ${emailaddressparam} -PasswordNeverExpires $${passwordneverexpires} -Enabled $${enabled};",
      onlyif      => "\$user = Get-ADUser -Identity '${accountname}' -Properties *;if((dsquery.exe user -samid ${accountname}) -and (('${description}' -ne \$user.Description -and '${description}' -ne '') -or (('${firstname}' -ne \$user.GivenName) -and ('${firstname}' -ne '')) -or (('${lastname}' -ne \$user.Surname) -and ('${lastname}' -ne '')) -or (('${emailaddress}' -ne \$user.EmailAddress) -and ('${emailaddress}' -ne '')) -or ('${fullnamevalue}' -ne \$user.DisplayName))){}else{exit 1}",
      provider    => powershell,
    }
    exec { "Add User - ${accountname}":
      command     => "import-module servermanager;add-windowsfeature -name 'rsat-ad-powershell' -includeAllSubFeature;import-module activedirectory;New-ADUser -name '${fullnamevalue}' -DisplayName '${fullnamevalue}' ${givenparam} ${lastnameparam} ${emailaddressparam} -Samaccountname '${accountname}' -UserPrincipalName '${userprincipalname}' -Description '${description}' -PasswordNeverExpires $${passwordneverexpires} -path '${path}' -AccountPassword (ConvertTo-SecureString '${pwd}' -AsPlainText -force) -Enabled $${enabled};",
      onlyif      => "\$oustring = \"CN=${fullnamevalue},${path}\"; if([adsi]::Exists(\"LDAP://\$oustring\")){exit 1}",
      provider    => powershell,
    }
    if ($writetoxmlflag == true){
      exec { "Add to XML - ${accountname}":
        command  => "[xml]\$xml = New-Object system.Xml.XmlDocument;[xml]\$xml = Get-Content '${xmlpath}';\$subel = \$xml.CreateElement('user');(\$xml.configuration.GetElementsByTagName('users')).AppendChild(\$subel);\$name = \$xml.CreateAttribute('name');\$name.Value = '${accountname}';\$password = \$xml.CreateAttribute('password');\$password.Value = '${pwd}';\$fullname = \$xml.CreateAttribute('fullname');\$fullname.value = '${fullnamevalue}';\$subel.Attributes.Append(\$name);\$subel.Attributes.Append(\$password);\$subel.Attributes.Append(\$fullname);\$xml.save('${xmlpath}');",
        provider => powershell,
        onlyif   => "[xml]\$xml = New-Object system.Xml.XmlDocument;[xml]\$xml = Get-Content '${xmlpath}';\$exist=\$false;foreach(\$user in \$xml.configuration.users.user){if(\$user.name -eq '${accountname}'){\$exist=\$true}}if(\$exist -eq \$True){exit 1}",
        require  => [Exec["Add User - ${accountname}"],File[$xmlpath]],
      }
    }
  }elsif($ensure == 'absent'){
    exec { "Remove User - ${accountname}":
      command     => "import-module activedirectory;Remove-ADUser -identity ${accountname} -Confirm:$${confirmdeletion}",
      onlyif      => "if(dsquery.exe user -samid ${accountname} ){return \$true}else{exit 1}",
      provider    => powershell,
    }
    if ($writetoxmlflag == true){
      exec { "Remove to XML - ${accountname}":
        command  => "[xml]\$xml = New-Object system.Xml.XmlDocument;[xml]\$xml = Get-Content '${xmlpath}';foreach(\$user in \$xml.configuration.users.user){if(\$user.name -eq '${accountname}'){\$user.ParentNode.RemoveChild(\$user);\$xml.save('${xmlpath}');}}",
        provider => powershell,
        onlyif   => "[xml]\$xml = New-Object system.Xml.XmlDocument;[xml]\$xml = Get-Content '${xmlpath}';\$exist=\$false;foreach(\$user in \$xml.configuration.users.user){if(\$user.name -eq '${accountname}'){\$exist=\$true}}if(\$exist -eq \$False){exit 1}",
        require  => [Exec["Remove User - ${accountname}"],File[$xmlpath]],
      }
    }
  }
}
