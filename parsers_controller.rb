module TEST
  class ParsersController < TEST::ApplicationController
  
  	before_action :authenticate_user!, only: [:create]

  	def create

		ptt_url = "https://www.ptt.cc"
		board_FoodandDrink_url = "/cls/3733" # board Food and Drink

		# issue
		# Major categories
		ptt_issue = Nokogiri::HTML(open(URI.join(ptt_url,board_FoodandDrink_url), :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
		ptt_issue_href = ptt_issue.css("div.b-ent a")

		# Major issue
		ptt_major_issue = ptt_issue.css("//div[class='board-title']")
		# fast food
		# ptt_major_issue = ptt_major_issue[10].text
		# food
		# ptt_major_issue = ptt_major_issue[11].text
		# fruit 
		# ptt_major_issue = ptt_major_issue[12].text
		# snacks
		ptt_major_issue = ptt_major_issue[16].text


		#fastfood board url
		# minor_board_url = ptt_issue_href[10].attr('href') # index page
		# # food board url
		# minor_board_url = ptt_issue_href[11].attr('href') # index page
		# fruit 
		# minor_board_url = ptt_issue_href[12].attr('href') # index page
		# snacks
		minor_board_url = ptt_issue_href[16].attr('href') # index page


		# 一個頁面 20 筆文章
		ptt_data = []
		ptt_data_count=0
		ptt_data_limit=200

		# catch 50 data
		while ptt_data_count < ptt_data_limit

			# minor_board_topic	ex: KFC....
			minor_board_topic = Nokogiri::HTML(open(URI.join(ptt_url,minor_board_url), :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
			minor_board_topic_href = minor_board_topic.css("div.r-ent a")

			article_upper_bound = minor_board_topic_href.count

			# major article
			for article_count in 0..(article_upper_bound-1)
			
				ptt_article = Nokogiri::HTML(open(URI.join(ptt_url,minor_board_topic_href[article_count].attr('href')), :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))

				
				# 100 word
				# if ptt_article.css("//div[@id='main-content']/text()").to_s.length > 100
				# 200 word
				# if ptt_article.css("//div[@id='main-content']/text()").to_s.length < 100 || ptt_article.css("//div[@id='main-content']/text()").to_s.length > 200
				# 300 word
				# if ptt_article.css("//div[@id='main-content']/text()").to_s.length < 200 || ptt_article.css("//div[@id='main-content']/text()").to_s.length > 300
				# 400 word
				# if ptt_article.css("//div[@id='main-content']/text()").to_s.length < 300 || ptt_article.css("//div[@id='main-content']/text()").to_s.length > 400
				#   next
				# end

				# author and title
				temp = ptt_article.css(".article-meta-value")
				next if temp.empty?
				if temp[0].text == "[問題] 大麥克生菜?" then next end
				author = temp[0].text	# author
				title  = temp[2].text	# title

				# 文章內容
				content = ptt_article.css("//div[@id='main-content']/text()")

				# 回文者
				replier = []
				temp = ptt_article.css(".push-userid")
				temp.each do |t|
					 replier << t.text
				end

				# 回文內容
				temp = ptt_article.css(".push-content")
				comment = temp.text.gsub(": ","\n")

				greate=0 # 讚
				bad=0	 # 噓
				temp = ptt_article.css(".push-tag")
				temp.each do |t|
					if t.text == "推 "
						greate+=1
					elsif t.text == "噓 "
						bad+=1
					end
				end

				ptt_data[ptt_data_count] = { author: author, title: title, content: content, replier: replier, comment: comment, greate: greate, bad: bad}
				ptt_data_count+=1;
	 
			end	# for-loop end

			previous_page =  Nokogiri::HTML(open(URI.join(ptt_url,minor_board_url), :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
			previous_page_href = URI.join( ptt_url, previous_page.css(".wide")[1].attr('href') )
			minor_board_url =  previous_page_href

		end # while-loop end

		issue_id=0
		binding.pry
		for i in 0..(ptt_data.count-1)
			if i==0

				@issue = Issue.new
				@article = Article.new(author: current_user.email)
				# create
				Issue.transaction do

		        	@issue = Issue.new(title: ptt_major_issue)

					@article = current_user.articles.new(author: current_user.email, title: ptt_data[i][:title], content: ptt_data[i][:content])

					@issue.save!

			        @article.issue_id = @issue.id

			        issue_id = @issue.id

		    	    @article.save!
				end
			else
				# create
				@article = current_user.articles.new(issue_id: issue_id, author: current_user.email, title: ptt_data[i][:title], content: ptt_data[i][:content])
				@article.save!
			end			
		end

  		redirect_to test.root_url

  	end
  end
end
