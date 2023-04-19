class <%= user_model.camelize %>InformationCard < ActiveRecord::Base    
  belongs_to :<%= user_model.underscore %>
end
