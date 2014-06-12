# validate_password.rb
# Simple function to validate a password
#
# Created by Jerome RIVIERE (www.jerome-riviere.re) (https://github.com/ninja-2)
require "puppet"

module Puppet::Parser::Functions
  newfunction(:validate_password, :type => :rvalue, :doc => <<-EOS
validate a given password with complexity requirements
    EOS
  ) do |args|
    raise(Puppet::ParseError, "validate_password(): Wrong number of arguments " +
      "given (#{args.size} for 1)") if args.size != 1
    reg = /^(?=.*\d)(?=.*([a-z]|[A-Z]))([\x20-\x7E]){8,}$/
    return (reg.match(args[0]))? true : false
  end
end