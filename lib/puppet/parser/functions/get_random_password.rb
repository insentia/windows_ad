# get_random_password.rb
# Simple function that generate a password
#
# Created by Jerome RIVIERE (www.jerome-riviere.re) (https://github.com/ninja-2)
require "puppet"

module Puppet::Parser::Functions
  newfunction(:get_random_password, :type => :rvalue, :doc => <<-EOS
Returns a random password.
    EOS
  ) do |args|
    raise(Puppet::ParseError, "get_random_password(): Wrong number of arguments " +
      "given (#{args.size} for 1)") if args.size != 1
    specials = ((33..33).to_a + (35..38).to_a + (40..47).to_a + (58..64).to_a + (91..93).to_a + (95..95).to_a + (123..125).to_a).pack('U*').chars.to_a
    numbers  = (0..9).to_a
    alphal = ('a'..'z').to_a
    alphau = ('A'..'Z').to_a
    if ((args[0].to_i) <= 7)
      length = 10
    else
      length = args[0].to_i
    end
    regchain = (alphal + specials + alphau + numbers)
    pwd = regchain.sort_by { rand }.join[0...length]
    return pwd
  end
end
