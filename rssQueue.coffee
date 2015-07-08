Queue = require 'firebase-queue'
Firebase = require 'firebase'
request = require 'request'
feedparser = require 'feedparser'
cl = console.log
crypto = require 'crypto'
moment = require 'moment'
slugify = require 'slug'
lodash = require 'lodash'

rootRef = new Firebase 'https://podcast.firebaseio.com'

queueRef = rootRef.child 'queues/rss'
queue = new Queue queueRef, (itunes, progress, resolve, reject) ->
	# cl "fetching feed for #{itunes.collectionName}"
	# cl itunes
	name = itunes.collectionName.toLowerCase().replace(/podcast/g, '')
	slugged = slugify(name)
	slug = slugged.split('-').slice(0,4).join('-')
	console.log(slug)

	# we use the itunes collection id as a unique identifier
	podId = itunes.collectionId

	# update podcast data (will store if we don't have it)
	podcastRef = rootRef.child "podcasts/#{podId}"
	podcastRef.update
		itunes: itunes

	# update the slugs
	checkAndStoreSlugs slug, podId, 0, podcastRef

	# go look for new episodes
	findNewEpisodes podId

	# TODO - break this out into chained queue items
	resolve()

episodeQueueRef = rootRef.child 'queues/episodeQueue'
episodeQueue = new Queue episodeQueueRef, (data, progress, resolve, reject) ->
	if data.podcastId
		findNewEpisodes data.podcastId
		resolve()	
	else
		reject()

checkAndStoreSlugs = (slug, podcastId, attempts, podcastRef) ->
	# If this isn't the first run, try appending attempts to slug
	if attempts > 0
		desiredSlug = "#{slug}-#{attempts}"
	else
		desiredSlug = slug
	# console.log "desired: #{desiredSlug}"
	# check if a podcast already lives here
	existingRef = rootRef.child "shortlinks/#{desiredSlug}"
	existingRef.once 'value', (snap) ->
		existingPodcastId = snap.val()?.uuid
		# If a podcast already exists, here, add an integer to the end and try again
		if existingPodcastId and existingPodcastId isnt podcastId
			# console.log 'exists!'
			checkAndStoreSlugs slug, podcastId, attempts + 1, podcastRef
		# If no podcast exists here, then we're good! Update the slugs
		else
			podcastRef.child('slug').set desiredSlug
			existingRef.set 
				type: 'podcast'
				uuid: podcastId

findNewEpisodes = (podId) ->
	console.log "finding new episodes for #{podId}"
	podItunesRef = rootRef.child "podcasts/#{podId}/itunes"
	podItunesRef.once 'value', (snap) ->
		itunes = snap.val()
		req = request itunes.feedUrl
		feed = new feedparser
			addMeta: false
		req.on 'error', (err) ->
			console.log "error fetching feed for #{itunes.collectionName}", err
		req.on 'response', (res) ->
			@emit 'error', new Error 'bad status code' unless res.statusCode is 200
			@pipe feed
		feed.on 'error', (err) ->
			console.log "error parsing feed for #{itunes.collectionName}", err
		feed.on 'readable', ->
			while item = @.read()
				# hash the guid
				episode = 
					hash: crypto.createHash('md5').update(item.guid).digest 'hex'
					timestamp: moment(item.pubdate).valueOf()
					podcastId: podId
				episode.title = item.title if item.title
				episode.description = item.description if item.description
				episode.summary = item.summary if item.summary
				episode.link = item.link if item.link
				episode.origlink = item.origlink if item.origlink
				episode.permalink = item.permalink if item.permalink
				episode.date = item.date if item.date
				episode.pubdate = item.pubdate if item.pubdate
				episode.author = item.author if item.author
				episode.guid = item.guid if item.guid
				episode.image = item.image if item.image
				episode.enclosures = item.enclosures if item.enclosures
				for enclosure in item.enclosures
					if enclosure.type = 'audio/mpeg'
						episode.audio = enclosure

				slug = slugify(episode.title).toLowerCase()
				episode.slug = slug

				# Store a reference to this episode on the podcast
				compactEpisodesRef = rootRef.child "podcasts/#{podId}/episodes/#{episode.hash}"
				compactEpisodesRef.set
					episodeId: episode.hash
					timestamp: episode.timestamp
					slug: slug

				# Store this episode in the episodes list
				episodeRef = rootRef.child "episodes/#{episode.hash}"
				episodeRef.update episode