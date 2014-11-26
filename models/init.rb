# database requires
require "data_mapper"
require 'dm-aggregates'
require "bcrypt"

# database url
if ENV['DATABASE_URL'].nil?
     url = "sqlite://#{Dir.pwd}/db/authentication.db"
else
 url = ENV['DATABASE_URL']
end

DataMapper.setup :default, url

# require models
require_relative "user"
require_relative "security_setting"
require_relative "oldpw"
require_relative "log"

# finalize
DataMapper.finalize
DataMapper.auto_upgrade!

# Data Generation
if User.count == 0
  @user = User.create(username: "admin")
  @user.password = "admin"
  @user.permission = Permissions::ADMIN
  @user.email = "x.drdak@gmail.com"
  @user.status = Status::ACTIVE
  @user.save

  @user = User.create(username: "circle")
  @user.password = "circle"
  @user.permission = Permissions::CIRCLE
   @user.email = "x.drdak@gmail.com"
  @user.status = Status::ACTIVE
  @user.save

  @user = User.create(username: "rectangle")
  @user.password = "rectangle"
  @user.permission = Permissions::RECT
  @user.email = "x.drdak@gmail.com"
  @user.status = Status::ACTIVE
  @user.save
end

if SecuritySetting.count == 0
  @security_setting = SecuritySetting.create
  @security_setting.save

end



