class windows_ad::create_users() {

  $userhash = hiera('windows_ad::userlist')
  create_resources(windows_ad::user, $userhash)
}
