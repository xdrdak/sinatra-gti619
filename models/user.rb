# User class
class User
  include DataMapper::Resource
  include BCrypt

  # hooks
  before :save, :generate_token
  before :create, :generate_token

  # properties
  property :id             ,Serial
  property :username       ,String         ,length: 0..50, :unique => true
  property :email           ,String         ,length: 0..200
  property :name           ,String         ,length: 0..200
  property :permission        ,Integer         ,default: 0
  property :password       ,BCryptHash
  property :salt          ,String         ,length: 0..100
  property :created        ,DateTime
  property :password_update_date, DateTime
  property :last_login_attempt        ,DateTime
  property :status         ,Integer        ,default: 0
  property :login_tries         ,Integer        ,default: 0
  property :crypt_version, String, default: "bcrypt3.1.9"
  property :reset_token, Text

  # methods
  def generate_token
    # generate token
    self.salt = BCrypt::Engine.generate_salt if self.salt.nil?
  end

  def next_password_update_date(amount, save = true)
    self.password_update_date = DateTime.now +  amount
    if save
      self.save
    end
  end

  def authenticate(pass)
    self.password == pass
  end

  def generate_reset_token
    self.reset_token = SecureRandom.hex + "_" + (DateTime.now + 1).to_s
  end

  def is_circle?
      self.permission == Permissions::CIRCLE or self.permission == Permissions::ADMIN
  end

  def is_rectangle?
      self.permission == Permissions::RECT or self.permission == Permissions::ADMIN
  end

  def is_admin?
      self.permission == Permissions::ADMIN
  end

  def softlock_timeleft
    SecuritySetting.first.soft_timeout - self.softlock_time_elapsed
  end

  def softlock_time_elapsed
    if self.last_login_attempt
      ((DateTime.now - self.last_login_attempt) * 24 *60).to_i
    else
      -1
    end

  end

  def is_on_cooldown?
    timediff = self.softlock_time_elapsed
    if self.status == Status::SOFTLOCKED and timediff < SecuritySetting.first.soft_timeout
      true
    else
      false
    end

  end

  def reset_as_active(save = true)
    self.login_tries = 0
    self.last_login_attempt  = DateTime.now
    self.status = Status::ACTIVE
    if save
      self.save
    end

  end

  def add_login_tries
    self.login_tries = self.login_tries + 1
    self.last_login_attempt  = DateTime.now
    security_settings = SecuritySetting.first

    if self.login_tries >= security_settings.max_hardlock_attempt
      self.status = Status::LOCKED
    elsif self.login_tries % security_settings.max_softlock_attempt == 0
      self.status = Status::SOFTLOCKED
    end

    self.save
  end


end
