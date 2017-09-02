# encoding: UTF-8

## Set working directory, load gems and create logs
## Using pathname extentions for setting public folder
require 'pathname'
## Set up root object, it might be used by the environment and\or the plezi extension gems.
Root ||= Pathname.new(File.dirname(__FILE__)).expand_path

## If this app is independant, use bundler to load gems (including the plezi gem).
## Else, use the original app's Gemfile and start Plezi's Rack mode.
require 'bundler'
Bundler.require(:default, ENV['ENV'].to_s.to_sym)

## make sure all file access and file loading is relative to the application's root folder
# Dir.chdir Root.to_s
## load code from a subfolder called 'code'
# Dir[File.join "{code}", "**" , "*.rb"].each {|file| load File.expand_path(file)}
# load Root.join('pdf_controller.rb').to_s
Dir[File.join File.dirname(__FILE__), '*.rb'].each { |file| load File.expand_path(file) unless file == __FILE__ }

# start a web service to listen on the first default port (3000 or the port set by the command-line).
# you can change some of the default settings here.
Plezi.assets = Root.join('assets').to_s
Plezi.templates = Root.join('templates').to_s

# Plezi.route '/:locale/*', /en|he/

# Add your routes and controllers by order of priority.
Plezi.route '/', PDFController
