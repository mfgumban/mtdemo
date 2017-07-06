var suggest = require('/lib/symptom-suggest-lib.sjs');

// GET
//
// This function returns a document node corresponding to each
// user-defined parameter in order to demonstrate the following
// aspects of implementing REST extensions:
// - Returning multiple documents
// - Overriding the default response code
// - Setting additional response headers
//
function get(context, params) {
  
  var results = [];
  context.outputTypes = [];
  xdmp.log(params);
  for (var pname in params) {
    if (params.hasOwnProperty(pname)) {
      results.push({name: pname, value: params[pname]});
    }
  }

  // var func = params["function"];
  // if (func != null) {
  //   results.push("ajacobs" + func);
  // }
  var term = params["term"];
  var response = suggest.listSuggests(term, "dmlc");

  // Return a successful response status other than the default
  // using an array of the form [statusCode, statusMessage].
  // Do NOT use this to return an error response.
  context.outputStatus = [201, 'Yay'];
  context.outputTypes.push('application/json');

  // Set additional response headers using an object
  // context.outputHeaders = 
  //   {'X-My-Header1' : 42, 'X-My-Header2': 'h2val' };

  // Return a Sequence to return multiple documents
  // return Sequence.from(results);
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