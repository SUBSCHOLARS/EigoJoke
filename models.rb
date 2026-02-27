require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class Joke < ActiveRecord::Base
end