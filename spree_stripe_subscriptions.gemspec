# encoding: UTF-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_stripe_subscriptions/version'

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'spree_stripe_subscriptions'
  s.version = SpreeStripeSubscriptions.version
  s.summary = 'Spree extension to manage stripe subscriptions using Stripe Checkout Session.'
  s.description = s.summary
  s.required_ruby_version = '>= 2.5'

  s.author = 'Satyakam Pandya'
  s.email = 'satyakampandya@gmail.com'
  s.homepage = 'https://github.com/satyakampandya/spree_stripe_subscriptions'
  s.license = 'BSD-3-Clause'

  s.files = `git ls-files`.split("\n").reject { |f| f.match(/^spec/) && !f.match(/^spec\/fixtures/) }
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree', '>= 4.3.0'
  s.add_dependency 'spree_backend'
  s.add_dependency 'spree_extension'

  s.add_dependency 'stripe', '>= 3.3.2', '< 8.0.0'
  s.add_dependency 'stripe_tester'

  s.add_dependency 'deface', '~> 1.0'

  s.add_development_dependency 'spree_dev_tools'
end
