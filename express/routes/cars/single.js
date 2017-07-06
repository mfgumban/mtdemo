'use strict';
const data = require('../../data.json');

module.exports = (req, res) => {
  const carId = req.params.carId * 1;
  const car = data.cars.find(m => m.id === carId);
  let q = req.query;
  let r = q.this;

  res.status(200).json({ r });
};