namespace :git do
  namespace :hooks do
    desc "Install some git hooks for updating cached externals"
    task :install do
      Dir["#{RAILS_ROOT}/vendor/plugins/cached_externals/script/git-hooks/*"].each do |hook|
        cp hook, ".git/hooks"
        chmod 0755, ".git/hooks/#{File.basename(hook)}"
      end
    end
  end
end
