Queue = require 'firebase-queue'
Firebase = require 'firebase'

# options = 
# 	specId: 'propagateActivity'
# 	numWorkers: 1

rootRef = new Firebase 'https://podcast.firebaseio.com'

queueRef = rootRef.child 'queues/activity'
queue = new Queue queueRef, (data, progress, resolve, reject) ->

	
	# For now, we'll just push this item into everyone's stream
	if data.type

		# There's a big shared activity stream that everyone can see
		# This is a hack right now, because I don't want to auto-populate streams on login yet
		sharedStreamRef = rootRef.child 'sharedActivityStream'
		sharedStreamRef.push data

		# Push this into everyone's activity streams
		usersRef = rootRef.child 'users'
		usersRef.once 'value', (snap) ->
			users = snap.val()
			if users
				for uuid, user of users
					streamRef = usersRef.child "#{uuid}/stream"
					streamRef.push data
				resolve()
	else
		reject 'data did not have a type'
		

	# if data.type is 'comment'
	# 	# Go get the author
	# 	authorRef = rootRef.child "users/#{data.authorId}/public"
	# 	authorRef.once 'value', (snap) ->
	# 		author = snap.val()
	# 		if author
	# 			# Go get the podcast
	# 			podcastRef = rootRef.child "podcasts/#{data.podcastId}/itunes"
	# 			podcastRef.once 'value', (snap) ->
	# 				podcast = snap.val()
	# 				if podcast
	# 					# Go get the episode
	# 					# TODO -refactor the episode structure to allow fetching of metadata only
	# 					episodeMetaRef = rootRef.child "episodes/#{data.episodeId}"
	# 					episodeMetaRef.once 'value', (snap) ->
	# 						if episodeMeta

		# Build a stream activity item
		# Push it into the stream of everyone that cares