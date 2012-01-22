require 'puppet/face'

Puppet::Face.define(:autoami, '0.0.1') do
  copyright "Puppet Labs", 2011
  license   "Apache 2 license; see COPYING"

  summary "Automatically update EC2 AMIs on infrastructure change"
end
