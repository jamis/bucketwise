# ---------------------------------------------------------------------------
# This is a recipe definition file for Capistrano. The tasks are documented
# below.
# ---------------------------------------------------------------------------
# This file is distributed under the terms of the MIT license by 37signals,
# LLC, and is copyright (c) 2008 by the same. See the LICENSE file distributed
# with this file for the complete text of the license.
# ---------------------------------------------------------------------------

Capistrano::Configuration.instance.load do
  # The :external_modules variable is used internally to load and contain the
  # contents of the config/externals.yml file. Although you _could_ set the
  # variable yourself (to bypass the need for a config/externals.yml file, for
  # instance), you'll rarely (if ever) want to.
  #
  # If ONLY_MODS is set to a comma-delimited string, you can specify which
  # modules to process explicitly.
  #
  # If EXCEPT_MODS is set to a comma-delimited string, the specified modules
  # will be ignored.
  set(:external_modules) do
    require 'yaml'

    modules = YAML.load_file("config/externals.yml") rescue {}

    if ENV['ONLY_MODS']
      patterns = ENV['ONLY_MODS'].split(/,/).map { |s| Regexp.new(s) }
      modules = Hash[modules.select { |k,v| patterns.any? { |p| k.to_s =~ p } }]
    end

    if ENV['EXCEPT_MODS']
      patterns = ENV['EXCEPT_MODS'].split(/,/).map { |s| Regexp.new(s) }
      modules = Hash[modules.reject { |k,v| patterns.any? { |p| k.to_s =~ p } }]
    end

    modules.each do |path, options|
      strings = options.select { |k, v| String === k }
      raise ArgumentError, "the externals.yml file must use symbols for the option keys (found #{strings.inspect} under #{path})" if strings.any?
    end
  end

  def in_local_stage?
    exists?(:stage) && stage == :local
  end

  set(:shared_externals_dir) do
    if in_local_stage?
      File.expand_path("../shared/externals")
    else
      File.join(shared_path, "externals")
    end
  end

  set(:shared_gems_dir) do
    if in_local_stage?
      File.expand_path("../shared/gems")
    else
      File.join(shared_path, "gems")
    end
  end

  def process_external(path, options)
    puts "configuring #{path}"
    shared_dir = File.join(shared_externals_dir, path)

    if options[:type] == 'gem'
      process_external_gem(path, shared_dir, options)
    else
      process_external_scm(path, shared_dir, options)
    end
  end

  def process_external_gem(path, shared_dir, options)
    name = options[:name] || File.basename(path)
    base = File.dirname(path)

    destination = File.join(shared_gems_dir, "gems/#{name}-#{options[:version]}")
    install_command = fetch(:gem, "gem") + " install --quiet --ignore-dependencies --no-ri --no-rdoc --install-dir='#{shared_gems_dir}' '#{name}' -v '#{options[:version]}'"

    if in_local_stage?
      FileUtils.rm_rf(path)
      FileUtils.mkdir_p(base)
      if !File.exists?(destination)
        FileUtils.mkdir_p(shared_gems_dir)
        system(install_command) or raise "error installing #{name}:#{options[:version]} gem"
      end
      FileUtils.ln_s(destination, path)
    else
      commands = [
        "mkdir -p #{shared_gems_dir} #{latest_release}/#{base}",
        "if [ ! -d #{destination} ]; then (#{install_command}) || (rm -rf #{destination} && false); fi",
        "ln -nsf #{destination} #{latest_release}/#{path}"
      ]

      run(commands.join(" && "))
    end
  end

  def process_external_scm(path, shared_dir, options)
    scm = Capistrano::Deploy::SCM.new(options[:type], options)
    revision =
      begin
        scm.query_revision(options[:revision]) { |cmd| `#{cmd}` }
      rescue => scm_error
        $stderr.puts scm_error
        next
      end

    destination = File.join(shared_dir, revision)

    if in_local_stage?
      FileUtils.rm_rf(path)
      FileUtils.mkdir_p(shared_dir)
      if !File.exists?(destination)
        unless system(scm.checkout(revision, destination))
          FileUtils.rm_rf(destination) if File.exists?(destination)
          raise "Error checking out #{revision} to #{destination}"
        end
      end
      FileUtils.ln_s(destination, path)
    else
      run "rm -rf #{latest_release}/#{path} && mkdir -p #{shared_dir} && if [ ! -d #{destination} ]; then (#{scm.checkout(revision, destination)}) || rm -rf #{destination}; fi && ln -nsf #{destination} #{latest_release}/#{path}"
    end
  end

  desc "Indicate that externals should be applied locally. See externals:setup."
  task :local do
    set :stage, :local
  end

  namespace :externals do
    desc <<-DESC
      Set up all defined external modules. This will check to see if any of the
      modules need to be checked out (be they new or just updated), and will then
      create symlinks to them. If running in 'local' mode (see the :local task)
      then these will be created in a "../shared/externals" directory relative
      to the project root. Otherwise, these will be created on the remote
      machines under [shared_path]/externals.

      Specify ONLY_MODS to process only a subset of the defined modules, and
      EXCEPT_MODS to ignore certain modules for processing.

        $ cap local externals:setup ONLY_MODS=rails,solr
        $ cap local externals:setup EXCEPT_MODS=rails,solr
    DESC
    task :setup, :except => { :no_release => true } do
      require 'fileutils'
      require 'capistrano/recipes/deploy/scm'

      external_modules.each do |path, options|
        process_external(path, options)
      end
    end
  end

  # Need to do this before finalize_update, instead of after update_code,
  # because finalize_update tries to do a touch of all assets, and some
  # assets might be symlinks to files in plugins that have been externalized.
  # Updating those externals after finalize_update means that the plugins
  # haven't been set up yet when the touch occurs, causing the touch to
  # fail and leaving some assets temporally out of sync, potentially, with
  # the other servers.
  before "deploy:finalize_update", "externals:setup"
end
