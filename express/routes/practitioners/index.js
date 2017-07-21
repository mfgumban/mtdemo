'use strict';
var request = require('request');
var qs = require('qs');
var url = require('url');

const practitioner = require('express').Router();

const baseUrl = "http://mitatac.demo.marklogic.com:8040/v1/resources/";
//const baseUrl = "http://localhost:9200/v1/resources/";
const username = 'mitatac-node-user';
const password = 'Zp_l^L`~by8d=2vzNJ^7';

function addRSNamespaceToParams(req) {
 // Convert to rs: namespace
 let rsParams = {};
 let params = req.query;
 for (var pname in params) {
    if (params.hasOwnProperty(pname)) {
      rsParams["rs:"+ pname] = params[pname];
  }
}
return rsParams;
};

function fullUrl(req) {
    var urlobj = url.parse(req.originalUrl);
    urlobj.protocol = req.protocol;
    urlobj.host = req.get('host');
    var requrl = url.format(urlobj);
    return requrl;
};

function addUrl(body, url) {
    body = JSON.parse(body);
    if (body.link) {
        body.link[0].url = url;
    }
    return body;
};

function processSearch(req, res) {
  const url = res.params ? baseUrl : baseUrl + "practitioner-search?" + qs.stringify(addRSNamespaceToParams(req));
  console.log(qs.stringify(req.query));
  console.log(url);
  request.get(url, function(err, response, body) {
      if (!err) {
          body = addUrl(body, fullUrl(req));
          console.log(body);
          res.json(body);
      }
  })
  .auth(username, password, true);
};

practitioner.get('/', processSearch);
practitioner.post('/_search', processSearch);

practitioner.get('/:practitionerID', (req, res) => {
    const practitionerId = req.params.practitionerID;
    const url = baseUrl + 'practitioner?rs:practitionerId=' + practitionerId;
    console.log(url);

    request.get(url, function(err, response, body) {
        if (!err) {
            body = addUrl(body, fullUrl(req));
            console.log(body);
            res.json(body);
      }
  })
  .auth(username, password, true);
});

module.exports = practitioner;