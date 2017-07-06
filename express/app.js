// Bring in our dependencies
const app = require('express')();
const routes = require('./routes');

//  Connect all our routes to our application
app.use('/', routes);

// Turn on that server!
app.listen(3001, () => {
  console.log('App listening on port 3001');
});