# Class: windows_ad
#
# Full description of windows_ad::install here.
#
# This class allow you to install/uninstall a windows domain services roles ADDS
#
# When you use this class please use it with windows_ad directly. see the readme file.
#
# === Parameters
#
#
# === Examples
#
#  class {'windows_ad::install':
#  install                => present,
#  installmanagementtools => true,
#  installsubfeatures     => true,
#  restart                => true,
#
# === Authors
#
# Jerome RIVIERE (www.jerome-riviere.re)
#
# === Copyright
#
# Copyright 2014 Jerome RIVIERE.
#
class windows_ad::install (
    $ensure = $ensure,
    $installmanagementtools = $installmanagementtools,
    $installsubfeatures = $installsubfeatures,
    $restart = $restart,
    $installflag = $installflag,
) {

  validate_re($ensure, '^(present|absent)$', 'valid values for ensure are \'present\' or \'absent\'')
  validate_bool($installmanagementtools)
  validate_bool($installsubfeatures)
  validate_bool($restart)
  validate_bool($installflag)

  if ($installflag == true){
    if $::operatingsystem != 'windows' { fail ("${module_name} not supported on ${::operatingsystem}") }
    if $restart { $restartbool = 'true' } else { $restartbool = 'false' }
    if $installsubfeatures { $subfeatures = '-IncludeAllSubFeature' }

    if $::kernelversion =~ /^(6.1)/ and $installmanagementtools {
      fail ('Windows 2012 or newer is required to use the installmanagementtools parameter')
    } elsif $installmanagementtools {
      $managementtools = '-IncludeManagementTools'
    }

    # Windows 2008 R2 and newer required http://technet.microsoft.com/en-us/library/ee662309.aspx
    if $::kernelversion !~ /^(6\.1|6\.2|6\.3)/ { fail ("${module_name} requires Windows 2008 R2 or newer") }

    # from Windows 2012 'Add-WindowsFeature' has been replaced with 'Install-WindowsFeature' http://technet.microsoft.com/en-us/library/ee662309.aspx
    if ($ensure == 'present') {
      if $::kernelversion =~ /^(6.1)/ { $command = 'Add-WindowsFeature' } else { $command = 'Install-WindowsFeature' }

      exec { "add-feature-${title}":
        command   => "Import-Module ServerManager; ${command} AD-Domain-Services ${managementtools} ${subfeatures} -Restart:$${restartbool}",
        onlyif    => "Import-Module ServerManager; if (@(Get-WindowsFeature AD-Domain-Services | ?{\$_.Installed -match \'false\'}).count -eq 0) { exit 1 }",
        provider  => powershell,
      }
    } elsif ($ensure == 'absent') {
      exec { "remove-feature-${title}":
        command   => "Import-Module ServerManager; Remove-WindowsFeature AD-Domain-Services -Restart:$${restartbool}",
        onlyif    => "Import-Module ServerManager; if (@(Get-WindowsFeature AD-Domain-Services | ?{\$_.Installed -match \'true\'}).count -eq 0) { exit 1 }",
        provider  => powershell,
      }
    }
  }
}
