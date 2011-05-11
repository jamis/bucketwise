Gem::Specification.new do |s|
  s.name        = 'cached_externals'
  s.version     = '1.0.0'
  s.date        = '2010-03-29'
  s.summary     = 'Symlink to external dependencies, rather than bloating your repositories with them'
  s.description = s.summary

  s.add_dependency('capistrano')

  s.files = Dir['lib/**/*']

  s.author   = 'Jamis Buck'
  s.email    = 'jamis@jamisbuck.org'
  s.homepage = 'http://github.com/37signals/cached_externals'
end
