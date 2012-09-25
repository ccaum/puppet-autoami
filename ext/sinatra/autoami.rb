require 'rubygems'
require 'sinatra'
require 'puppet/face'

## This needs to be a Torquebox app

class AutoAMI < Sinatra::Base

  get '/run' do
    fork {
      Puppet::Face[:autoami, :current].run
    }
    "Running AutoAMI in the background"
  end

  get '/launch/:group' do
    fork {
      Puppet::Face[:node_aws, :current].launch params[:group]
    }
    "Launching AutoAMI #{params[:group]} group in the background"
  end

  get '/list' do
    Puppet::Face[:node_aws, :current].list.to_yaml
  end
end
