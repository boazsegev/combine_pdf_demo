source "https://rubygems.org"

####################
# core gems

# include the basic plezi framework and server
gem 'plezi'

# combine_pdf gem for this demo app
gem 'combine_pdf'

####################
# development gems

# use pry gem for basic debug ( put `binding.pry` at breake point )?
# gem 'pry'


# active support can run without rails and extends the Ruby language.
# it might be heavy, be warned.
# see: http://guides.rubyonrails.org/active_support_core_extensions.html
# 
# gem 'activesupport', :require => ['active_support', 'active_support/core_ext'] 
# or:
# gem 'activesupport', :require => ['active_support', active_support/all'] 


####################
# gems for easy markup

## Slim is very recommended for HTML markup, it's both easy and fast.
gem 'slim'

## Sass makes CSS easy
gem "sass"

## erb for HTML fanatics:
# gem 'erb'

## we love Haml, even though it can be slow:
# gem 'haml'

## and maybe coffee script? (although, we just use javascript, really)
# gem "coffee-script"

####################
# Internationalization

## I18n is the only one I know of.
gem 'i18n'

####################
# WebSocket Scaling

## redis servers are used to allow websocket scaling.
## the :broadcast and :collect methods will work only for the current process.
## using Redis, we can publish messages and subscribe to 'chunnels' across processes
# (limited support for :broadcast and NO support for :collect while Redis is running).

# gem 'redis'

####################
# gems for databases and models

## if you want to use a database, here are a few common enough options:
# gem 'mysql2'
# gem 'sqlite3'
# gem 'pg'

## MongoDB is a very well known NoSQL DB
## https://github.com/mongodb/mongo-ruby-driver
# gem 'mongo'
## for a performance boost, the C extentions can be used (NOT JRuby - bson_ext isn't used with JRuby).
# gem 'bson_ext'
## you can also have a look at the Mongo Mapper ORM
## http://mongomapper.com
# gem 'mongo_mapper'

## someone told me good things about sequel:
## http://sequel.jeremyevans.net/rdoc/files/README_rdoc.html
## http://sequel.jeremyevans.net/rdoc/files/doc/cheat_sheet_rdoc.html
## this seems greate, but we left out any auto-config for this one... seems to work out of the box.
# gem 'sequel'

## if you want to use ActiveRecord, uncomment the following line(s)...
## but first, please remember that AcriveRecord needs extra attention when multi-threading
# gem 'activerecord', :require => 'active_record'
# gem 'bcrypt', '~> 3.1.7'



ruby '2.2.0'
