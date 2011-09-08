require 'anemone'
require 'open-uri'
require 'mongoid'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'thin'

Mongoid.database = Mongo::Connection.new('localhost','27017').db('parse_emails')

@url_array = ["http://www.jcsana.org/", 
	"http://www.dorot.org/dfi",
	 "http://www.jewish-studies.com/Jewish_Studies_at_Universities/USA/",
	"http://www.teachforamerica.org/",
	"http://blogs.rj.org/reform/",
	"http://www.natanet.org/",
	"http://www.jewishcamp.org/",
	"http://www.americorps.gov/"
	]
	 
#@url_array = ["http://www.jcsana.org/",
#             "http://www.jewish-studies.com/Jewish_Studies_at_Universities/USA/"]
class Site
  include Mongoid::Document
  embeds_many :pages
  field :url
  
end

class Page
  include Mongoid::Document
  embedded_in :site
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

def test(url)
  page_search_array = []
  search_field_input = "board staff", "contact us", "about us", "faculty", "directory", "directory:"
  page_search_array << search_field_input.join(" ").split
  page_search_array.flatten!

  site = Site.new(:url => url)
  puts "created #{site.inspect}"
  Anemone.crawl(url, :discard_page_bodies => true) do |anemone|
  #TODO: Save separate sites (how to pop get url from url_array?)
    anemone.on_every_page do |page|
      page_title = page.doc.at('title').inner_html.chomp.downcase rescue nil 
      search_results = page_search_array & page_title.split rescue nil
      puts page_title
      if page.html? && search_results && !search_results.empty? 
        url = url.to_s
        site.pages << Page.new(:url => page.url.to_s, :page_title => page_title)
        site.save
        puts "*************/created******** #{site.pages.last}"
        page.discard_doc!()
        Anemone.crawl(@links.to_s, :discard_page_bodies => true, :depth_limit => 4) do |anemone|
          anemone.on_every_page do |page|
            page_title = page.doc.at('title').inner_html.chomp.downcase rescue nil 
            search_results = page_search_array & page_title.split rescue nil
            puts page_title
            if page.html? && search_results && !search_results.empty? 
              url = url.to_s
              site.pages << Page.new(:url => page.url.to_s, :page_title => page_title)
              site.save
            end
          end
        end
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
  "This is a working url : #{Site.first.url}" 
end

