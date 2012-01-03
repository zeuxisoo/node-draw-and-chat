var express = require('express'),
	socket = require('socket.io'),
	routes = require('./routes')

var app = module.exports = express.createServer(),
	io = socket.listen(app);

app.configure(function(){
	app.set('views', __dirname + '/views');
	app.set('view engine', 'jade');
	app.use(express.bodyParser());
	app.use(express.methodOverride());
	app.use(express.cookieParser());
	app.use(express.session({ secret: 'This is a key **** PLEASE CHANGE ****' }));
	app.use(app.router);
	app.use(express.static(__dirname + '/public'));
});

app.configure('development', function(){
	app.use(express.errorHandler({ dumpExceptions: true, showStack: true })); 
});

app.configure('production', function(){
	app.use(express.errorHandler()); 
});

app.get('/', routes.index);

app.listen(3000);
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);

var onlineList = {};

io.sockets.on('connection', function(socket) {
	var address = socket.handshake.address;

	socket.on('login', function(data) {
		if (onlineList[data.username]) {
			socket.emit('relogin');
		}else{
			socket.set('username', data.username, function() {
				onlineList[data.username] = socket;
				socket.broadcast.emit('loggined', 'Login > ' + data.username + ' connected');
			});
		}
	});

	socket.on('drawing', function(data) {
		socket.get('username', function(error, username) {
			data['status'] = 'Draw > ' + username;

			socket.broadcast.emit('draw', data);
		});
	});

	socket.on('loadingImage', function(data) {
		socket.get('username', function(error, username) {
			data['status'] = 'Image > IP: ' + username + ' sent';

			socket.broadcast.emit('loadImage', data);
		});
	});

	socket.on('saying', function(data) {
		socket.get('username', function(error, username) {
			data['username'] = username;
			data['status'] = 'Say > ' + username + ' said';

			io.sockets.emit('say', data);
		});
	});

	socket.on('cleaned', function(data) {
		socket.get('username', function(error, username) {
			socket.broadcast.emit('clear', 'Clear > ' + username + ' cleaned');
		});
	});

	socket.on('disconnect', function(data) {
		socket.get('username', function(error, username) {
			if (username != null) {
				delete onlineList[username];
				io.sockets.emit('logout', 'Logout > ' + username + ' disconnected');
			}
		});
	});
});