class Article
  include MongoMapper::Document
  include MongoMapper::Plugins::Taggregator
  
  key :title,   String
  key :body,    String
  key :authors, Array
  
  taggable
  taggable :keywords
  taggable :ads, :separator => ', '
  
end
