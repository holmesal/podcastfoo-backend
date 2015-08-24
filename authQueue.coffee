Queue = require 'firebase-queue'
Firebase = require 'firebase'
graph = require 'fbgraph'
_ = require 'lodash'

rootRef = new Firebase 'https://podcast.firebaseio.com'

globalUserListRef = rootRef.child 'globalUserList'
globalUserListRef.on 'value', (snap) ->
	globalUserList = snap.val()

	queueRef = rootRef.child 'queues/auth'
	queue = new Queue queueRef, (item, progress, resolve, reject) ->
		# Make sure this user is in the global list of users
		globalUserListRef.child(item.uid).set true
		# Go get this user's list of friends from facebook
		# NOTE - these are only the friends that have added podcastfoo & have allowed it access to friend list
		graph.get "me/friends?access_token=#{item.facebook.token}", (err, res) ->
			gotFriends item, err, res, resolve, reject

gotFriends = (item, err, res, resolve, reject) =>
	if err
		console.log err
		reject err
	else
		# console.info res
		if res.data
			_.map res.data, (friend) ->
				# Friend each one of these users
				selfId = item.uid
				friendId = "facebook:#{friend.id}"
				follow selfId, friendId
				follow friendId, selfId
		else
			console.info 'got no data ... :-('
		if res.paging?.next
			graph.get res.paging.next, (err, res) ->
				gotFriends item, err, res, resolve, reject
		else
			resolve()

follow = (selfId, toFollowId) ->
	# Unless this user already follows this other user
	followRef = rootRef.child "users/#{selfId}/following/#{toFollowId}"
	followRef.once 'value', (snap) ->
		doesFollow = snap.val()
		if doesFollow
			console.info "[ ] #{selfId} is already following #{toFollowId}"
		else
			rootRef.child("users/#{selfId}/following/#{toFollowId}").set true
			rootRef.child("users/#{toFollowId}/followers/#{selfId}").set true
			console.info "[#{String.fromCharCode(0x2714)}] #{selfId} is now following #{toFollowId}"
			# Grab 10 items from this user's recent activity and push them into your stream
			recentActivityRef = rootRef.child("activityByUser/#{toFollowId}").limitToLast 10
			recentActivityRef.once 'value', (snap) ->
				recentActivity = snap.val()
				userStreamRef = rootRef.child "streamByUser/#{selfId}"
				userStreamRef.update snap.val()
			# TODO - Send this user a notification that you are now following them