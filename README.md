windows_ad

This is the windows_ad module.

##Introduction
This is the windows_ad module.
Inspired from opentable/windows_feature module and from martezr/windows_domain_controller 

This module permit you to install a Windows AD Domain controller on a Windows Server.


This module have been tested on Windows Server 2012 r2, should work on Windows Server since 2008 R2.

##Last Fix
V 0.0.4 :
 - Fix Problem when uninstalling the forest.
 - Fix Problem to check if Forest is already installed

##Module Description

For now, the module only allow the creation of new domain, in a new forest.


###Setup Requirements
 
Depends on the following modules:
'joshcooper/powershell', '>=0.0.6'
'puppetlabs/stdlib', '>= 4.2.1'

##Usage

Class: windows_ad

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

Parameters:
	$install              # Present or absent -> install/desinstall ADDS role
	$configure            # Present or absent -> configure/remove a Domain Controller
	$domainname           # name of domain you must install FQDN
	$domain               # Installation type { forest | tree | child | replica | readonly } ==> doesn't implement yet
	$netbiosdomainname    # NetBIOS name
	$domainlevel          # Domain level {2 - Server 2003 | 3 - Server 2008 | 4 - Server 2008 R2 | 5 - Server 2012 | 6 - Server 2012 R2}
	$forestlevel          # Forest Level {2 - Server 2003 | 3 - Server 2008 | 4 - Server 2008 R2 | 5 - Server 2012 | 6 - Server 2012 R2}
	$databasepath         # Active Directory database path
	$logpath              # Active Directory log path
	$sysvolpath           # Active Directory sysvol path
	$dsrmpassword         # Directory Service Recovery Mode password
	$localadminpassword   # password of local admin for remove DC.
  
Other parameters can be set Check the init.pp in manifests folder. 

License
-------
Apache License, Version 2.0

Contact
-------
Jerome RIVIERE

Support
-------

Please log tickets and issues at our [Projects site](https://github.com/ninja-2/windows_ad)
