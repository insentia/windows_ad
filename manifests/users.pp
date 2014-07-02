# == Class: windows_ad
#
# Full description of windows_ad::users here.
#
# This resource allow you to a add multiple users based on user definition.
# the domain name is use globally but you easily declare a specific domain name on each user in the users array
# and make change to this method to use the array instead of the global variable
#
# For using this definition you need to use future parser
#
# === Parameters
#
# domainname     -> the domain name like : jre.local
# users          -> users array (see example to know how declare them)
#
# === Examples
#
# $users = [
# {
#    ensure               => present,
#    path                 => 'OU=PLOP2,DC=JRE,DC=LOCAL',
#    accountname          => 'test',
#    lastname             => test,
#    firstname            => 'testtest',
#    passwordneverexpires => true,
#    passwordlength       => '15',
#    emailaddress         => 'test@jre.local',
# },
# {
#    ensure               => present,
#    path                 => 'OU=PLOP,DC=JRE,DC=LOCAL',
#    accountname          => 'test2',
#    lastname             => test2,
#    firstname            => 'test22',
#    passwordneverexpires => true,
#    passwordlength       => '9',
#    fullname             => 'test2 the best',
#  }
#]
#
#  windows_ad::users{'test':
#  domainname           => 'jre.local',
#  users                => $users,
#}
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
define windows_ad::users(
  $domainname     = $domainname,     # the domain name like : jre.local
  $users          = $users,          # users array
  $xmlpath        = 'C:\\users.xml', # path where to save the user xml
  $writetoxmlflag = true,            # write a xml ?. Default set to true
){
  warning('Instead of using this class, you can declare a hash of user (see readme file), and use function create_resources(windows_ad::user, $userhash)')
  $_users = $users
  each($_users) |$user|{
    windows_ad::user{"${user['accountname']}":
      ensure               => $user['ensure'],
      domainname           => $domainname,
      path                 => $user['path'],
      accountname          => $user['accountname'],
      lastname             => $user['lastname'],
      firstname            => $user['firstname'],
      description          => $user['description'],
      passwordneverexpires => $user['passwordneverexpires'],
      passwordlength       => $user['passwordlength'],
      enabled              => $user['enabled'],
      password             => $user['password'],
      confirmdeletion      => $user['confirmdeletion'],
      xmlpath              => $xmlpath,
      writetoxmlflag       => $writetoxmlflag,
      fullname             => $user['fullname'],
      emailaddress         => $user['emailaddress'],
    }
  }
}
