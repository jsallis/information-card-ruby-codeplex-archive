class InformationCardAuthenticationGenerator < Rails::Generator::NamedBase
  
  attr_reader :user_model
  
  def initialize(runtime_args, runtime_options = {})
    super
    @user_model = class_name
  end

  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => "create_#{user_model.underscore}_information_cards"
      m.template 'model.rb', File.join('app/models', "#{user_model.underscore}_information_card.rb")
      m.template 'controller.rb', File.join('app/controllers', "#{user_model.underscore}_information_card_controller.rb")
      m.template 'helper.rb', File.join('app/helpers', "#{user_model.underscore}_information_card_helper.rb")
      m.directory File.join('app/views', "#{user_model.underscore}_information_card")
      
      m.template 'information_card_authentication_test.rb', File.join('test/unit', 'information_card_authentication_test.rb')
      m.template 'model_test.rb', File.join('test/unit', "#{user_model.underscore}_information_card_test.rb")
      m.template 'controller_test.rb', File.join('test/functional', "#{user_model.underscore}_information_card_controller_test.rb")
      m.template 'fixture.yml', File.join('test/fixtures', "#{user_model.underscore}_information_cards.yml")
      
      m.directory File.join('lib', "information_card_authentication")
      m.template 'information_card_authentication.rb', File.join('lib', 'information_card_authentication.rb')
    end
  end
end