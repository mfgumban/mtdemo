var geo = require('/lib/geo-lib.xqy');

function get(context, params) {
  
  context.outputTypes = [];

  const address = params["address"]
  if (address == null) {
    context.outputStatus = [400, 'Bad Request'];
    return; 
  }
  
  var response = geo.geoCodeFullAddress(address);
  if (response == null) {
    context.outputStatus = [200, 'OK'];
    context.outputTypes.push('application/json');
  }
  else {
    context.outputStatus = [401, 'No Records Found '];
  }

  return response;

};

// PUT
//
// The client should pass in one or more documents, and for each
// document supplied, a value for the 'basename' request parameter.
// The function inserts the input documents into the database only 
// if the input type is JSON or XML. Input JSON documents have a
// property added to them prior to insertion.
//
// Take note of the following aspects of this function:
// - The 'input' param might be a document node or a Sequence
//   over document nodes. You can normalize the values so your
//   code can always assume a Sequence.
// - The value of a caller-supplied parameter (basename, in this case)
//   might be a single value or an array.
// - context.inputTypes is always an array
// - How to return an error report to the client
//
function put(context, params, input) {
  xdmp.log('PUT invoked');
  return null;
};

function post(context, params, input) {
  xdmp.log('POST invoked');
  return null;
};

function deleteFunction(context, params) {
  xdmp.log('POST invoked');
  return null;
};



// Helper function that demonstrates how to normalize inputs
// that may or may not be multi-valued, such as the 'input'
// param to your methods.
//
// In cases where you might receive either a single value
// or a Sequence, depending on the request context,
// you can normalize the data type by creating a Sequence
// from the single value.
function normalizeInput(item)
{
  return (item instanceof Sequence)
         ? item                        // many
         : Sequence.from([item]);      // one
};

// Helper function that demonstrates how to return an error response
// to the client.

// You MUST use fn.error in exactly this way to return an error to the
// client. Raising exceptions or calling fn.error in another manner
// returns a 500 (Internal Server Error) response to the client.
function returnErrToClient(statusCode, statusMsg, body)
{
  fn.error(null, 'RESTAPI-SRVEXERR', 
           Sequence.from([statusCode, statusMsg, body]));
  // unreachable - control does not return from fn.error.
};

// Include an export for each method supported by your extension.
exports.GET = get;
exports.POST = post;
exports.PUT = put;
exports.DELETE = deleteFunction;