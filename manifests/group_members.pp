# == Class: windows_ad::group_members
#
# Manages AD group memberships.
#
# === Authors
#
# John Puskar (johnpuskar@gmail.com)
# Jerome RIVIERE (www.jerome-riviere.re)
#
# === Copyright
#
# Copyright 2014 Jerome RIVIERE.
#
define windows_ad::group_members(
  Array[String] $members,
  String        $group_name = $title,
  String        $ensure = 'present',
){
  validate_re($ensure, '^(present|absent)$', 'valid values for ensure are \'present\' or \'absent\'')

  $puppet_members_joined = join($members, ',')
  $cmd_input_vars = @("END_cmd_input_vars"/$)
    \$puppet_group_name = "${group_name}"
    \$puppet_members = "${puppet_members_joined}"
    | END_cmd_input_vars

  $cmd_ensure_boilerplate_frag_1 = @(END_cmd_ensure_boilerplate)
    $ErrorActionPreference = "Stop"
    Import-Module activedirectory

    $member_names = $puppet_members.split(',')
    $member_names = $member_names | ForEach-Object {$_.replace("""",'').replace("'","").tolower()}
    $target_group_name = $puppet_group_name

    Try{
      $target_group = Get-AdGroup $target_group_name
      $target_group_members = Get-AdGroupMember $target_group_name
      $target_group_members_usernames = $target_group_members | Select-Object "sAMAccountName" -ExpandProperty "sAMAccountName"
      $target_group_members_usernames = $target_group_members_usernames | ForEach-Object {$_.ToLower()}
    } Catch {
      Write-Warning $error[0]
      Throw $error[0]
    }
    | END_cmd_ensure_boilerplate
  $cmd_ensure_boilerplate = "\
${cmd_input_vars} \
${cmd_ensure_boilerplate_frag_1} \
"

  $cmd_ensure_present_onlyif_frag_1 = @(END_cmd_ensure_present_onlyif)
    $found_missing_members = $false
    $member_names | Foreach-Object {
      If(!($target_group_members_usernames -contains $_)) {
        $found_missing_members = $true
      }
    }

    If($found_missing_members) {
      Exit 1
    } Else {
      Exit 0
    }
    | END_cmd_ensure_present_onlyif

  $cmd_ensure_present_onlyif = "\
${cmd_ensure_boilerplate} \
${cmd_ensure_present_onlyif_frag_1} \
"

  $cmd_ensure_present_frag_1 = @(END_cmd_ensure_present_frag_1)
    $member_names | Foreach-Object {
      If(!($target_group_members_usernames -contains $_)) {
        $cur_user = $null
        Try{
          $cur_user = Get-ADUser $cur_member_name
          Add-ADGroupMember $target_group_name -Member $cur_user
        } Catch {
          Write-Warning $error[0]
          Throw $error[0]
        }
      }
    }
    | END_cmd_ensure_present_frag_1

    $cmd_ensure_present = "\
${cmd_ensure_boilerplate} \
${cmd_ensure_present_frag_1} \
"
  $cmd_ensure_absent_frag_1 = @(END_cmd_ensure_absent_frag_1)
    $member_names | Foreach-Object {
      If(!($target_group_members_usernames -contains $_)) {
        $cur_user = $null
        Try{
          $cur_user = Get-ADUser $cur_member_name
          Remove-ADGroupMember $target_group_name -Member $cur_user -Confirm:$False
        } Catch {
          Write-Warning $error[0]
          Throw $error[0]
        }
      }
    }
    | END_cmd_ensure_absent_frag_1

  $cmd_ensure_absent = "\
${cmd_ensure_boilerplate} \
${cmd_ensure_absent_frag_1} \
"
  $cmd_ensure_absent_unless_frag_1 = @(END_cmd_ensure_absent_unless)
    $found_extra_members = $false
    $member_names | Foreach-Object {
      If($target_group_members_usernames -contains $_)) {
        $found_extra_members = $true
      }
    }

    If($found_extra_members) {
      Exit 1
    } Else {
      Exit 0
    }
    | END_cmd_ensure_absent_unless

  $cmd_ensure_absent_unless = "\
${cmd_ensure_boilerplate} \
${cmd_ensure_absent_unless_frag_1} \
"

  if($ensure == 'present'){
    exec { "add_ad_group_member_${group_name}":
      command  => $cmd_ensure_present,
      unless   => $cmd_ensure_present_onlyif,
      provider => 'powershell',
    }
  } else {
    exec { "remove_ad_group_member_${group_name}":
      command  => $cmd_ensure_absent,
      onlyif   => $cmd_ensure_absent_unless,
      provider => 'powershell',
    }
  }
}