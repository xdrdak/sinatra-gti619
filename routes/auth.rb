module SST
  class SinatraWarden < Sinatra::Base
    # security
        # login
        get '/auth/login' do

          if env['warden'].authenticated?
            flash[:success] = env['warden'].message || "You're logged in!"
            redirect '/'
          end
          erb :login
        end

        post '/auth/login' do

          if env['warden'].authenticated?
            flash[:success] = env['warden'].message || "You're already logged in!"
            redirect '/'
          end
          # call warden strategies
          env['warden'].authenticate!
          # warden message
          flash[:success] = env['warden'].message || "Successful Login"
          # come from protected page ??
          if session[:return_to].nil?
            redirect "/"
          else
            redirect session[:return_to]
          end
        end

        # accessing unauthenticated user to protected path
        post '/auth/unauthenticated' do
          session[:return_to] = env['warden.options'][:attempted_path]
          flash[:error] = env['warden'].message  || 'You must to login to continue'
          redirect '/auth/login'
        end

        get '/auth/forgot' do
            erb '/forgot_pw'.to_sym
        end

        get '/auth/reset/:token' do |t|
          user = User.first(:reset_token => t)
          if user
            token = user.reset_token
            token_array = token.split('_')
            time = DateTime.parse(token_array[1])

            time_expired = (DateTime.now > time)
            #http://127.0.0.1:9393/auth/reset/c5b4f17c8c1f0e9265008851b7d5d92f_2014-11-26T20:32:36-05:00
            puts time_expired
            if time_expired
              flash[:error] = "Password reset link is expired!"
              redirect '/'
            else
              user.status = Status::NEEDRESETBYMAIL
              user.save
              env['warden'].set_user(user)
              redirect '/protected/reset'
            end
            puts time_expired
          end
          flash[:error] = "Password reset link is expired!"
          redirect '/'
        end

        post '/auth/forgot' do
          flash[:success] = "Password recovery instructions has been sent."
          if params['user'] &&  params['user'] != 'admin'
          user = User.first(:username => params['user'])
            if user && user.status != Status::LOCKED
              send_reset(user)
            end
          end
           redirect  '/'
        end


        # logout
        get '/auth/logout' do
          env['warden'].raw_session.inspect
          env['warden'].logout
          flash[:success] = "Successfully logged out"
          redirect '/'
        end
    end
end

