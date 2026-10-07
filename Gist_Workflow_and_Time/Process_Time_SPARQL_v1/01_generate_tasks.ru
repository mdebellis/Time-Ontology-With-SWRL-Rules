# Version 1: rebuild generated task structure from asserted templates.
# Read README.md before loading your own data.
# Input: graph:source. Output owned exclusively by this script:
# graph:generated-tasks. Run this file, then 02_rebuild_time_relations.ru.
# One task per (project, immediate component template); no loops or scheduling.
# Existing source task identities are reused; otherwise IRIs are deterministic.
# Preconditions: named projects/templates, exactly one process template per
# project, and at most one source task for each project/step pair.

PREFIX gist:  <https://w3id.org/semanticarts/ns/ontology/gist/>
PREFIX ipt:   <https://www.in2use.com/process-time/>
PREFIX graph: <https://www.in2use.com/process-time/graph/>
PREFIX time:  <http://www.w3.org/2006/time#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos:  <http://www.w3.org/2004/02/skos/core#>
PREFIX xsd:   <http://www.w3.org/2001/XMLSchema#>

CLEAR SILENT GRAPH graph:generated-tasks;

# 1. Instantiate the component tasks. Source task labels take precedence.
INSERT {
  GRAPH graph:generated-tasks {
    ?task a gist:Task ;
          gist:isBasedOn ?step ;
          gist:isPartOf ?project ;
          rdfs:label ?label ;
          skos:prefLabel ?label .
  }
}
WHERE {
  GRAPH graph:source {
    ?project a gist:Project ; gist:isBasedOn ?process .
    ?process a gist:TaskTemplate .
    ?step a gist:TaskTemplate ; gist:isPartOf ?process .
    FILTER(isIRI(?project) && isIRI(?step) && ?step != ?process)
    OPTIONAL {
      ?existingTask gist:isPartOf ?project ; gist:isBasedOn ?step .
      FILTER(isIRI(?existingTask) && ?existingTask != ?project)
    }
    OPTIONAL { ?step skos:prefLabel ?templateLabel . }
  }
  BIND(COALESCE(?existingTask,
       IRI(CONCAT(STR(?project), "/task/", SHA256(STR(?step))))) AS ?task)
  OPTIONAL { GRAPH graph:source { ?task skos:prefLabel ?existingLabel . } }
  BIND(IF(BOUND(?templateLabel),
       STRLANG(REPLACE(STR(?templateLabel), " — template$", ""), LANG(?templateLabel)),
       STR(?step)) AS ?newLabel)
  BIND(COALESCE(?existingLabel, ?newLabel) AS ?label)
};

# 2. Instantiate each task's goals, following the current example's use
# of a distinct intention based on the template's intention.
INSERT {
  GRAPH graph:generated-tasks {
    ?task gist:hasGoal ?goal .
    ?goal a gist:Intention ; gist:isBasedOn ?templateGoal ;
          rdfs:label ?goalLabel ; skos:prefLabel ?goalLabel .
  }
}
WHERE {
  GRAPH graph:generated-tasks {
    ?task a gist:Task ; gist:isBasedOn ?step .
  }
  GRAPH graph:source {
    ?step gist:hasGoal ?templateGoal .
    FILTER(isIRI(?templateGoal))
    OPTIONAL {
      ?task gist:hasGoal ?existingGoal .
      ?existingGoal gist:isBasedOn ?templateGoal .
      FILTER(isIRI(?existingGoal))
    }
    OPTIONAL { ?templateGoal skos:prefLabel ?templateGoalLabel . }
  }
  BIND(COALESCE(?existingGoal,
       IRI(CONCAT(STR(?task), "/goal/", SHA256(STR(?templateGoal))))) AS ?goal)
  OPTIONAL { GRAPH graph:source { ?goal skos:prefLabel ?existingGoalLabel . } }
  BIND(COALESCE(?existingGoalLabel, ?templateGoalLabel, STR(?templateGoal)) AS ?goalLabel)
};

# 3. Carry the template ordering to this project's tasks. The property path
# includes its transitive consequences. This is intended workflow ordering;
# it neither assigns dates nor asserts time:before from the template order.
INSERT {
  GRAPH graph:generated-tasks { ?taskA gist:precedes ?taskB . }
}
WHERE {
  GRAPH graph:generated-tasks {
    ?taskA gist:isPartOf ?project ; gist:isBasedOn ?stepA .
    ?taskB gist:isPartOf ?project ; gist:isBasedOn ?stepB .
  }
  GRAPH graph:source { ?stepA gist:precedes+ ?stepB . }
  FILTER(?taskA != ?taskB)
}
