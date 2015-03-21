windows_ad

This is the windows_ad puppet module.

##Introduction
This is the windows_ad puppet module.
Inspired from [opentable/windows_feature](https://forge.puppetlabs.com/opentable/windows_feature) module and from [martezr/windows_domain_controller](https://forge.puppetlabs.com/martezr/windows_domain_controller) for the installation and configuration of a windows domain

This module have two main roles :
- Install & configure AD
- Manage Users/OU/Groups in your Active Directory


This module permit you to install a Windows AD Domain controller on a Windows Server.


Moreover, it allows you to create/Remove User in Active Directory, but also permit you to create/Remove Organisational Unit in Active Directory


This module have been tested on Windows Server 2012 r2, should work on Windows Server since 2008 R2.
Puppet open source v3.5.1 and v3.6.2, the puppetmaster version is v3.4.3 (on ubuntu 14.04 LTS). Should work since version 3.5.1 of puppet

##Last Fix/Update
V 0.3.1 :
 - Fix add user. (dsquery.exe doesn't seem to work anymore) - Works with fullname value
 - Add Pull Request #8 (fix readme for Group)
V 0.3.2 :
 - Fix add group and groupmember dsquery.exe doesn't seem to work anymore).

##Module Description

For now, the module allow the installation and creation of new domain, in a new forest.
You can also do :
+ Manage object in your AD :
 - User, 
 - Users,
 - OU,
 - Group,
 - Group Members


###Setup Requirements

Your puppet.conf need to have this following line:
```
	ordering=manifest
``` 

For using windows_ad::users resource you need to put parser=future in your puppet.conf
Adding multiple users it's possible with or WITHOUT parser=future parameter. Please read the next sections


Depends on the following modules:
 - ['joshcooper/powershell', '>=0.0.6'](https://forge.puppetlabs.com/joshcooper/powershell),
 - ['puppetlabs/stdlib', '>= 4.2.1'](https://forge.puppetlabs.com/puppetlabs/stdlib)

##Usage

Class: windows_ad  
```
Example - Create a new forest
	class {'windows_ad':
	  install                => present,
	  installmanagementtools => true,
	  restart                => true,
	  installflag            => true,
	  configure              => present,
	  configureflag          => true,
	  domain                 => 'forest',
	  domainname             => 'jre.local',
	  netbiosdomainname      => 'jre',
	  domainlevel            => '6',
	  forestlevel            => '6',
	  databasepath           => 'c:\\windows\\ntds',
	  logpath                => 'c:\\windows\\ntds',
	  sysvolpath             => 'c:\\windows\\sysvol',
	  installtype            => 'domain',
	  dsrmpassword           => 'password',
	  installdns             => 'yes',
	  localadminpassword     => 'password',
	}
```
Parameters:
```
	$install              # Present or absent -> install/desinstall ADDS role
	$installflag          # Flag to bypass the install of AD if desired. Need to be set to False to bypass. Default true
	$configure            # Present or absent -> configure/remove a Domain Controller
	$configureflag        # Flag to bypass the configuration of AD if desired. Need to be set to False to bypass. Default true
	$domainname           # name of domain you must install FQDN
	$domain               # Installation type { forest | tree | child | replica | readonly } ==> doesn't implement yet
	$netbiosdomainname    # NetBIOS name
	$domainlevel          # Domain level {4 - Server 2008 R2 | 5 - Server 2012 | 6 - Server 2012 R2}
	$forestlevel          # Forest Level {4 - Server 2008 R2 | 5 - Server 2012 | 6 - Server 2012 R2}
	$databasepath         # Active Directory database path
	$logpath              # Active Directory log path
	$sysvolpath           # Active Directory sysvol path
	$dsrmpassword         # Directory Service Recovery Mode password
	$localadminpassword   # password of local admin for remove DC.
``` 
Other install and configuration parameters can be set check the init.pp in manifests folder. 

For adding Organisational Unit : 
```
	windows_ad::organisationalunit{'PLOP':
	  ensure       => present,
	  path         => 'DC=JRE,DC=LOCAL',
	  ouName       => 'PLOP',
	}
```


For adding a simple User :
```
	windows_ad::user{'Add_user':
	  ensure               => present,
	  domainname           => 'jre.local',
	  path                 => 'OU=PLOP,DC=JRE,DC=LOCAL',
	  accountname          => 'test',
	  lastname             => 'test',                   ## Not mandatory. But for this 2 parameters you need to declare at least one 
	  firstname            => 'test',                   ## or use fullname parameter !
	  passwordneverexpires => true,
	  passwordlength       => 15,                       # must be number so don't put ''
	  password             => 'M1Gr3atP@ssw0rd',        # You can specify a password for the account you declare
	  xmlpath              => 'C:\\users.xml',          # must contain the full path, and the name of the file. Default value C:\\users.xml
	  writetoxmlflag       => true,                     # need to be set to false if you doesn't want to write the xml file. Default set to true
	  emailaddress         => 'test@jre.local',
	}
```

For adding multiple Users WITH parser=future:
```
	$users = [
	 {
		ensure               => present,
		path                 => 'OU=PLOP,DC=JRE,DC=LOCAL',
		accountname          => 'test',
		lastname             => 'test',
		firstname            => 'testtest',
		passwordneverexpires => true,
		passwordlength       => 15,
		fullname             => 'The test',
	 },
	 {
		ensure               => present,
		path                 => 'OU=PLOP,DC=JRE,DC=LOCAL',
		accountname          => 'test2',
		lastname             => 'test2',
		firstname            => 'test22',
		passwordneverexpires => true,
		passwordlength       => 9,
		password             => 'M1Gr3atP@ssw0rd',
		emailaddress         => 'test2@jre.local',
	  }
	]

	windows_ad::users{'Add_Users':
	  domainname           => 'jre.local',
	  users                => $users,
	  xmlpath              => 'C:\\users.xml', # must contain the full path, and the name of the file. Default value C:\\users.xml
	  writetoxmlflag       => true,            # need to be set to false if you doesn't want to write the xml file. Default set to true
	}
```

For adding multiple Users WITHOUT parser=future:
```
	$userhash = {
	 'test' => {
		ensure               => present,
		path                 => 'OU=PLOP,DC=JRE,DC=LOCAL',
		accountname          => 'test',
		lastname             => 'test',
		firstname            => 'testtest',
		passwordneverexpires => true,
		passwordlength       => 15,
		fullname             => 'The test',
	 },
	 'test2' => {
		ensure               => present,
		path                 => 'OU=PLOP,DC=JRE,DC=LOCAL',
		accountname          => 'test2',
		lastname             => 'test2',
		firstname            => 'test22',
		passwordneverexpires => true,
		passwordlength       => 9,
		password             => 'M1Gr3atP@ssw0rd',
		emailaddress         => 'test2@jre.local',
	  },
	}
	
	create_resources(windows_ad::user, $userhash)

```

About password: the password will be auto-generated or now you can specify your own password (min 8 characters, one alpha, one numeric, one special characters at least)
Passwords will be saved to users.xml on your c: drive (C:\users.xml)

For adding a Group :
```
	windows_ad::group{'test':
	  ensure               => present,
	  displayname          => 'Test',
	  path                 => 'CN=Users,DC=JRE,DC=LOCAL',
	  groupname            => 'test',
	  groupscope           => 'Global',
	  groupcategory        => 'Security',
	  description          => 'desc group',
	}
```

For adding members to a Group :
```
	windows_ad::groupmembers{'Member groupplop':
	  ensure    => present,
	  groupname => 'groupplop',
	  members   => '"jre","test2"',
	}
```

For the group members respect the syntax : '"samaccountname","samaccountname"' and if only one member :'"jre"'
The module doesn't delete users if you let ensure to present, and modify only the members list
Otherwise, if you let in the list of the members you want to delete and put ensure to absent, then the module will delete only the members in the list 


### Known issues

- If you update the FullName the XML file will not be updated.

License
-------
Apache License, Version 2.0

Contributors
-------
[Jerome RIVIERE](https://github.com/ninja-2)

 + V 0.0.9 :
   - [shawnhall](https://github.com/shawnhall)  -> Pull Request #1
   - [grafjo](https://github.com/insentia/windows_ad/pulls/grafjo) -> Pull Request #9

Support
-------

Please log tickets and issues on [GitHub site](https://github.com/insentia/windows_ad/issues)

