Queue = require 'firebase-queue'
Firebase = require 'firebase'

# options = 
# 	specId: 'propagateActivity'
# 	numWorkers: 1

queueRef = new Firebase 'https://podcast.firebaseio.com/queues/activity'
queue = new Queue queueRef, (data, progress, resolve, reject) ->
	console.info 'got queue data!', data

	if data.type is 'comment'
		# Go get the author
		# Go get the comment
		# Build a stream activity item
		# Push it into the stream of everyone that cares