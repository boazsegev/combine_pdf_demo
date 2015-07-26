# encoding: UTF-8

## Set working directory, load gems and create logs
	## Using pathname extentions for setting public folder
	require 'pathname'
	## Set up root object, it might be used by the environment and\or the plezi extension gems.
	Root ||= Pathname.new(File.dirname(__FILE__)).expand_path
	## make sure all file access and file loading is relative to the application's root folder
	# Dir.chdir Root.to_s
	## load code from a subfolder called 'code'
	# Dir[File.join "{code}", "**" , "*.rb"].each {|file| load File.expand_path(file)}
	load Root.join('pdf_controller.rb').to_s

	## If this app is independant, use bundler to load gems (including the plezi gem).
	## Else, use the original app's Gemfile and start Plezi's Rack mode.
		require 'bundler'
		Bundler.require(:default, ENV['ENV'].to_s.to_sym)
		## OR:
		# Plesi.start_rack # remember 

	## Uncomment to create a log file
	# GReactor.create_logger File.expand_path(Root.join('server.log').to_s)

## Options for Scaling the app (across processes or machines):
	## uncomment to set up forking.
	# GReactor::Settings.set_forking 4
	## Redis scaling
	# Plezi::Settings.redis_channel_name = 'demo_6d697a793aa7c555d3450b676fdf79fa'
	# ENV['PL_REDIS_URL'] ||= ENV['REDIS_URL'] || ENV['REDISCLOUD_URL'] || ENV['REDISTOGO_URL'] || "redis://username:password@my.host:6389"


# start a web service to listen on the first default port (3000 or the port set by the command-line).
# you can change some of the default settings here.
listen 	host: :default,
		# root: Root.join('public').to_s,
		assets: Root.join('assets').to_s,
		templates: Root.join('templates').to_s,
		ssl: false

route "/:locale{en|he}/*" , false
	#
	## OAuth2 - Facebook / Google authentication
	# require 'plezi/oauth'
	# ENV["FB_APP_ID"] ||= "app id"; ENV["FB_APP_SECRET"] ||= "secret"; ENV['GOOGLE_APP_ID'] = "app id"; ENV['GOOGLE_APP_SECRET'] = "secret"
	# create_auth_shared_route do |service_name, auth_token, remote_user_id, remote_user_email, remote_response|
	#         # ...callback for authentication.
	#         # This callback should return the app user object or false
	#         # This callback has access to the controller's methods (request, cookies, response, etc')
	# end

# Add your routes and controllers by order of priority.
route '/(:id)', PDFController

