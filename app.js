// Generated by CoffeeScript 1.6.3
var ECT, allowCrossDomain, app, ectRenderer, express, fs, path, requestLogger, routes, util, utils,
  _this = this;

fs = require('fs');

path = require('path');

util = require('util');

express = require('express');

requestLogger = require('./lib/requestLogger');

allowCrossDomain = require('./lib/allowCrossDomain');

utils = require('./lib/utils');

routes = require('./route');

ECT = require('ect');

ectRenderer = ECT({
  cache: true,
  watch: true,
  root: "views"
});

if (!String.prototype.trim) {
  String.prototype.trim = function() {
    return this.replace(/^\s+|\s+$/g, '');
  };
}

app = express();

app.configure(function() {
  var store;
  console.log("Environment: " + (app.get('env')));
  app.set('port', 9000);
  app.set('views', "" + __dirname + "/views");
  app.set('view engine', 'ect');
  app.engine('.ect', ectRenderer.render);
  app.use('/images', express["static"]("" + __dirname + "/public/images"));
  app.use('/scripts', express["static"]("" + __dirname + "/public/scripts"));
  app.use('/styles', express["static"]("" + __dirname + "/public/styles"));
  app.use(express.favicon());
  app.use(express.bodyParser());
  app.use(express.cookieParser());
  store = new express.session.MemoryStore;
  app.use(express.session({
    secret: 'something',
    store: store
  }));
  app.use(express.logger());
  app.use(express.methodOverride());
  app.use(allowCrossDomain());
  app.use(requestLogger());
  app.use(app.router);
  app.use(function(err, req, res, next) {
    console.error("Error: " + err + ", Stacktrace: " + err.stack);
    return res.send(500, "Something broke! Error: " + err + ", Stacktrace: " + err.stack);
  });
});

app.configure('development', function() {
  app.use(express.errorHandler({
    dumpExceptions: true,
    showStack: true
  }));
});

app.configure('production', function() {
  app.use(express.errorHandler());
});

app.get('/cards', routes.cards);

process.on('SIGTERM', function() {
  console.log('Got SIGTERM exiting...');
  return process.exit(0);
});

process.on('uncaughtException', function(err) {
  console.error("An uncaughtException was found, the program will end. " + err + ", stacktrace: " + err.stack);
  return process.exit(1);
});

console.log("Express listening on port: " + (app.get('port')));

app.listen(app.get('port'));

console.log('Initializing xml2json-xebia-card-converter application');

/*
//@ sourceMappingURL=app.map
*/
