windows_ad

This is the windows_ad module.

##Introduction
This is the windows_ad module.
Inspired from [opentable/windows_feature](https://forge.puppetlabs.com/opentable/windows_feature) module and from [martezr/windows_domain_controller](https://forge.puppetlabs.com/martezr/windows_domain_controller) for the installation and configuration of a windows domain

This module have two main roles : 
- Install & configure AD
- Manage Users/OU in your Active Directory


This module permit you to install a Windows AD Domain controller on a Windows Server.


Moreover, it allows you to create/Remove User in Active Directory, but also permit you to create/Remove Organisational Unit in Active Directory


This module have been tested on Windows Server 2012 r2, should work on Windows Server since 2008 R2.

##Last Fix/Update
V 0.0.5 :
 - Create/Remove/Update a User or a multiple Users in Active Directory
 - Create/Remove OU in Active Directory

##Module Description

For now, the module allow the installation and creation of new domain, in a new forest.
You can also do :
+ Manage object in your AD :
 - User, 
 - Users,
 - OU


###Setup Requirements

Your puppet.conf need to have this following line:
```
	ordering=manifest
	parser = future    --> allow use of a foreach loop in puppet module 
``` 

If you don't want to activate the future parser, you can't declare and use the users definition (windows_ad::users), 
so you can't add users by array and need to declare them one by one (windows_ad::user)


Depends on the following modules:
['joshcooper/powershell', '>=0.0.6'](https://forge.puppetlabs.com/joshcooper/powershell),
['puppetlabs/stdlib', '>= 4.2.1'](https://forge.puppetlabs.com/puppetlabs/stdlib)

##Usage

Class: windows_ad
```
Example - Create a new forest
	class {'windows_ad':
	  install                => present,
	  installmanagementtools => true,
	  restart                => true,
	  configure              => present,
	  domain                 => 'forest',
	  domainname             => 'jre.local',
	  netbiosdomainname      => 'jre',
	  domainlevel            => '6',
	  forestlevel            => '6',
	  databasepath           => 'c:\\windows\\ntds',
	  logpath                => 'c:\\windows\\ntds',
	  sysvolpath             => 'c:\\windows\\sysvol',
	  installtype            => 'domain',
	  secure_string_pwd      => 'password',
	  dsrmpassword           => 'password',
	  installdns             => 'yes',
	  localadminpassword     => 'password',
	}
```
Parameters:
```
	$install              # Present or absent -> install/desinstall ADDS role
	$configure            # Present or absent -> configure/remove a Domain Controller
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
	  lastname             => 'test',
	  firstname            => 'test',
	  passwordneverexpires => true,
	  passwordlength       => '15',
	}
```

For adding multiple Users :
```
	$users = [
	 {
		ensure               => present,
		path                 => 'OU=PLOP,DC=JRE,DC=LOCAL',
		accountname          => 'test',
		lastname             => 'test',
		firstname            => 'testtest',
		passwordneverexpires => true,
		passwordlength       => '15',
	 },
	 {
		ensure               => present,
		path                 => 'OU=PLOP,DC=JRE,DC=LOCAL',
		accountname          => 'test2',
		lastname             => 'test2',
		firstname            => 'test22',
		passwordneverexpires => true,
		passwordlength       => '9',
	  }
	]

	windows_ad::users{'Add_Users':
	  domainname           => 'jre.local',
	  users                => $users,
	}
```



License
-------
Apache License, Version 2.0

Contact
-------
Jerome RIVIERE

Support
-------

Please log tickets and issues at our [Projects site](https://github.com/ninja-2/windows_ad)
