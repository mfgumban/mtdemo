const data = require('../../data.json');

module.exports = (req, res) => {
  const cars = data.cars;
    // const fullUrl = req.protocol + '://' + req.get('Host') + req.originalUrl;  

  res.status(200).json({ cars });
};