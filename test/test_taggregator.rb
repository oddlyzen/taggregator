require 'helper'

class TestTaggregator < Test::Unit::TestCase
  def setup
    @articles = [
    (@home_and_garden = Article.new(:title => 'Is your refrigerator running? Better catch it',
                                    :body => @lipsum,
                                    :authors => ['Thomas Mann', 'Jim Byrd'])),
    (@golf_digest =     Article.new(:title => 'The Colonial: In Full Swing',
                                    :body => @lipsum,
                                    :authors => ['Rebecca Simmons']))
                ]
    @home_and_garden.keywords = 'luxury household appliances'
    @home_and_garden.ads_array = ['LG Electronics', 'Kenneth Cole']
    @golf_digest.keywords = 'resort vacation luxury'
    @golf_digest.ads_array = ['Calloway', 'Ping']
    save_articles
  end
  
  should "Have keywords context" do
    assert @home_and_garden.keywords
    assert @golf_digest.keywords
  end
  
  should 'parse a string to tags' do
    assert @home_and_garden.keywords_array.count == 3
    assert @golf_digest.keywords_array.count == 3
  end
  
  should 'parse an array for a string representation of the tags' do
    assert @home_and_garden.ads == 'LG Electronics, Kenneth Cole'
    assert @golf_digest.ads     == 'Calloway, Ping'
  end
  
  should 'return all tags for Articles with the tag\'s corresponding weight' do
    tags = Article.tags_with_weight_for :keywords
    assert tags.kind_of? Array
    assert tags[0][0] == 'luxury' && tags[0][1] == 2
  end
  
  should 'return a list of articles if given a tag' do
    articles = Article.keywords_tagged_with 'luxury'
    assert articles.count == 2
  end
  
  should 'find similar articles when given a context and article' do
    article = Article.all.first
    assert (Article.find_similar article, :through => :keywords).count == 2
  end
  
  def teardown
    Article.destroy_all
  end

  private
  def save_articles
    @articles.each{ |article| article.save }
  end
  
end

