const todosController = require('../controllers').todos;
const todoItemsController = require('../controllers').todoItems;
const express = require('express');
const path = require('path');
const env = process.env.NODE_ENV || 'development';
const host = process.env.HOST || 'localhost';
const config = require(`${__dirname}/../config/config.json`)[env];

var swaggerJSDoc = require('swagger-jsdoc');

module.exports = (app) => {
  app.get('/api', (req, res) => res.status(200).send({
    message: 'Welcome to the Todos API!',
  }));
 /**
 * @swagger
 * definition:
 *   todos:
 *     properties:
 *       title:
 *         type: string
 */
  
/**
 * @swagger
 * /api/todos:
 *   post:
 *     tags:
 *       - todos
 *     description: Creates a new todo
 *     produces:
 *       - application/json
 *     parameters:
 *       - name: title
 *         description: todo title
 *         in: body
 *         required: true
 *         schema:
 *           $ref: '#/definitions/todos'
 *     responses:
 *       200:
 *         description: Successfully created
 */

  app.post('/api/todos', todosController.create);

/**
 * @swagger
 * /api/todos:
 *   get:
 *     tags:
 *       - todos
 *     description: Returns all todos
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: An array of todos
 *         schema:
 *           $ref: '#/definitions/todos'
 */
  app.get('/api/todos', todosController.list);
  app.get('/api/todos/:todoId', todosController.retrieve);
  app.put('/api/todos/:todoId', todosController.update);
  app.delete('/api/todos/:todoId', todosController.destroy);

  app.post('/api/todos/:todoId/items', todoItemsController.create);
  app.put('/api/todos/:todoId/items/:todoItemId', todoItemsController.update);
  app.delete(
    '/api/todos/:todoId/items/:todoItemId', todoItemsController.destroy
  );
  app.all('/api/todos/:todoId/items', (req, res) => res.status(405).send({
    message: 'Method Not Allowed',
  }));
  var host_address = host + ':8000';
  var swaggerDefinition = {
	  info: {
		title: 'Node Swagger API',
		version: '1.0.0',
		description: 'Demo RESTful API',
	  },
	  host: host_address,
	  basePath: '/',
	};

	// options for the swagger docs
	var options = {
	  // import swaggerDefinitions
	  swaggerDefinition: swaggerDefinition,
	  // path to the API docs
	  apis: ['./server/routes/*.js'],
	};

	// initialize swagger-jsdoc
	var swaggerSpec = swaggerJSDoc(options);
	app.get('/swagger.json', function(req, res) {
		res.setHeader('Content-Type', 'application/json');
		res.send(swaggerSpec);
	});
};
