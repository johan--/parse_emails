require 'anemone'
require 'open-uri'

url_array = ["http://www.jcsana.org/", 
	"http://www.dorot.org/dfi",
	 "http://www.jewish-studies.com/Jewish_Studies_at_Universities/USA/",
	 "http://www.google.com/search?q=Jewish+Studies+Departments&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a#sclient=psy&hl=en&client=firefox-a&hs=Le0&rls=org.mozilla:en-US%3Aofficial&source=hp&q=*+site:+jewishstudies*.edu&pbx=1&oq=*+site:+jewishstudies*.edu&aq=f&aqi=&aql=1&gs_sm=e&gs_upl=578l578l3l965l1l1l0l0l0l0l229l431l2-2l2l0&fp=1&biw=1277&bih=844&bav=on.2,or.r_gc.r_pw.r_cp.&cad=b",
	"http://www.google.com/search?q=year+programs+in+israel&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a#sclient=psy&hl=en&client=firefox-a&rls=org.mozilla:en-US%3Aofficial&source=hp&q=year+in+israel+site:*.edu&pbx=1&oq=year+in+israel+site:*.edu&aq=f&aqi=&aql=1&gs_sm=e&gs_upl=197788l204318l0l204735l26l20l5l0l0l3l368l4025l0.2.9.4l15l0&fp=1&biw=1277&bih=844&bav=on.2,or.r_gc.r_pw.r_cp.&cad=b",
	"http://www.teachforamerica.org/",
	"http://blogs.rj.org/reform/",
	"http://www.natanet.org/",
	"http://www.jewishcamp.org/",
	"http://www.americorps.gov/"
	]


open_urls(url_array)
url_array.to_a
@url_array = url_array
