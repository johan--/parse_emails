require 'anemone'
require 'open-uri'
require 'mongoid'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'thin'

#configure do
#   Mongoid.configure do |config|
#    name = "parse_emails"
#    host = "localhost"
#    config.database = Mongo::Connection.new.db(name)
#  end
#end

Mongoid.database = Mongo::Connection.new('localhost','27017').db('parse_emails')
#Mongoid.configure do |config|
#  config.master = Mongo::Connection.new.db("parse_emails")
#end

#@url_array = ["http://www.jcsana.org/", 
#	"http://www.dorot.org/dfi",
#	 "http://www.jewish-studies.com/Jewish_Studies_at_Universities/USA/",
#	 "http://www.google.com/search?q=Jewish+Studies+Departments&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a#sclient=psy&hl=en&client=firefox-a&hs=Le0&rls=org.mozilla:en-US%3Aofficial&source=hp&q=*+site:+jewishstudies*.edu&pbx=1&oq=*+site:+jewishstudies*.edu&aq=f&aqi=&aql=1&gs_sm=e&gs_upl=578l578l3l965l1l1l0l0l0l0l229l431l2-2l2l0&fp=1&biw=1277&bih=844&bav=on.2,or.r_gc.r_pw.r_cp.&cad=b",
#	"http://www.google.com/search?q=year+programs+in+israel&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a#sclient=psy&hl=en&client=firefox-a&rls=org.mozilla:en-US%3Aofficial&source=hp&q=year+in+israel+site:*.edu&pbx=1&oq=year+in+israel+site:*.edu&aq=f&aqi=&aql=1&gs_sm=e&gs_upl=197788l204318l0l204735l26l20l5l0l0l3l368l4025l0.2.9.4l15l0&fp=1&biw=1277&bih=844&bav=on.2,or.r_gc.r_pw.r_cp.&cad=b",
#	"http://www.teachforamerica.org/",
#	"http://blogs.rj.org/reform/",
#	"http://www.natanet.org/",
#	"http://www.jewishcamp.org/",
#	"http://www.americorps.gov/"
#	]
	 
@url_array = ["http://www.jcsana.org/",
             "http://www.jewish-studies.com/Jewish_Studies_at_Universities/USA/"]
class Site
  include Mongoid::Document
  embeds_many :pages
  field :url
  def self.get_url_list(url_array)
  url_array.each do |url|
    site = Site.new(:url => url)
    Anemone.crawl(url) do |anemone|
      anemone.on_every_page do |page|
        page_title = page.doc.at_css('title').inner_html rescue nil
        unless page_title == "Board & Staff"#TODO matches "contact" "board" "staff" "faculty"
          page_title = nil
        end
        #page.doc.xpath('//*[starts-with(*, "President")]').each do |node|
        #  contacts = node.parent.text
        #end
        if page_title
          site.pages << Page.new(url: page.url.to_s, page_title: page_title )
        end
        puts site.pages.each { |p| puts "found url => \"#{p.url}\"";
                                   puts "found title => \"#{p.title}\"";
                                   puts "found contacts => \"#{p.contacts}\""; }
      end
    end
    site.save
  end 
 # def self.search_text
 #   node.xpath('.//title[regex(., "\w+")]', Class.new {
 #     def regex node_set, regex
 #       node_set.find_all { |node| node['some_attribute'] =~ /#{regex}/ }
 #     end
 #   }.new)
 # end
end

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

get '/' do
  "This is a working url : #{Site.first.url}" 
end

