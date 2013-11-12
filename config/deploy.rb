require 'rvm/capistrano'
require "bundler/capistrano"

# Choose a Ruby explicitly, or read from an environment variable.
# set :rvm_ruby_string, 'ree@rails3'
# # Load RVM's capistrano plugin.
require 'rvm/capistrano'

set :rvm_type, :user  # Literal ":user"

set :application, "user"
set :repository,  "repo"
set :user, "user"
set :deploy_to, "path/to/stuff"

role :web, "domain.me"                          # Your HTTP server, Apache/etc
role :app, "domain.me"                          # This may be the same as your `Web` server
role :db,  "domain.me", :primary => true # This is where Rails migrations will run


namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

after "deploy:restart", "deploy:cleanup"
