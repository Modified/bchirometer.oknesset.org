$ ->
	show_page=(p)->
		$('section').hide().filter(p).show()
		$('body').toggleClass 'splash',p is '#splash'
		window.scrollTo 0,0
	page_turner=(p)->return ->return show_page p
	page.base '/'
	page 'about',page_turner '#about'
	page 'qna',page_turner '#qna'
	page 'categories',page_turner '#categories'
	page 'agendas:arr',(context)-> # (Apparently, window.location is updated after this handler, so can't get URL hash from it. Page.js provides details in a "context" parameter.)
		# Identify category from URL and fetch details; eg "agendas[92,113,101]" means category includes agendas 92, 113, and 101.
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
	page 'results',->
		# Wipe old final scores.
		final={}
		$ '#parties-list h3 span'
		.text 0
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
				total=scores.reduce (x,y)->x+y
				average=total/scores.length
				$ "#party-#{party}"
				.attr 'score',average
				.find 'h3 span'
				.text average.toFixed 1
			#??? parseInt a,10
		r=$ '#parties-list'
		p=r.children().get()
		p.sort (x,y)->if (parse_score x)<(parse_score y) then 1 else -1
		r.append p
		# Count votes.
		$ '#results>p span'
		.text $('#agendas button.selected:not(.indifferent)').length
		# Only show best result's logo.
		$('#parties-list img').hide().first().show()
		show_page '#results'
	page '*',->show_page '#splash' # Root page (or index.html?), or anything else — take us "home".
	page.start hashbang:yes # Begin listening to location changes.

	# Some routines definitions.
	parse_score=(e)->parseFloat $(e).attr('score') or 0
	hide_nav_to_results=->
		# Hide nav to results (entire footer) if no votes.
		$ '#agendas footer,#categories footer'
		.toggle $('#agendas button.selected:not(.indifferent)').length isnt 0
	disable_category=->
		# Mark category to indicate whether votes done in it.
		voted=$('#agendas button.selected:visible:not(.indifferent)').length #???... find any dis/agree votes on this category/page: $ :visible and .dis/agree
		cid=location.pathname+location.hash # Identify current category.
		$('#categories a[href="'+cid+'"]').toggleClass 'has-votes',voted isnt 0

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
		hide_nav_to_results()
	# Cancel votes button handler.
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
		hide_nav_to_results()
	# Synopsis expansion clicks.
	$ '.synopsis a'
	.click (ev)->
		ev.preventDefault()
		$ @
		.parents '#agendas-list>li'
		.children 'h4,p:not(.synopsis)'
		.toggle()

	# Stuff that needs to be initially hidden. #??? Use new [hidden] attribute? Polyfill it?
	hide_nav_to_results()
