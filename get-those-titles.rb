require 'anemone'
require 'open-uri'
require 'mongoid'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'thin'

require 'rbing'

#templating
require 'haml'

#simpleworker
#development `ENV['SIMPLE_WORKER_ACCESS_KEY'] = 'YOUR ACCESS KEY'
#             ENV['SIMPLE_WORKER_SECRET_KEY'] = 'YOUR SECRET KEY'
#config simplworker
#SimpleWorker.configure do |config|
#  config.access_key = ENV['SIMPLE_WORKER_ACCESS_KEY']
#  config.secret_key = ENV['SIMPLE_WORKER_SECRET_KEY']
#      # Use the line below if you're using an ActiveRecord database
#  config.database = Rails.configuration.database_configuration[Rails.env]
#end

#or delayed_job
#http://devcenter.heroku.com/articles/delayed-job

#configure :production do
#end

configure :development do
  Mongoid.configure do |config|
      config.master = Mongo::Connection.new.db("get_those_development")
  end
end

Mongoid.load!("config/mongoid.yml")

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
      unless ENV['MONGOLAB_URI']
        anemone.storage = Anemone::Storage.MongoDB
      end
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
  field :display_url
  field :page_title
  field :description
end

class Contact
  include Mongoid::Document
  embedded_in :Page
  field :email
  field :name
  field :content
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
  count = SiteGroup.count
  
  if params[:bing_search]
    bing = RBing.new("66BB92727C57435B4A611134F4C8530A2F62B362")
    bing_results = bing.web(params[:bing_search], :site => params[:urls])
    @bing_results = bing_results
    @site_group = SiteGroup.new( :name => params[:name], 
                                 :urls => params[:urls]
                               )
    for result in bing_results.web.results
      @site_group.pages << Page.new( :page_title => result.title, 
                                      :url => result.url,
                                      :description => result.description,
                                      :display_url => result.displayUrl
                                    )
      @site_group.save
    end
    @@results = @bing_results.web.results
  else
    SiteGroup.get_titles(
      params[:urls], params[:search], params[:site_group_name]
    )
  end

  @site_group = SiteGroup.last 

  if SiteGroup.count == count + 1
    redirect "/site_groups/#{@site_group.id}"
  else
    redirect "/bing_results"
  end
end

post "/site_groups/:id/contacts/update" do
  puts "****************************#{params.inspect}"
  @site_group = SiteGroup.find(params[:id])
  @page = @site_group.pages.find_or_initialize_by( 
                                                  :url => params[:url].to_s
                                                 ) 
  @page.Contact.new( 
                                  :email => params[:email],
                                  :name => params[:name],
                                  :content => params[:content]
                                )
  if @site_group.save
    redirect "/site_groups/#{@site_group.id}"
  end
end
  

#show
get '/bing_results' do
  @results = @@results
  haml :bing_results
end

get '/site_groups/:id' do
  puts "*************************************" 
  p params.inspect
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



