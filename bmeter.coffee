$ ->
	# Some local routines.
	parse_score=(e)->parseFloat $(e).data().score or 0
	update_link_results=->
		# Hide/disable nav to results (entire footer?) if no votes.
		$ '.to-results'
		.toggleClass 'disabled',$('#agendas button.selected:not(.indifferent)').length is 0
		# Modify URL link to results page to contain votes so can bookmark, share…
		$ '.to-results'
		.attr 'href','#!results'+votes_serialize()
	disable_category=->
		# Mark category to indicate whether votes done in it.
		#???... Don't use visible, parse ID instead, so results URL works too.
		voted=$('#agendas button.selected:visible:not(.indifferent)').length # Find any dis/agree votes in current category.
		$("#categories a[href=\"#{location.hash}\"]").toggleClass 'has-votes',voted isnt 0
	votes_serialize=->
		vs={}
		$ '#agendas button.selected:not(.indifferent)'
		.each ->
			b=$ @
			aid=b.parents('li').attr('id').slice 'agenda-'.length
			vs[aid]=if b.hasClass 'agree' then 'y' else 'n'
		JSON.stringify vs

	# SPA with virtual pages.
	show_page=(p)->
		$('section').hide().filter(p).show()
		$('body').attr 'data-page',p # Mark current page on body so can style with CSS selectors.
		window.scrollTo 0,0
	page_turner=(p)->return ->return show_page p # Factory.
	# Routing.
	page.base '/'
	page 'about',page_turner '#about'
	page 'qna',page_turner '#qna'
	page 'categories',page_turner '#categories'
	page 'agendas:cid',(context)->
		# Identify category from URL and fetch details; eg "#!agendas[92,113,101]" means category includes agendas 92, 113, and 101.
		# (Apparently, window.location is updated after this handler, so can't get URL hash from it. Page.js provides details in a "context" parameter.)
		cid=context.path.slice 'agendas'.length
		ids=$.parseJSON cid
		c=$ "#categories-list a[href=\"#!#{context.path}\"]"
		icon=c.attr('class').match(/fa-\S+/)[0]
		# Set heading to chosen category.
		$ '#agendas h2'
		.empty()
		.text c.text()
		.prepend $ "<i class=\"fa #{icon}\"></i>"
		# Filter agendas list for selected category.
		$ '#agendas-list li'
		.each ->
			a=$ @ # Wrap DOM node with jQuery? Yeah, easier to work with.
			aid=a.attr 'id' # Each li has an id attribute in the form "agenda-113".
			.slice 'agenda-'.length
			a.toggle parseInt(aid,10) in ids
		show_page '#agendas'
	page 'results:votes?',(context)-> # Nav to results page.
		# Guard against missing votes: redirect home.
		unless context.params.votes then page '/'
		# Extract votes from URL. Set voting buttons.
		try
			votes=$.parseJSON context.params.votes
		catch _
			return page '/'
		for own agenda,vote of votes
			do (agenda,vote)->
				v=if vote is 'y' then 'agree' else 'disagree'
				$ "#agenda-#{agenda} button.#{v}"
				.addClass 'selected'
				.siblings().removeClass 'selected'
		# Guard against invalid votes.
		unless $('#agendas button.selected:not(.indifferent)').length isnt 0 then page '/'
		#???... Mark category buttons too!
		# Wipe old final scores: reset to zeroes.
		final={}
		$ '#parties-list li'
		.data 'score',0
		.find 'h3 img'
		.attr 'src','meter/zero.png'
		.siblings 'span'
		.text '—'
		# Recalculate final scores.
		$ '#agendas-list>li'
		.each ->
			a=$ @
			# Voted?
			if a.children('button.selected:not(.indifferent)').length isnt 0
				dis_agree=switch
					when a.children('button.selected.agree').length isnt 0 then 1.0
					else -1.0
				ps=$.parseJSON a.attr 'data-parties-scores'
				for own party,score of ps
					do (party,score)->
						final[party] or=[] # Initialize to empty array, once.
						final[party].push score*dis_agree # Add score.
		# Sort parties by score.
		for own party,scores of final
			do (party,scores)->
				sum=scores.reduce (x,y)->x+y
				average=sum/scores.length
				#??? meter=switch
				$ "#party-#{party}"
				.data 'score',average
				.find 'h3 img'
				.attr 'src','meter/zero.png'
				.siblings 'span'
				.text average.toFixed 1
				.attr 'title','ממוצע של \u202d'+scores # Just for debugging?
		r=$ '#parties-list'
		p=r.children().get()
		.sort (x,y)->if (parse_score x)<(parse_score y) then 1 else -1
		r.append p
		# Count votes.
		$ '#results>p span'
		.text $('#agendas button.selected:not(.indifferent)').length
		# Only show best result's logo.
		$('#parties-list li>img').hide().first().show()
		show_page '#results'
	page '*',->show_page '#splash' # Root page, or anything else — take us "home".
	page.start hashbang:yes # Begin listening to location changes.

	# Voting buttons handler.
	$ '#agendas-list'
	.on 'click','button',(ev)->
		b=$ ev.target # Which button?
		v=switch # Vote?
			when b.hasClass 'agree' then 1
			when b.hasClass 'indifferent' then 0
			when b.hasClass 'disagree' then -1
		b.addClass 'selected'
		.siblings().removeClass 'selected'
		# Update stuff depending on number of votes.
		disable_category()
		update_link_results()
	###??? # Cancel votes button handler. #??? Removed.
	$ '#cancel'
	.click (ev)->
		$ '#agendas button.selected:visible:not(.indifferent)'
		.each ->
			$ @
			.removeClass 'selected'
			.siblings '.indifferent'
			.addClass 'selected'
		# Update stuff depending on number of votes.
		disable_category()
		update_link_results()
	###
	# Disable results button.
	$ '.to-results'
	.click (ev)->
		if $(@).hasClass 'disabled' then ev.preventDefault()
	# Expansion clicks.
	$ 'a.expand'
	.click (ev)->
		ev.preventDefault() # Not a real (nav) link.
		id=$ ev.target
		.attr 'href'
		#??? .next 'span'
		$ id
		.toggle()
	###??? Replace this with 'expand' handler.
	$ '.synopsis a'
	.click (ev)->
		ev.preventDefault()
		$ @
		.parents '#agendas-list>li'
		.children 'h4,p:not(.synopsis)'
		.toggle()
	###
	# Next category.
	$ '#next'
	.click (ev)->
		ev.preventDefault() # Not a real (nav) link.
		# Find current category, and decide which next: from last cycle back to first.
		n=$("#categories-list a[href=\"#{location.hash}\"]").parent().next().find 'a'
		if n.length is 0 then n=$("#categories-list a").first()
		page n.attr 'href'

	# Dynamically generated content.
	$ 'button.disagree'
	.after $ '<p><small>(* לחצי "לא אכפת" כדי לבטל הצבעה.)</small></p>'

	# Stuff that needs to be initially hidden. #??? Use new [hidden] attribute? Polyfill it?
	update_link_results()

	#??? Backdoors!
	$ '.bg-toggle'
	.click (ev)->
		ev.preventDefault() # Not a real (nav) link.
		$ 'body'
		.toggleClass 'bgi'
