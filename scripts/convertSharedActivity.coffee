Firebase = require 'firebase'
sharedActivity = require '/Users/alonso/Downloads/podcast-sharedActivityStream-export.json'

rootRef = new Firebase 'https://podcast.firebaseio.com'

for key, old of sharedActivity
	newItem = 
		type: old.type
		userId: old.authorId
		timestamp: old.timestamp
		data: {}
	newItem.data.podcastId = String(old.podcastId) if old.podcastId
	newItem.data.episodeId = old.episodeId if old.episodeId
	if old.type is 'comment'
		newItem.data.commentId = old.commentId
		# console.info newItem.data.podcastId
	else if old.type is 'commentReply'
		newItem.data.commentId = old.inReplyTo
		newItem.data.replyId = old.commentId
	else if old.type is 'commentLike'
		newItem.data.commentId = old.commentId

	newActivityRef = rootRef.child "activity/#{key}"
	console.info newActivityRef.toString()
	newActivityRef.set newItem
	# Set the activity on this user
	userActivityRef = rootRef.child "activityByUser/#{newItem.userId}/#{key}"
	userActivityRef.set newItem.timestamp

