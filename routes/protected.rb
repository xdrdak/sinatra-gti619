module SST
  class SinatraWarden < Sinatra::Base
    #require './helpers/protected_helper'

    get '/protected' do
      env['warden'].authenticate!
      erb :protected
    end

    get '/protected/circle' do
      authorize(Permissions::CIRCLE)
      erb "protected/circle".to_sym
    end

    get '/protected/rectangle' do
      authorize(Permissions::RECT)
      erb "protected/rectangle".to_sym
    end

    get '/protected/pwupdate' do
      authorize(Permissions::ANY)
      @security_settings =SecuritySetting.first
      erb "protected/pw_update".to_sym
    end

    post '/protected/pwupdate' do
      authorize(Permissions::ANY)
      user = env['warden'].user

      puts params['oldpwd']
      @security_settings =SecuritySetting.first

      if params['oldpwd'] and params['newpwd'] and params['newpwdconf']
        if user.authenticate(params['oldpwd']) and params['newpwd'] == params['newpwdconf'] and @security_settings.validate_pwd(params['newpwd'])
          flash[:success] = "New password has been set!"
          user.password = params['newpwd']
          user.save
        else
           flash[:error] = "Passwords are invalid! Make sure you enter your passwords correctly"
        end
      else
         flash[:error] = "All fields are required!"
      end

       redirect '/protected/pwupdate'


    end

    get '/protected/siteconfig' do
      authorize(Permissions::ADMIN)
      @security_settings =SecuritySetting.first
      erb "protected/siteconfig".to_sym
    end


     post '/protected/siteconfig' do
      authorize(Permissions::ADMIN)
      @security_settings =SecuritySetting.first
      if params['securitysetting'] and  @security_settings.update(params['securitysetting'])
        flash[:success] = "Security settings saved!"
        redirect '/protected/siteconfig'
      else
         flash[:error] = "There are are errors in the settings!"
         erb "protected/siteconfig".to_sym
      end

    end


    #Authenticate and authorize : All in one!
    def authorize(permission)
      #Use warden for authentication. If it fails, bounce back to login
      env['warden'].authenticate!
      user = env['warden'].user
      #Checking for permissions. A wrong permission will throw a 403
      valid = false
      if permission == Permissions::ADMIN
        valid = user.is_admin?
      elsif permission == Permissions::CIRCLE
        valid = user.is_circle?
      elsif permission == Permissions::RECT
        valid = user.is_rectangle?
      elsif permission == Permissions::ANY
        valid = true
      end

      if !valid
        error 403
      end
    end

  end
end
