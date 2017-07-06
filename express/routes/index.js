const routes = require('express').Router();
const models = require('./models');
const cars = require('./cars');
const practitioner = require('./practitioners');

routes.use('/models', models);
routes.use('/cars', cars);
routes.use('/fhir/Practitioner', practitioner);
routes.get('/', (req, res) => {
  res.status(200).json({ message: 'Connected!' });
});

module.exports = routes;

