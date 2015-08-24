Queue = require 'firebase-queue'
Firebase = require 'firebase'

# options = 
# 	specId: 'propagateActivity'
# 	numWorkers: 1

rootRef = new Firebase 'https://podcast.firebaseio.com'

queueRef = rootRef.child 'queues/activity'
queue = new Queue queueRef, (item, progress, resolve, reject) ->

	console.info 'got activity item'
	console.info item

	# Store the item in the global activity list
	activityRef = rootRef.child('activity').push()
	activityRef.set item

	# Store this activity on this user's activity list
	userActivityRef = rootRef.child "activityByUser/#{item.userId}/#{activityRef.key()}"
	userActivityRef.set item.timestamp

	# Fan out this item to all of this user's followers
	followersRef = rootRef.child "users/#{item.userId}/followers"
	followersRef.once 'value', (snap) ->
		followers = snap.val()
		for uuid, something of followers
			userStreamRef = rootRef.child "streamByUser/#{uuid}/#{activityRef.key()}"
			console.info "pushing activity #{activityRef.key()} ---> follower #{uuid}"
			userStreamRef.set item.timestamp
		resolve()

	# if this is a commentLike or a commentReply, notify the owner of the comment
	if item.type is 'commentLike' or item.type is 'commentReply'
		commentRef = rootRef.child "commentsByEpisode/#{item.data.episodeId}/#{item.data.commentId}"
		commentRef.once 'value', (snap) ->
			comment = snap.val()
			unless comment
				console.error "no comment found at #{commentRef.toString()}, requested by comment like #{activityRef.toString()}"
				return false
			# Push this activity into the owner's feed
			# If the owner is following this user, this set will happen twice - I think this is easier than maintaining a list 
			# of users that have been notified and checking it here - planning to break this out into separate queue stages someday
			ownerStreamRef = rootRef.child "streamByUser/#{comment.authorId}/#{activityRef.key()}"
			console.info "pushing activity #{activityRef.key()} ---> owner #{comment.authorId}"
			ownerStreamRef.set item.timestamp