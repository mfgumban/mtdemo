


function getPractitionerById(id, bundle) {
    const q = cts.jsonPropertyValueQuery('id', id);
    const coll = cts.collectionQuery("Practitioner");
    const result =  cts.search(cts.andQuery([q, coll]));

    if (bundle)
        return buildBundle(result);
    else return result;

};

function getPractitioners(count) {
    count = count || 10;
    return buildBundle(fn.subsequence(fn.collection("Practitioner"), 1, count));
};

function buildBundle(response) {
    var bundle = 
 // "resourceType": "Bundle",
 //    "id": text {sem:uuid-string()},
 //    "meta": object-node {
 //        "lastUpdated": fn:current-dateTime()
 //    },
 //    "type": "searchset"
 //    "total": number-node{4},
 //    "link": array-node {
 //        object-node {
 //          "relation": "self",
 //          "url": $url
    {
        "resourceType": "Bundle",
        "id": sem.uuidString(),
        "meta": {
            "lastUpdated": fn.currentDateTime()
        },
        "type": "searchset",
        "total": fn.count(response),
        "link": [ 
            {"relation": "self",
            "url": "myurl"},
        ],
        "docs": Sequence.from(response)
    }

    return bundle;
}



module.exports = {
  getPractitionerById:  getPractitionerById,
  getPractitioners:     getPractitioners,
  buildBundle:          buildBundle
};


