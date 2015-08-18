firebase = require 'firebase'
_ = require 'lodash'

rootRef = new firebase 'podcast.firebaseio.com'

users = rootRef.child 'users'
users.on 'child_added', (snap) ->
	uid = snap.ref().key()

	_.forEach snap.val().stream, (item, key) ->
		console.info item.type, key
		if item.type is 'commentReply' and item.created
			timestampRef = snap.ref().child "stream/#{key}/timestamp"
			# console.log timestampRef.path()
			timestampRef.set item.created