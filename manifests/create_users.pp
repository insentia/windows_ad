class windows_ad::create_users(
  $hieraname = 'windows_ad::userlist',
  $writetoxmlflag = false,
  $domainname,
  $path,
  $passwordneverexpires = false,
  $passwordlength = 14,
  $password = 'Ch@ng3Th1sP@ss',
  $description = 'Created User',
) {

  $defaults = {
    writetoxmlflag => $writetoxmlflag,
    path => $path,
    domainname => $domainname,
    passwordneverexpires => $passwordneverexpires,
    passwordlength => $passwordlength,
    password => $password,
    description => $description,
  }

  $userhash = hiera($hieraname)
  create_resources(windows_ad::user, $userhash, $defaults)
}
