# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'multi_timer'
  app.frameworks += ['AudioToolbox']

  # Create constants.rb to use these settings.
  if File.exists?("constants.rb")
    load "constants.rb"
    app.provisioning_profile = PROVISIONING_PROFILE 
    app.codesign_certificate = CODESIGN_CERTIFICATE
  end
end
