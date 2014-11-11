# main requires
require "sinatra"
require "slim"
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
    use Rack::Session::Cookie, secret: "IdoNotHaveAnySecret"
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
          fail!("This account has been temporarily suspended. Please try again in " + user.softlock_timeleft.to_s + " minutes")
        elsif user.authenticate(params['user']['password'])
            flash.success = "Logged in"
            user.reset_as_active
            success!(user)
        else
          user.add_login_tries
          puts user.login_tries
          fail!("Account does not exist or the password is invalid")
        end
      end

    end

  end
end
# require routes
require_relative "routes/init"

