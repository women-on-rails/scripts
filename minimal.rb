run "pgrep spring | xargs kill -9"
run "rm Gemfile"
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'
ruby '#{RUBY_VERSION}'
gem 'rails', '#{Rails.version}' # Rails framework, with specific version
gem 'puma' # HTTP 1.1 server 
gem 'sqlite3' # database
gem 'sass-rails' # RoR integration of Sass stylesheet language (CSS)
gem 'jquery-rails' # jQuery libs (JS) 
gem 'bootstrap-sass' # Sass-powered version of Bootstrap (CSS / JS libs)
gem 'font-awesome-sass' # Sass-powered version of font-awesome : iconic font & css toolkit
gem 'autoprefixer-rails' # parse CSS and add vendor prefixes to CSS rules

group :development, :test do
  gem 'better_errors' # Improve error page by adding console + better readability
  gem 'pry-byebug' # Adds step-by-step debugging and stack navigation capabilities to pry
  gem 'pry-rails' # Use pry instead of standard console
  gem 'spring' # Rails application preloader
end

group :production do
  gem 'rails_12factor' # Better logging & static assets serving
end
RUBY

file ".ruby-version", RUBY_VERSION

file 'Procfile', <<-YAML
web: bundle exec puma -C config/puma.rb
YAML

if Rails.version < "5"
puma_file_content = <<-RUBY
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
threads     threads_count, threads_count
port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }
RUBY

file 'config/puma.rb', puma_file_content, force: true
end

run "rm -rf app/assets/stylesheets"
run "curl -L https://github.com/lewagon/stylesheets/archive/master.zip > stylesheets.zip"
run "unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets"

run 'rm app/assets/javascripts/application.js'
file 'app/assets/javascripts/application.js', <<-JS
//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require_tree .
JS

gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.erb', <<-HTML
<!DOCTYPE html>
<html>
  <head>
    <title>TODO</title>
    <%= csrf_meta_tags %>
    #{Rails.version >= "5" ? "<%= action_cable_meta_tag %>" : nil}
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <%= stylesheet_link_tag    'application', media: 'all' %>
  </head>
  <body>
    <%= yield %>
    <%= javascript_include_tag 'application' %>
  </body>
</html>
HTML

run "rm README.rdoc"
markdown_file_content = <<-MARKDOWN
Rails App
MARKDOWN
file 'README.md', markdown_file_content, force: true

after_bundle do
  rake 'db:drop db:create db:migrate'
  generate(:controller, 'curiosities', 'index', '--no-helper', '--no-assets', '--skip-routes')
  route "root to: 'curiosities#index'"

  run "rm .gitignore"
  file '.gitignore', <<-TXT
.bundle
log/*.log
tmp/**/*
tmp/*
*.swp
.DS_Store
public/assets
TXT
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end