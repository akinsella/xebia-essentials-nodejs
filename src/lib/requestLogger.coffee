# the middleware function
module.exports = () ->
	return (req, res, next) ->
		console.log "---------------------------------------------------------"
		console.log "Http Request - Url: ", req.url
		console.log "Http Request - Query: ", req.query
		console.log "Http Request - Method: ", req.method
		console.log "Http Request - Headers: ", req.headers
		console.log "Http Request - Body: ", req.body
		console.log "Http Request - Raw Body: ", req.rawBody
		console.log "---------------------------------------------------------"

		next()
		return

