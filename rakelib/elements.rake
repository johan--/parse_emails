desc "fetch page elements"
task :fetch_elements, [:root, :iterations, :relative] => :environment do |t, args|
  require 'anemone' 
  require 'nokogiri'
  require 'open-uri'
  args.with_defaults(:root => "Insert domain root use 'rake fetch_elements[root, iterations, [true][false]' where 
                                true is a relative url and false is a static url",
                     :iterations => nil, :relative => false)
    
      css_selection = '.max table td:nth-child(2)'
      root = args.root
     # Handle iterations arg 
      iterations = args.iterations
      Anemone.crawl(root, :discard_page_bodies => true) do |anemone|
        number_its = 0 
        begin
        anemone.on_every_page do |page|
          if page.doc ? page.doc.html? : false
            if args.relative  # Handle site path arg
              url = page.path.to_s
            else
              url = page.url.to_s
            end
            Page.fetch_elements url  rescue nil
          #  title = page.doc.at('title').inner_html rescue nil
          #  if page.doc
          #    body = page.doc.css(css_selection)
          #  else
          #    body = nil
          #  end
          #  unless body.nil?
          #    page.update_attributes(:title => title)
          #    page = Page.find_or_create_by(:url => url)
          #    i = 0 #increment page_position 
          #    body.children.each do |element| #TODO add self = content ?use .traverse ?
          #      if !element.comment? || !element.inner_html.blank?
          #        content = element.inner_html
          #        page.elements.find_or_create_by(:content => content, :page_position => i)
          #        i += 1
          #      end
          #    end
              number_its += 1
              puts number_its
          #    puts number_its
          #  end
            #clear instance variables
            url = nil
            title = nil
            body = nil
            page = nil
            content = nil
            unless iterations.nil?
              if iterations > number_its
                raise "Finished #{iterations} iterations"
              end
            end
          end # end 'if doc.html?'
        end 
        end #begin block
      end
  end
