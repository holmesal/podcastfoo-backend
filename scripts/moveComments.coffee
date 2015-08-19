firebase = require 'firebase'
_ = require 'lodash'

rootRef = new firebase 'podcast.firebaseio.com'

keys = []

episodes = rootRef.child('episodes')
# episodes.on 'child_added', (snap) ->
# 	commentsRef = snap.ref().child 'comments'
# 	console.info "setting #{commentsRef.toString()} comments to null"
# 	commentsRef.remove()
# 	snap.ref().off()
# 	# snap.ref().child('comments').set null



# 	# uid = snap.ref().key()
# 	# episode = snap.val()
# 	# if episode.comments
# 	# 	console.info "moving #{uid}"
# 	# 	newLocationRef = rootRef.child "commentsByEpisode/#{uid}"
# 	# 	newLocationRef.update episode.comments
# 	#	snap.ref().child('comments').set null
# 	# else
# 	# 	console.info "ignoring #{uid} for lack of comments"

episodes.once 'value', (snap) ->
	console.info "got data!"
	for key, episode of snap.val()
		commentsRef = snap.ref().child "#{key}/comments"
		console.info "setting #{commentsRef.toString()} comments to null"
		commentsRef.remove()