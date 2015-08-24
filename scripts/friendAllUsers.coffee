Firebase = require 'firebase'
_ = require 'lodash'
rootRef = new Firebase 'https://podcast.firebaseio.com'

usersRef = rootRef.child "users"
usersRef.once 'value', (snap) ->
	users = snap.val()
	uids = _.keys(users)
	console.info uids
	realPeople = (uid for uid in uids when uid not in ['facebook:134609796881834', 'facebook:161611324173367', 'facebook:150900101914974'])
	console.info realPeople

	for self in realPeople
		for toFollow in realPeople
			unless self is toFollow
				# console.info "#{self} <--> #{toFollow}"
				follow self, toFollow
				follow toFollow, self


follow = (selfId, toFollowId) ->
	# Unless this user already follows this other user
	followRef = rootRef.child "users/#{selfId}/following/#{toFollowId}"
	followRef.once 'value', (snap) ->
		doesFollow = snap.val()
		# if doesFollow
		# 	console.info "[ ] #{selfId} is already following #{toFollowId}"
		# else
		rootRef.child("users/#{selfId}/following/#{toFollowId}").set true
		rootRef.child("users/#{toFollowId}/followers/#{selfId}").set true
		console.info "[#{String.fromCharCode(0x2714)}] #{selfId} is now following #{toFollowId}"
		# Grab 10 items from this user's recent activity and push them into your stream
		recentActivityRef = rootRef.child("activityByUser/#{toFollowId}").limitToLast 100
		recentActivityRef.once 'value', (snap) ->
			recentActivity = snap.val()
			if recentActivity
				userStreamRef = rootRef.child "streamByUser/#{selfId}"
				userStreamRef.update snap.val()