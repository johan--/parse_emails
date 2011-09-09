require 'anemone'
require 'open-uri'
require 'mongoid'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'thin'

#templating
require 'haml'

Mongoid.database = Mongo::Connection.new('localhost','27017').db('parse_emails')


@urls = ["http://www.jcsana.org/", 
	"http://www.dorot.org/dfi",
	 "http://www.jewish-studies.com/Jewish_Studies_at_Universities/USA/",
	"http://www.teachforamerica.org/",
	"http://blogs.rj.org/reform/",
	"http://www.natanet.org/",
	"http://www.jewishcamp.org/",
	"http://www.americorps.gov/"
	]
	 
class SiteGroup
  include Mongoid::Document
  embeds_many :pages
  field :urls
  field :name
  
end

class Page
  include Mongoid::Document
  embedded_in :site_group
  embeds_many :contacts
  field :url
  field :page_title
end

class Contact
  include Mongoid::Document
  embedded_in :Page
  field :email
  field :name
  field :content
  field :content_snippet
end

def test(urls)
  page_search_array = []
  search_field_input = "board staff", "contact us", "about us", "faculty", "directory", "directory:"
  page_search_array << search_field_input.join(" ").split
  page_search_array.flatten!

  site_group = SiteGroup.new(:urls => urls)
  puts "created #{site_group.urls}"
  Anemone.crawl(urls, :discard_page_bodies => true) do |anemone|
    anemone.storage = Anemone::Storage.MongoDB
    anemone.on_every_page do |page|
      page_title = page.doc.at('title').inner_html.chomp.downcase rescue nil 
      search_results = page_search_array & page_title.split rescue nil
      puts page_title
      if page.html? && search_results && !search_results.empty? 
        url = url.to_s
        site_group.pages << Page.new(:url => page.url.to_s, :page_title => page_title)
        site_group.save
        puts "*************/created******** #{site_group.pages.last}"
        page.discard_doc!()
        page_title = nil; body = nil; search_results = nil; 
        page = nil; email = nil; name = nil; content = nil; content_snippet = nil; 
      end
    end
  end
end

 #page.doc.xpath('//*[starts-with(*, "President")]').each do |node|
 #  contacts = node.parent.text
 #end

 # def self.search_text
 #   node.xpath('.//title[regex(., "\w+")]', Class.new {
 #     def regex node_set, regex
 #       node_set.find_all { |node| node['some_attribute'] =~ /#{regex}/ }
 #     end
 #   }.new)
 # end

get '/' do
  haml :index
end

