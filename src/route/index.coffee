fs = require 'fs'
xml2json = require 'xml2json'
_ = require('underscore')._
async = require 'async'
request = require 'request'
mkdirp = require 'mkdirp'
jsdom = require 'jsdom'

jquery = fs.readFileSync("./lib/jquery.js", "utf-8");

fetchCardFullContent = (card, cb) =>
	console.log "Requesting a response for url: '#{card.url}'"

	filePath = "pages/#{card.id}.html"
	fs.lstat filePath, (err, stats) ->
		if !err && stats.isFile()
			fs.readFile filePath, (err, body) ->
				jsdom.env
					html: body,
					src: [jquery],
					done: (err, window) ->
						if (err)
							cb(err)
						else
							window.$("#card_images").remove()
							fullContent = window.$("#main-content").html()
							card.fullContent = fullContent
							cb(null, card)
						window.close()
		else
			request.get card.url, (err, response, body) ->
				if err
					console.log "Could not get Url: #{card.url}, Error: '#{err.message}'"
					cb(err)
				else if response.statusCode != 200
					cb(new Error("Status code - #{response.statusCode}"))
				else
					console.log "Got a response for url: '#{card.url}'"

					jsdom.env
						html:body,
						src: [jquery],
						done: (err, window) ->
							if (err)
								cb(err)
							else
								window.$("#card_images").remove()
								card.fullContent = window.$("#main-content").html()
								cb(null, card)
								mkdirp "pages", (err) ->
									if !err || err.code == 'EEXIST'
										fs.writeFile filePath, body
							window.close()


cards = (req, res) =>
	dataAsXml = fs.readFileSync './data/cards.xml'
	data = JSON.parse(xml2json.toJson(dataAsXml))
	deck = data.deck
	categories = deck.categories.category
	delete deck.categories

	_(categories).each (category) ->
		delete category.cmyk

		category.backgroundColor = category["background-color"]
		delete category["background-color"]

	deck.cards = deck.card
	delete deck.card

	_(deck.cards).each (card) ->

		if card.altid
			card.id = card.altid
			delete card.altid

		card.category = _(categories).find((category) ->
			card.category == category.id)

		card.sponsors = _(card.sponsors.split(" ")).map((sponsor) ->
			id: sponsor
		)

		console.log "Card ID: #{card.id}"
		console.log "Card tags: #{card.tags}"

		card.tags = if !card.tags then [] else _(card.tags.split(" ")).map((tag) ->
			id: tag
		)

		card.title = convertObjectToText(card.front)
		delete card.front

		card.note = unescapeHtml(card.note)

		card.description = convertObjectToHtml(card.back)
		delete card.back

		if !card.ulink
			card.ulink = []

		if !Array.isArray(card.ulink)
			card.ulink = [ card.ulink ]

		card.ulinks = card.ulink
		delete card.ulink

		card.url = "http://essentials.xebia.com/#{card.id}"
		delete card.bitly

	async.map deck.cards, fetchCardFullContent, (err, results) ->
		if err
			console.log "Could not get card data content"
			res.send(500, err.message)
		else
			console.log "Got full content for #{results.length} cards"
			res.json deck

convertObjectToHtml = (data) ->
    html = ""
    for key, value of data
        if key == "para"
            if typeIsArray(value)
                html += value.reduce (x, y) -> "#{x} #{y}"
            else
                html += "<p>#{value}</p>"
        else if key == "blockquote"
            result = convertObjectToHtml(value)
            html += "<blockquote>#{result}</blockquote>"
        else if key == "ul"
            result = value.li.map (liContent) -> "<li>#{liContent}</li>"
            html += "<ul>#{result.join("")}</ul>"
        else if key == "attribution"
            result = "<p><i>#{value}</i></p>"
        else
            html += "<p>#{value}</p>"
    unescapeHtml(html)


convertObjectToText = (data) ->
    text = ""
    for key,value of data
#		if typeIsArray(value)
#			text += convertObjectToHtml(item) for item of value
        if key == "para"
            if typeIsArray(value)
                text += value.reduce (x, y) -> "#{x}, #{y}"
            else
                text += "#{value}"
        else
            text += "#{value}"

    unescapeHtml(text)

unescapeHtml = (value) -> if value == undefined then undefined else value.replace("&apos;", "'")

typeIsArray = Array.isArray || (value) -> return {}.toString.call(value) is '[object Array]'

module.exports =
    cards: cards
