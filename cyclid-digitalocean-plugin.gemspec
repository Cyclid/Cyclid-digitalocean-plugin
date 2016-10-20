# frozen_string_literal: true
Gem::Specification.new do |s|
  s.name        = 'cyclid-digitalocean-plugin'
  s.version     = '0.1.0'
  s.licenses    = ['Apache-2.0']
  s.summary     = 'Cyclid Digitalocean plugin'
  s.description = 'Creates Digitalocean Droplet build hosts'
  s.authors     = ['Kristian Van Der Vliet']
  s.homepage    = 'https://cyclid.io'
  s.email       = 'contact@cyclid.io'
  s.files       = Dir.glob('lib/**/*')

  s.add_runtime_dependency('droplet_kit', '~> 1.4')
end
