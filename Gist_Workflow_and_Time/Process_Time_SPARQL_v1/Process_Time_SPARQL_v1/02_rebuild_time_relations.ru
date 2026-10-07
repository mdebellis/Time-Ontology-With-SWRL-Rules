# Version 1: direct SPARQL counterparts of the six revised SWRL rules.
# Input: graph:source. Output owned exclusively by this script:
# graph:generated-time. No prior generated result is used as input.
# The inverse relations and intervalIn consequences needed by the example
# are inserted explicitly. This is not a complete OWL reasoner.
# All source intervals are compared, including intervals from different projects.
# Comparisons accept xsd:dateTime or xsd:dateTimeStamp with explicit offsets.
# xsd:dateTime(STR(...)) avoids relying on native dateTimeStamp comparison.
# Shared endpoint *nodes* implement meets, starts, equals, as in the SWRL.
# No finishes rule, intervalBefore rule, or instant-ordering rule is added.

PREFIX gist:  <https://w3id.org/semanticarts/ns/ontology/gist/>
PREFIX ipt:   <https://www.in2use.com/process-time/>
PREFIX graph: <https://www.in2use.com/process-time/graph/>
PREFIX time:  <http://www.w3.org/2006/time#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos:  <http://www.w3.org/2004/02/skos/core#>
PREFIX xsd:   <http://www.w3.org/2001/XMLSchema#>

CLEAR SILENT GRAPH graph:generated-time;

# 1. A ends before B begins.
INSERT {
  GRAPH graph:generated-time {
    ?a time:before ?b .
    ?b time:after ?a .
  }
}
WHERE {
  GRAPH graph:source {
    ?a time:hasEnd ?endA .
    ?endA time:inXSDDateTimeStamp ?endDateALiteral .
    ?b time:hasBeginning ?startB .
    ?startB time:inXSDDateTimeStamp ?startDateBLiteral .
  }
  FILTER(DATATYPE(?endDateALiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?endDateALiteral)) AS ?endDateA)
  FILTER(BOUND(?endDateA) && TZ(?endDateA) != "")
  FILTER(DATATYPE(?startDateBLiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?startDateBLiteral)) AS ?startDateB)
  FILTER(BOUND(?startDateB) && TZ(?startDateB) != "")
  FILTER(?endDateA < ?startDateB)
};

# 2. A overlaps B: start(A) < start(B) < end(A) < end(B).
INSERT {
  GRAPH graph:generated-time {
    ?a time:intervalOverlaps ?b .
    ?b time:intervalOverlappedBy ?a .
  }
}
WHERE {
  GRAPH graph:source {
    ?a time:hasBeginning ?startA ; time:hasEnd ?endA .
    ?b time:hasBeginning ?startB ; time:hasEnd ?endB .
    ?startA time:inXSDDateTimeStamp ?startDateALiteral .
    ?endA time:inXSDDateTimeStamp ?endDateALiteral .
    ?startB time:inXSDDateTimeStamp ?startDateBLiteral .
    ?endB time:inXSDDateTimeStamp ?endDateBLiteral .
  }
  FILTER(DATATYPE(?startDateALiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?startDateALiteral)) AS ?startDateA)
  FILTER(BOUND(?startDateA) && TZ(?startDateA) != "")
  FILTER(DATATYPE(?endDateALiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?endDateALiteral)) AS ?endDateA)
  FILTER(BOUND(?endDateA) && TZ(?endDateA) != "")
  FILTER(DATATYPE(?startDateBLiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?startDateBLiteral)) AS ?startDateB)
  FILTER(BOUND(?startDateB) && TZ(?startDateB) != "")
  FILTER(DATATYPE(?endDateBLiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?endDateBLiteral)) AS ?endDateB)
  FILTER(BOUND(?endDateB) && TZ(?endDateB) != "")
  FILTER(?startDateA < ?startDateB && ?startDateB < ?endDateA && ?endDateA < ?endDateB)
};

# 3. A strictly contains B. During is also a subproperty of intervalIn.
INSERT {
  GRAPH graph:generated-time {
    ?a time:intervalContains ?b .
    ?b time:intervalDuring ?a ; time:intervalIn ?a .
  }
}
WHERE {
  GRAPH graph:source {
    ?a time:hasBeginning ?startA ; time:hasEnd ?endA .
    ?b time:hasBeginning ?startB ; time:hasEnd ?endB .
    ?startA time:inXSDDateTimeStamp ?startDateALiteral .
    ?endA time:inXSDDateTimeStamp ?endDateALiteral .
    ?startB time:inXSDDateTimeStamp ?startDateBLiteral .
    ?endB time:inXSDDateTimeStamp ?endDateBLiteral .
  }
  FILTER(DATATYPE(?startDateALiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?startDateALiteral)) AS ?startDateA)
  FILTER(BOUND(?startDateA) && TZ(?startDateA) != "")
  FILTER(DATATYPE(?endDateALiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?endDateALiteral)) AS ?endDateA)
  FILTER(BOUND(?endDateA) && TZ(?endDateA) != "")
  FILTER(DATATYPE(?startDateBLiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?startDateBLiteral)) AS ?startDateB)
  FILTER(BOUND(?startDateB) && TZ(?startDateB) != "")
  FILTER(DATATYPE(?endDateBLiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?endDateBLiteral)) AS ?endDateB)
  FILTER(BOUND(?endDateB) && TZ(?endDateB) != "")
  FILTER(?startDateA < ?startDateB && ?endDateB < ?endDateA)
};

# 4. Shared beginning node; A ends earlier than B.
INSERT {
  GRAPH graph:generated-time {
    ?a time:intervalStarts ?b ; time:intervalIn ?b .
    ?b time:intervalStartedBy ?a .
  }
}
WHERE {
  GRAPH graph:source {
    ?a time:hasBeginning ?start ; time:hasEnd ?endA .
    ?b time:hasBeginning ?start ; time:hasEnd ?endB .
    ?endA time:inXSDDateTimeStamp ?endDateALiteral .
    ?endB time:inXSDDateTimeStamp ?endDateBLiteral .
  }
  FILTER(DATATYPE(?endDateALiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?endDateALiteral)) AS ?endDateA)
  FILTER(BOUND(?endDateA) && TZ(?endDateA) != "")
  FILTER(DATATYPE(?endDateBLiteral) IN (xsd:dateTime, xsd:dateTimeStamp))
  BIND(xsd:dateTime(STR(?endDateBLiteral)) AS ?endDateB)
  FILTER(BOUND(?endDateB) && TZ(?endDateB) != "")
  FILTER(?endDateA < ?endDateB)
};

# 5. Meets: the same boundary node is A's end and B's beginning.
INSERT {
  GRAPH graph:generated-time {
    ?a time:intervalMeets ?b .
    ?b time:intervalMetBy ?a .
  }
}
WHERE {
  GRAPH graph:source {
    ?a time:hasEnd ?boundary .
    ?b time:hasBeginning ?boundary .
  }
};

# 6. Equal interval extent: shared endpoint nodes. Self-equality is retained.
INSERT {
  GRAPH graph:generated-time {
    ?a time:intervalEquals ?b .
  }
}
WHERE {
  GRAPH graph:source {
    ?a time:hasBeginning ?start ; time:hasEnd ?end .
    ?b time:hasBeginning ?start ; time:hasEnd ?end .
  }
}
