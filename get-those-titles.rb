require 'anemone'
require 'open-uri'
require 'mongoid'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'thin'

#templating
require 'haml'

#configure :production do
#  uri  = URI.parse(ENV['MONGOLAB_URI'])
#  Mongoid.database = Mongo::Connection.from_uri(ENV['MONGOLAB_URI']).db(uri.path.gsub(/^\//, ''))
#end
#puts URI.parse(ENV['MONGOLAB_URI'])

configure :production do
  Mongoid::Config::Database.new( false, "uri" => {  "ENV['MONGOLAB_URI']"  })
  #uri  = URI.parse(ENV['MONGOLAB_URI'])
  #conn = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
  #db = conn.db(uri.path.gsub(/^\//, ''))
  #Mongoid.database = db
end

configure :development do
  #Mongoid.database = Mongo::Connection.new('localhost','27017').db('parse_emails')
end
	 
class SiteGroup
  include Mongoid::Document
  embeds_many :pages
  field :urls
  field :name

  def self.get_titles( urls, 
                       search = "board\r\ncontact\r\nabout\r\nfaculty\r\ndirectory\r\ndirectory:\r\n",
                       site_group_name )
    puts "************#{search}****************"
    urls = CGI::unescape(urls).split("\r\n") 
    if urls.count == 1 
      urls = urls.pop
    end
    page_search_array = []
    regex = /(?:\r\n|\s)/
    search = search.chomp.split(regex) 
    puts "************This is the search array************\r\n#{search}"
    page_search_array << search
    page_search_array.flatten!

    @site_group = SiteGroup.new(:urls => urls, :name => site_group_name )
    Anemone.crawl(urls, :discard_page_bodies => true, :dept_limit => 4) do |anemone|
      anemone.storage = Anemone::Storage.MongoDB
      #TODO idea = find siteindex first, then find link with params[:search]
      anemone.on_every_page do |page|
        page_title = page.doc.at('title').inner_html.chomp.downcase rescue nil 
        search_results = page_search_array & page_title.split rescue nil
        puts page_title
        if page.html? && search_results && !search_results.empty? 
          url = url.to_s
          @site_group.pages << Page.new(:url => page.url.to_s, :page_title => page_title)
          @site_group.save
          puts "*************/created******** #{@site_group.pages.last}"
          page.discard_doc!()
          page_title = nil; body = nil; search_results = nil; 
          page = nil; email = nil; name = nil; content = nil; content_snippet = nil; 
        end
      end
    end
  end
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

#new
get '/' do
 before do
    p params[:urls]
  end
  haml :index
 
end

#create
post '/' do
  puts "********************************************"
  puts ENV['MONGOLAB_URI']
  puts "*********************************************"

  count = SiteGroup.count
  SiteGroup.get_titles(params[:urls], params[:search], params[:site_group_name])
  @site_group = SiteGroup.last 
  if SiteGroup.count == count + 1
    redirect "/#{@site_group.id.to_s}"
  else
    redirect '/'
  end
end

#show
get '/:id' do
  @site_group = SiteGroup.find(params[:id])
  haml :show
end

#test
get '/test/staff.html' do
  haml '%title staff', :layout => false
end
get '/test/faculty.html' do
  haml '%title faculty', :layout => fals
end
get '/test/other.html' do
  haml '%title other', :layout => false
end
post '/google_search' do
  cx = "003190795339691424418:y8ddzdespag" 
  lr = "lang_en"
  q = params[:google_search]
  get "http://www.googleapis.com/customsearch/v1?key=#{cx}&q=#{q}"
end
#http://www.googleapis.com/customsearch/v1?key=130693690549&cx=003190795339691424418:y8ddzdespag&q=site:huc.edu
