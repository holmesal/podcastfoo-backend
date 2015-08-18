Firebase = require 'firebase'
request = require 'request'


searchRef = new Firebase 'https://podcast.firebaseio.com/search'

# Clear existing search requests/results
searchRef.set null

searchRef.child('request').on 'child_added', (snap) ->
	params = snap.val()?.params

	unless params
		console.error 'improper query parameters passed'
		console.error snap.val()
		return false

	request 
		url: 'https://itunes.apple.com/search'
		json: true
		qs: params
	, (err, res, body) =>
			resultsRef = searchRef.child "response/#{snap.ref().key()}"
			resultsRef.set
				results: body.results.slice 0,5
				queryParams: params

			# Remove the search request ref
			snap.ref().set null

			# Remove the search results ref after a short delay
			setTimeout ->
				resultsRef.set null
			, 10000

