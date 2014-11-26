#
# Main routing
#
module SST
  class SinatraWarden < Sinatra::Base
    after do
      if env['warden'].authenticated?
        if (env['warden'].user.status == Status::NEEDRESET || env['warden'].user.status == Status::NEEDRESETBYMAIL) && request.path_info != "/protected/reset"
          redirect '/protected/reset'
        end
      end
    end
    # site index
    get "/" do
      erb :index
    end

    error 403 do
      erb "403".to_sym
    end

    # not found catch
    not_found do
      erb "404".to_sym
    end

    get '/main' do
      env['warden'].authenticate!
      erb :main
    end

  end
end
