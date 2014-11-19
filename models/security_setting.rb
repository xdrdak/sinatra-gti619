# SecuritySetting class
class SecuritySetting
  include DataMapper::Resource

  # properties
  property :id, Serial
  property :max_softlock_attempt, Integer,  :required => true , :default => 3
  property :max_hardlock_attempt, Integer,  :required => true,  :default => 6
  property :soft_timeout, Integer,  :required => true, :default => 60
  property :pwd_min_len, Integer,  :required => true, :default => 6
  property :pwd_lowers, Integer,  :required => true, :default => 1
  property :pwd_uppers, Integer,  :required => true, :default => 1
  property :pwd_number, Integer,  :required => true, :default => 1
  property :pwd_specials, Integer,  :required => true, :default => 1
  property :old_pwd_keep, Integer,  :required => true, :default => 0

  def validate_pwd(pwd)
    upper_count = (pwd.scan /\p{Upper}/).length
    lower_count = (pwd.scan /\p{Lower}/).length
    number_count = (pwd.scan /\p{Digit}/).length
    symbol_count = (pwd.scan /\W/).length

    if pwd.length >= self.pwd_min_len and upper_count >= self.pwd_uppers and
      lower_count >= self.pwd_lowers and number_count >= self.pwd_number and symbol_count >= pwd_specials
      true
    else
      false
    end
  end
end
