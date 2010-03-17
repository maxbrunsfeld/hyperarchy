module Resources
  class Root < Http::Resource
    def locate(path_fragment)
      case path_fragment
      when "user_repository"
        UserRepository.new(current_user)
      when "users"
        Users.new
      when "login"
        Login.new
      end
    end

    def get(params)
      [200, headers, content]
    end

    def headers
      { "Content-Type" => "text/html" }
    end

    def content
      Views::Root.new(:current_user => current_user).to_pretty
    end
  end
end
