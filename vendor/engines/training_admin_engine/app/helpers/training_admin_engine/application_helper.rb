module TrainingAdminEngine
  module ApplicationHelper
    def generate_avatar_initial(name)
      parts = name.to_s.split
      first_initial = parts.first[0].upcase
      last_initial = parts.last[0].upcase
      "#{first_initial}#{last_initial}"
    end
  end
end
