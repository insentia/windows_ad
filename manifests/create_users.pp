class windows_ad::create_users() {

  $defaults = {
    writetoxmlflag => false,
  }

  $userhash = hiera('windows_ad::userlist')
  create_resources(windows_ad::user, $userhash, $defaults)
}
