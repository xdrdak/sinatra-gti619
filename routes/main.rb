#
# Main routing
#
module SST
  class SinatraWarden < Sinatra::Base
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
