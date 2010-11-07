run "rm public/index.html"
run "rm README"
run "rm -Rf doc"

gem 'pg'
gem 'dm-rails'
gem 'dm-postgres-adapter'
gem 'dm-migrations'
gem 'dm-constraints'
gem 'dm-timestamps'
gem 'dm-validations'
gem 'dm-types'
gem 'dm-transactions'

gem 'haml'
gem 'formtastic'
gem 'rspec-rails', :group => :test
gem 'machinist',   '~> 1.0.6'
gem 'timecop'
gem 'steak'
gem 'capybara'
gem 'faker'

generate 'rspec:install'
generate 'steak:install'

get 'http://github.com/rails/jquery-ujs/raw/master/src/rails.js', 'public/javascripts/rails.js'
get 'http://code.jquery.com/jquery-1.4.3.js',                     'public/javascripts/jquery-1.4.3.js'

src = 'https://github.com/xaviershay/sandbox/raw/master/rails'
get "#{src}/at.rb",                     'spec/support/at.rb'
get "#{src}/set.rb",                    'spec/support/set.rb'
get "#{src}/rspec_extensions.rb",       'spec/support/extensions.rb'
get "#{src}/pg_nested_transactions.rb", 'config/initializers/pg_nested_transactions.rb'
get "#{src}/data_mapper_ex.rb",         'config/initializers/data_mapper_ex.rb'
get "#{src}/build.rake",                'lib/tasks/build.rake'
get "#{src}/rspec.rake",                'lib/tasks/rspec.rake'

git :init
git :add => '.'
git :commit => "a -m 'Initial commit'"
