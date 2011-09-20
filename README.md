# Taggregator

Adds tagging in context (and aggregation of those tags) to your MongoMapper models. Tag weight and distribution methods make it easy to find real-time taxonomical hotspots in datastore. **Taggregator** Uses MongoDB's increment/decrement (`$inc`/`$dec`) to keep real-time counts of individual tags in context with optional type. Based on [Mongoid Taggable With Context](https://github.com/aq1018/mongoid_taggable_with_context "The Progenitor.").

## Basic Usage

**Taggregator** is easy to use. Just include the MongoMapper plugin in your model the normal way and call `taggable`, like so:

    class Article
      include MongoMapper::Document
      plugin  MongoMapper::Plugins::Taggregator

      key :title, String
      key :body, String
      taggable
      taggable :keywords
      taggable :ads, :separator => ','
    end

    a = Article.new

Tags are then set with a string by calling `a.tags = 'space separated tags'`. The tag separator character defaults to the space character, but as you see in the above example, it can be overridden with any character or string of your choice. If we follow the lead of the example, we would set `a.ads` by calling `a.ads = 'comma,separated,tags'`. The call to `taggable` injects an array representation of the model's taggable fields with context, accessible through `a.tags_array`, `a.keywords_array`, and `a.ads_array`. If you have an array of tags (strings) and wish to set the tags array manually, you can (i.e., `a.ads_array = ['xmas', 'shopping', 'books']`). When the string `a.ads` is set, `a.ads_array` is populated with the individual tags. Likewise, setting the tags array populates the string representation of the tag list for that context.

The call to `taggable` mixes in some cool stuff. You can get all articles tags with a call to `Article.tags` and all tags (in the 'keywords' context) with `Article.keywords`. If you would like to get a list of all keywords with the keyword's associated frequency/weight, try this:

    Article.tags_with_weight_for :keywords
    => [["stocks", 4], ["finance", 4], ["banking", 3], ["bonds", 1]]

## Contributing to taggregator
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright © 2011 Mark Coates. See LICENSE.txt for further details.
 