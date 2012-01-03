$ ->
	# socket
	socket = io.connect window.location.href

	socket.on 'loggined', (data) ->
		addStatus data

	socket.on 'logout', (data) ->
		addStatus data

	socket.on 'relogin', (data) ->
		$('#says').hide()
		$('#login').show()

	socket.on 'draw', (data) ->
		draw data.type, data.x, data.y, data.strokeColor, data.lineWidth, data.status

	socket.on 'loadImage', (data) ->
		clearBoard()
		
		img = new Image()
		img.onload = ->
			$context.drawImage img, 0, 0, img.width, img.height
			img = null
		img.src = data.dataURL
		addStatus(data.status)

	socket.on 'say', (data) ->
		$messages.append("<p><strong>#{data.username}</strong>: #{data.says}</p>")
		addStatus data.status

	socket.on 'clear', (data) ->
		if confirm 'Clear the board?'
			addStatus data
			clearBoard()

	# color
	$color = $('.color')
	$selected_color = $('span.color')
	$selected_line_width = $('select[name=line-width]')

	$color.click ->
		$selected_color.css 
			backgroundColor: $(this).data('color')

		$selected_color.data 'color', $(this).data('color')

	$color.each ->
		$(this).css
			backgroundColor: $(this).data('color')

	# canvas
	$canvas = $('canvas')
	$context = $canvas[0].getContext("2d")
	$context.lineCap = 'round'

	$canvas.bind 'drag dragstart dragend', (e) ->
		type = e.handleObj.type
		offset = $(this).offset()

		e.offsetX = e.layerX - offset.left
		e.offsetY = e.layerY - offset.top

		x = e.offsetX
		y = e.offsetY

		strokeColor = $selected_color.data('color')
		lineWidth = $selected_line_width.val()

		draw type, x, y, strokeColor, lineWidth, null

		socket.emit 'drawing',
			type: type
			x: x,
			y: y,
			strokeColor: strokeColor
			lineWidth: lineWidth

	# clear
	$('button[name=clear]').click (e) ->
		clearBoard()
		socket.emit 'cleaned'

	# drop image here
	$('#drop-image-here').bind 'dragover', (e) ->
		$(this).addClass 'drag-hover'
		return false

	$('#drop-image-here').bind 'drop', (e) ->
		e.preventDefault()

		file = e.originalEvent.dataTransfer.files[0]
		imageType = /image.*/

		if (file.type.match(imageType) == false)
			alert('File is not image')
		else
			clearBoard()

			reader = new FileReader()
			reader.onload = (e) ->
				socket.emit 'loadingImage',
					dataURL: e.target.result

				$img = $('<img>').attr('src', e.target.result)
				$context.drawImage $img[0], 0, 0, $img[0].width, $img[0].height
				
				$('#drop-image-here').removeClass()
				reader = null
			reader.readAsDataURL(file)

	# says
	$says = $('input[name=says]')
	$messages = $('#messages')

	$says.keypress (e) ->
		if e.keyCode == 13
			if $says.val().length <= 0
				return
			else
				data = 
					says: $says.val()
			
			socket.emit 'saying', data

			$says.val ""
			$says.focus()

	# login
	$username = $('input[name=username]')
	$loginButton = $('input[name=login]')

	$loginButton.click (e) ->
		if $username.val().length <= 0
			return
		else
			socket.emit 'login',
				data =
					username: $username.val()
			
			$('#says').show()
			$('#login').hide()

	# function
	draw = (type, x, y, strokeColor, lineWidth, status) ->
		$context.strokeStyle = strokeColor
		$context.lineWidth = lineWidth

		switch type
			when "dragstart"
				$context.beginPath()
				$context.moveTo x,y
				if status? then addStatus "#{status} started"
			when "drag"
				$context.lineTo x, y
				$context.stroke()
			else
				$context.closePath()
				if status? then addStatus "#{status} ended"

	addStatus = (text) ->
		$('#status').append "<p>#{text}</p>"
		$('#status').scrollTop 9999;

	clearBoard = ->
		$context.clearRect 0, 0, $('canvas').width(), $('canvas').height()