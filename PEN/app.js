const express = require('express');
const logger = require('morgan');
const bodyParser = require('body-parser');
const path = require('path');
const env = process.env.NODE_ENV || 'development';
const config = require(`${__dirname}/server/config/config.json`)[env];
const host = process.env.HOST || 'localhost';

const app = express();

app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

require('./server/routes')(app);
app.use(express.static(path.join(__dirname, '')));
app.get('*', (req, res) => res.status(200).send({
  message: 'Welcome to the beginning of nothingness. Host: ' + host + ' Database: ' + config.host,
}));

module.exports = app;
