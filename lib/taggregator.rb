module MongoMapper
  module Plugins
    autoload :Taggregator, 'taggregator'
  end
end

module Taggregator
  extend ActiveSupport::Concern
  
  included do
    class_inheritable_reader :taggable_with_context_options
    write_inheritable_attribute(:taggable_with_context_options, {})
    delegate "convert_string_to_array",     :to => 'self.class'
    delegate "convert_array_to_string",     :to => 'self.class'
    delegate "get_tag_separator_for",       :to => 'self.class'
    delegate "tag_contexts",                :to => 'self.class'
    delegate "tag_options_for",             :to => 'self.class'
    set_callback :create,   :after, :increment_tags_agregation
    set_callback :save,     :after, :update_tags_aggregation
    set_callback :destroy,  :after, :decrement_tags_aggregation
  end
  
  module ClassMethods
    # Macro to declare a document class as taggable, specify field name
    # for tags, and set options for tagging behavior.
    #
    # @example Define a taggable document.
    #
    #   class Article
    #     include Mongoid::Document
    #     include Mongoid::Taggable
    #     taggable :keywords, :separator => ' ', :aggregation => true, :default_type => "seo"
    #   end
    #
    # @param [ Symbol ] field The name of the field for tags.
    # @param [ Hash ] options Options for taggable behavior.
    #
    # @option options [ String ] :separator The tag separator to
    #   convert from; defaults to ','
    # @option options [ true, false ] :aggregation Whether or not to
    #   aggregate counts of tags within the document collection using
    #   map/reduce; defaults to false
    # @option options [ String ] :default_type The default type of the tag.
    #   Each tag can optionally have a tag type. The default type is nil
    def taggable(*args)
      # init variables
      options = args.extract_options!
      tags_field = (args.blank? ? :tags : args.shift).to_sym
      options.reverse_merge!(
        :separator => ' ',
        :array_field => "#{tags_field}_array".to_sym
      )
      tags_array_field = options[:array_field]
      
      # register / update settings
      class_options = taggable_with_context_options || {}
      class_options[tags_field] = options
      write_inheritable_attribute(:taggable_with_context_options, class_options)
      
      # setup fields & indexes
      field tags_field, :default => ""
      field tags_array_field, :type => Array, :default => []
      index tags_array_field      
      
      # singleton methods
      class_eval <<-END
        class << self
          def #{tags_field}
            tags_for(:"#{tags_field}")
          end
      
          def #{tags_field}_with_weight
            tags_with_weight_for(:"#{tags_field}")
          end
      
          def #{tags_field}_separator
            get_tag_separator_for(:"#{tags_field}")
          end
          
          def #{tags_field}_separator=(value)
            set_tag_separator_for(:"#{tags_field}", value)
          end
                  
          def #{tags_field}_tagged_with(tags)
            tagged_with(:"#{tags_field}", tags)
          end
        end
      END
      
      # instance methods
      class_eval <<-END
        def #{tags_field}=(s)
          super
          write_attribute(:#{tags_array_field}, convert_string_to_array(s, get_tag_separator_for(:"#{tags_field}")))
        end
        
        def #{tags_array_field}=(a)
          super
          write_attribute(:#{tags_field}, convert_array_to_string(a, get_tag_separator_for(:"#{tags_field}")))
        end
      END
    end
    
    def tag_contexts
      taggable_with_context_options.keys
    end
    
    def tag_options_for(context)
      taggable_with_context_options[context]
    end

    def tags_for(context, conditions={})
      raise AggregationStrategyMissing
    end
    
      # Collection name for storing results of tag count aggregation
      def aggregation_collection_for(context)
        "#{collection_name}_#{context}_aggregation"
      end
      
      def tags_for(context, conditions={})
        conditions = {:sort => '_id'}.merge(conditions)
        db.collection(aggregation_collection_for(context)).find({:value => {"$gt" => 0 }}, conditions).to_a.map{ |t| t["_id"] }
      end

      # retrieve the list of tag with weight(count), this is useful for
      # creating tag clouds
      def tags_with_weight_for(context, conditions={})
        conditions = {:sort => '_id'}.merge(conditions)
        db.collection(aggregation_collection_for(context)).find({:value => {"$gt" => 0 }}, conditions).to_a.map{ |t| [t["_id"], t["value"]] }
      end
    end
    
    private
    def need_update_tags_aggregation?
      !changed_contexts.empty?
    end

    def changed_contexts
      tag_contexts & previous_changes.keys.map(&:to_sym)
    end
    
    def increment_tags_agregation
      # if document is created by using MyDocument.new
      # and attributes are individually assigned
      # #previous_changes won't be empty and aggregation
      # is updated in after_save, so we simply skip it.
      return unless previous_changes.empty?

      # if the document is created by using MyDocument.create(:tags => "tag1 tag2")
      # #previous_changes hash is empty and we have to update aggregation here
      tag_contexts.each do |context|
        coll = self.class.db.collection(self.class.aggregation_collection_for(context))
        field_name = self.class.tag_options_for(context)[:array_field]
        tags = self.send field_name || []
        tags.each do |t|
          coll.update({:_id => t}, {'$inc' => {:value => 1}}, :upsert => true)
        end
      end
    end

    def decrement_tags_aggregation
      tag_contexts.each do |context|
        coll = self.class.db.collection(self.class.aggregation_collection_for(context))
        field_name = self.class.tag_options_for(context)[:array_field]
        tags = self.send field_name || []
        tags.each do |t|
          coll.update({:_id => t}, {'$inc' => {:value => -1}}, :upsert => true)
        end
      end
    end

    def update_tags_aggregation
      return unless need_update_tags_aggregation?

      changed_contexts.each do |context|
        coll = self.class.db.collection(self.class.aggregation_collection_for(context))
        field_name = self.class.tag_options_for(context)[:array_field]        
        old_tags, new_tags = previous_changes["#{field_name}"]
        old_tags ||= []
        new_tags ||= []
        unchanged_tags = old_tags & new_tags
        tags_removed = old_tags - unchanged_tags
        tags_added = new_tags - unchanged_tags

        tags_removed.each do |t|
          coll.update({:_id => t}, {'$inc' => {:value => -1}}, :upsert => true)
        end

        tags_added.each do |t|
          coll.update({:_id => t}, {'$inc' => {:value => 1}}, :upsert => true)
        end
      end
  
    def get_tag_separator_for(context)
      taggable_with_context_options[context][:separator]
    end

    def set_tag_separator_for(context, value)
      taggable_with_context_options[context][:separator] = value.nil? ? " " : value.to_s
    end
            
    # Find documents tagged with all tags passed as a parameter, given
    # as an Array or a String using the configured separator.
    #
    # @example Find matching all tags in an Array.
    #   Article.tagged_with(['ruby', 'mongodb'])
    # @example Find matching all tags in a String.
    #   Article.tagged_with('ruby, mongodb')
    #
    # @param [ String ] :field The field name of the tag.
    # @param [ Array<String, Symbol>, String ] :tags Tags to match.
    # @return [ Criteria ] A new criteria.
    def tagged_with(context, tags)
      tags = convert_string_to_array(tags, get_tag_separator_for(context)) if tags.is_a? String
      array_field = tag_options_for(context)[:array_field]
      all_in(array_field => tags)
    end
  
    # Helper method to convert a String to an Array based on the
    # configured tag separator.
    def convert_string_to_array(str = "", seperator = " ")
      str.split(seperator).map(&:strip).uniq.compact
    end
  
    def convert_array_to_string(ary = [], seperator = " ")
      ary.uniq.compact.join(seperator)
    end
  end

end