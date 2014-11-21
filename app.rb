# main requires
require "sinatra"
require "warden"
require "rack-flash"



require_relative "permissions"
require_relative "status"

# require models
require_relative "models/init"


# main class
module SST
  class SinatraWarden < Sinatra::Base
    # enabling sessions and configuring flash
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
          fail!("This account has been locked. Please contact the administrator.")
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

  end
end
# require routes
require_relative "routes/init"

