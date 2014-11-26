# main requires
require "sinatra"
require "sinatra/config_file"
require "warden"
require "rack-flash"
require 'rack/ssl'
require 'pony'


require_relative "permissions"
require_relative "status"

# require models
require_relative "models/init"

# main class
module SST
  class SinatraWarden < Sinatra::Base
    register Sinatra::ConfigFile
    config_file './config/config.yml'
    # enabling sessions and configuring flash
    #use Rack::SSL
    use Rack::Session::Cookie, :expire_after => 86400, secret: "1d8cf82056f6c031aff000fa7f0068c852b9cb669066591981b9df875555d6be"
    use Rack::Flash, accessorize: [:error, :success]

    # configuration
    # warden configuration
    use Warden::Manager do |config|
      # serialize user to session ->
      config.serialize_into_session{|user| user.id}
      # serialize user from session <-
      config.serialize_from_session{|id| User.get(id) }
      # configuring strategies
      config.scope_defaults :default, strategies: [:password], action: 'auth/unauthenticated'
      #
      config.failure_app = self
    end

    # redirect method for POST
    Warden::Manager.before_failure do |env,opts|
      env['REQUEST_METHOD'] = 'POST'
    end

    # implement warden strategies
    Warden::Strategies.add(:password) do
      # flash is not reached
      # we create a wrap
      def flash
        env['x-rack.flash']
      end

      # valid params for authentication
      def valid?
        params['user'] && params['user']['username'] && params['user']['password']
      end

      # authenticating user
      def authenticate!
        # find for user
        user = User.first(username: params['user']['username'])

        if user.nil?
          fail!("Account does not exist or the password is invalid")
          flash.error = ""
        elsif  user.status == Status::LOCKED
          fail!("This account has been locked. Please contact the administrator to restore your account")
        elsif user.is_on_cooldown?
          log = Log.create(related_user: user.username, message: "User in softlock attempted to log in")
          fail!("This account has been temporarily suspended. Please try again in " + user.softlock_timeleft.to_s + " minutes")
        elsif user.authenticate(params['user']['password'])
            log = Log.create(related_user: user.username, message: "User has logged in")
            log.save
            flash.success = "Logged in"
            user.reset_as_active
            days_before_pw_expire = SecuritySetting.first.days_before_pw_expire

            if !user.password_update_date
              user.next_password_update_date(days_before_pw_expire)
            elsif days_before_pw_expire > 0 and user.password_update_date < DateTime.now
              user.status = Status::NEEDRESET
              user.save
            end
            success!(user)
        else
          log = Log.create(related_user: user.username, message: "User failed to login")
          log.save
          user.add_login_tries
          fail!("Account does not exist or the password is invalid")
        end
      end

    end

     def mail_to(email, subjet, content)
        Pony.mail(
                :to => email,
                :from => "no-reply@server.com",
                :subject => subjet,
                :html_body => content,
                :via => :smtp,

                :via_options =>  {
                    :address => 'smtp.gmail.com',
                    :port => '587',
                    :enable_starttls_auto => true,
                    :user_name => settings.server_email_user,
                    :password =>settings.server_email_pw,
                    :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
                    :domain => "HELO", # don't know exactly what should be here
                     }
                )
    end

    def send_reset(user)
        user.generate_reset_token
        user.save
        mail_to(user.email, "Password Reset for FancyLab5",
            "<p>Click on the following link to reset your password : <a href='#{request.base_url}/auth/reset/#{user.reset_token}''>Click here</a><p>")

    end


  end

end
# require routes
require_relative "routes/init"

