module SST
  class SinatraWarden < Sinatra::Base

    get '/protected' do
      env['warden'].authenticate!
      erb :protected
    end

    get '/protected/reset' do
      user = authorize(Permissions::ANY)
      if user.status != Status::NEEDRESET && user.status != Status::NEEDRESETBYMAIL
        redirect '/'
      end

      @title =  if Status::NEEDRESET == user.status
        "Password expired - Set new Password"
      else
        "Password reset - Set new Password"
      end
      @security_settings = SecuritySetting.first
      erb "/protected/pw_reset".to_sym
    end

    get '/protected/users' do
      authorize(Permissions::ADMIN)
      @users = User.all
      erb '/users/index_admin'.to_sym
    end

    get '/protected/users/:id/reset' do |n|
      authorize(Permissions::ADMIN)
      @s_user = User.get(n)
      if @s_user
       erb '/users/reset'.to_sym
      else
        redirect '/'
      end
    end

    post '/protected/users/:id/reset' do |n|
      user = authorize(Permissions::ADMIN)

      if params['password'] && user.password ==  params['password']
        @s_user = User.get(n)
        if @s_user
          @password = SecureRandom.hex(4)
          @s_user.password = @password
          @s_user.reset_as_active(false)
          @s_user.next_password_update_date(1,false)
          @s_user.save
          mail_to(@s_user.email, "Account Reactivated",
            "<p>Your account has been reactivated. Please log in with the following temporary password : #{@password}</p>
            <p><strong>This password is only valid for 1 day, you must change it as you log in!</strong></p>
            <p><a href='#{request.base_url}/auth/login''>Click here to log in</a><p>")
          erb '/users/reset_confirm'.to_sym
        else
          redirect '/protected/users'
        end
      else
        redirect '/'
      end

    end

    post '/protected/reset' do
      user = authorize(Permissions::ANY)

      if user.status != Status::NEEDRESET
        redirect '/'
      end
      @security_settings = SecuritySetting.first
      if params['newpwd'] == params['newpwdconf'] and @security_settings.validate_pwd(params['newpwd'])
          old_pw_history = Oldpw.new(user_id: user.id, password:  params['newpwd'])

          if old_pw_history.already_exists?(user.id, params['newpwd'], @security_settings.old_pwd_keep)
             flash[:error] = "You've already used this new password before. Please choose another one."
          else
            set_new_pw(user, old_pw_history, params['newpwd'], @security_settings.days_before_pw_expire)
            flash[:success] = "New password has been set!"
            redirect '/'
          end

        else
           flash[:error] = "Passwords are invalid! Make sure you enter your passwords correctly"
      end

      redirect '/protected/reset'
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

      @security_settings = SecuritySetting.first

      if params['oldpwd'] and params['newpwd'] and params['newpwdconf']

        if params['oldpwd'] == params['newpwd']
          flash[:error] = "You cannot use a new password that is the same as the old one!"

        elsif user.authenticate(params['oldpwd']) and params['newpwd'] == params['newpwdconf'] and @security_settings.validate_pwd(params['newpwd'])
          old_pw_history = Oldpw.new(user_id: user.id, password:  params['newpwd'])

          if old_pw_history.already_exists?(user.id, params['newpwd'], @security_settings.old_pwd_keep)
             flash[:error] = "You've already used this new password before. Please choose another one."
          else
            set_new_pw(user, old_pw_history, params['newpwd'], @security_settings.days_before_pw_expire)
            flash[:success] = "New password has been set!"
          end

        else
           flash[:error] = "Passwords are invalid! Make sure you enter your passwords correctly"
        end
      else
         flash[:error] = "All fields are required!"
      end

       redirect '/protected/pwupdate'


    end

    get '/protected/logs' do
      authorize(Permissions::ADMIN)
      @logs = Log.all()
      erb "protected/logs".to_sym

    end

    get '/protected/siteconfig' do
      authorize(Permissions::ADMIN)
      @security_settings =SecuritySetting.first
      erb "protected/siteconfig".to_sym
    end


     post '/protected/siteconfig' do
      user = authorize(Permissions::ADMIN)
      @security_settings =SecuritySetting.first
      if params['securitysetting'] and  @security_settings.update(params['securitysetting'])
        flash[:success] = "Security settings saved!"
        log = Log.create(related_user: user.username, message: "Settings have been changed")
        log.save
        redirect '/protected/siteconfig'
      else
         flash[:error] = "There are errors in the settings!"
         erb "protected/siteconfig".to_sym
      end

    end

private
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
        log = Log.create(related_user: user.username, message: "Tried to access something he was not supposed to")
        log.save

        error 403
      end

      user
    end

    def set_new_pw(user, old_pw_history, pwd, days_before_pw_expire)
        user.password =  pwd
        user.status = Status::ACTIVE
        old_pw_history.save
        user.next_password_update_date(days_before_pw_expire)
        user.save
        log = Log.create(related_user: user.username, message: "Password has been changed ")
        log.save
    end

  end
end
