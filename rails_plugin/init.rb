begin
  gem 'information_card'
  require 'information_card'
rescue LoadError
  puts "Install the information_card gem to enable information card support"
end
