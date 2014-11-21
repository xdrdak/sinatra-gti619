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
          flash[:success] = env['warden'].message || "Successfull Login"
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


        # logout
        get '/auth/logout' do
          env['warden'].raw_session.inspect
          env['warden'].logout
          flash[:success] = "Successfully logged out"
          redirect '/'
        end
    end
end

