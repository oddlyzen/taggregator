# require 'yadda/yadda'

module Taggregator
  extend ActiveSupport::Concern
  
  included do
  end
  
  # the basics, from the current plugin
  
private
  # don't look
end

require 'taggregator/class_methods'
require 'taggregator/instance_methods'
# require 'more/stuff'