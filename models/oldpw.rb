class Oldpw
    include DataMapper::Resource
    include BCrypt
    property :id             ,Serial
    property :user_id,  Integer
    property :password       , BCryptHash
    property :salt, String         ,length: 0..100


    def already_exists?(user_id, pwd, old_pw_keep)
        old_pw_list = Oldpw.all(user_id: user_id)
        pwd_count = 0

        old_pw_list.last(old_pw_keep + 1).each do |p|
            if p.password == pwd
                pwd_count += 1
            end
        end

        if pwd_count == 0
            false
        else
            true
        end

    end
end
