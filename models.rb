require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class ApplicationRecord < ActiveRecord::Base
    self.abstract_class=true
end

class Joke < ApplicationRecord
    has_many :favs
    has_many :faved_users, through: :favs, source: :user
    
    has_many :answers
    has_many :joke_answers, through: :answers, source: :user
end

class User < ApplicationRecord
    has_secure_password
    validates :name, presence: true, uniqueness: true
    validates :password, presence: true, format: { with: /\A(?=.*?[A-Za-z])(?=.*?\d)[A-Za-z\d]+\z/i}
    
    has_many :favs
    has_many :faved_jokes, through: :favs, source: :joke
    
    has_many :answers
    has_many :user_answers, through: :answers, source: :joke
end

class Fav < ApplicationRecord
    belongs_to :user
    belongs_to :joke
end

class Answer < ApplicationRecord
    belongs_to :user
    belongs_to :joke
end