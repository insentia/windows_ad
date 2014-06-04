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

##Last Fix/Update
V 0.0.7 :
 - Added functionality so that the code can pull data from hiera
 - Added chaining to enforce execution ordering
 - Fixed some Powershell scripts that were causing errors
 - Added some conditional flags to make installing AD and configuring the forest optional
 - Added conditional flag to make writing to the xml file optional
 - Create/Remove a Group in Active Directory
 - Create/Remove members inside a existing Group in Active Directory
 - Add possibility to enter a password for user
 - Put password in xml file instead of txt. Better for ulterior use
 - Fix showing notice when no modification is made on a user

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
	  password             => 'M1Gr3atP@ssw0rd', #You can specify a password for the account you declare
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
		password             => 'M1Gr3atP@ssw0rd',
	  }
	]

	windows_ad::users{'Add_Users':
	  domainname           => 'jre.local',
	  users                => $users,
	}
```

About password: the password will be auto-generated or now you can specify your own password (min 8 characters, one alpha, one numeric, one special characters at least)
Passwords will be saved to users.xml on your c: drive (C:\users.xml)

For adding a Group :
```
	windows_ad::group{'test':
	  ensure               => present,
	  domainname           => 'jre.local',
	  path                 => 'CN=Users,DC=JRE,DC=LOCAL',
	  groupname            => 'groupplop',
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
Otherwise, if you let in the list the members you want to delete and put ensure to absent the module will delete only the members in the list 

### Known issues
Sometimes the generated password doesn't meet the windows requirement, however the user is created but not enabled
 -> [MSDN Note of Remarks Part](http://msdn.microsoft.com/en-us/library/vstudio/system.web.security.membership.generatepassword.aspx)
 -> WorkAround just delete the user or specify his password and execute again the manifest

License
-------
Apache License, Version 2.0

Contact
-------
Jerome RIVIERE

Support
-------

Please log tickets and issues at our [Projects site](https://github.com/ninja-2/windows_ad)
