Queue = require 'firebase-queue'
Firebase = require 'firebase'
GitHubApi = require 'github'

github = new GitHubApi
	version: '3.0.0'
	headers:
		'user-agent': 'mountainlab'

unless process.env.token
	console.error '[feedbackQueue] - no token provided'

github.authenticate
	type: 'oauth'
	token: process.env.token

queueRef = new Firebase 'https://podcast.firebaseio.com/queues/feedback'
queue = new Queue queueRef, (data, progress, resolve, reject) ->

	github.issues.create
		user: 'holmesal'
		repo: 'podcastfoo'
		title: "[feedback] " + data.text.substring 0, 50
		body: """
		## url: [#{data.url}](#{data.url})
		

		#{data.text}
		"""
		labels: ['feedback']
	, (err, data) ->
		if err
			reject err
		else
			resolve data

