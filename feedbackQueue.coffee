Queue = require 'firebase-queue'
Firebase = require 'firebase'
GitHubApi = require 'github'

github = new GitHubApi
	version: '3.0.0'
	headers:
		'user-agent': 'mountainlab'

unless process.env.githubToken
	console.error '[feedbackQueue] - no github token provided'

github.authenticate
	type: 'oauth'
	token: process.env.githubToken

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

