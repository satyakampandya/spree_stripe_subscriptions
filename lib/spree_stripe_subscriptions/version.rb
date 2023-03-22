module SpreeStripeSubscriptions
  VERSION = '0.0.2'.freeze

  module_function

  # Returns the version of the currently loaded SpreeStripeSubscriptions as a
  # <tt>Gem::Version</tt>.
  def version
    Gem::Version.new VERSION
  end
end
