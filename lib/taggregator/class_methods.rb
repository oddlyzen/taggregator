module Taggregator
  module ClassMethods
    def attachment_accessor_module
      @attachment_accessor_module ||= Module.new
    end
    
    # Use the attachement_accessor_module like so:
    # => attachment_accessor_module.module_eval "puts 'hello world from my own module context!'"
  end
end