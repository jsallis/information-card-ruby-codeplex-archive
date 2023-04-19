class <%= user_model.camelize %>InformationCardController < ApplicationController
  include InformationCardAuthentication::ControllerExtensions
  
end