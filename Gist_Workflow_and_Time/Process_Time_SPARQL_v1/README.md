# Process and time: SPARQL Update experiment, version 1

These updates implement the two proposed operations: instantiate tasks from
gist task templates, and rebuild the temporal relationships calculated by the
six revised SWRL rules. Each operation clears its own generated graph and
recalculates its contents. The source graph is never cleared or edited.

## Run the supplied example

1. Load `onboarding_demo.trig` into an empty test repository as **TriG**,
   preserving its named graph. It contains the input data and no generated
   task structure or temporal relations.
2. Run `00_check_endpoints.rq` as a SELECT query. The demo should return no rows.
3. Run the entire `01_generate_tasks.ru` file as one SPARQL Update request.
4. Run the entire `02_rebuild_time_relations.ru` file as one SPARQL Update request.
5. Run `03_view_temporal_relations.rq` as a CONSTRUCT query. It reproduces the
   Figure 3 view: **eight nodes and twelve edges**.

The `.ru` files contain multiple operations separated by semicolons. Keep the
prefix declarations at the top when submitting them. No reasoner or imported
ontology is needed to execute this demonstration: matching uses explicit
triples, and the outputs needed here are inserted directly.

For a local check, install RDFLib and run `python verify_demo.py`. The files
were executed with RDFLib 7.6.0. They have **not yet been run against
AllegroGraph, so this is a locally verified first version for
testing there, not a claim about AllegroGraph performance.

After Step 5, if you are working in Gruff and do Visualize Graph, you should see something like the following:

<img width="1093" height="995" alt="SPARQL_Time_Process_Test" src="https://github.com/user-attachments/assets/e6f3470a-4656-4eee-a8f3-f798947a7205" />

## Graph ownership

All graph IRIs begin with `https://www.in2use.com/process-time/graph/`.

| Graph | Contents | Rebuilt by these updates? |
|---|---|---|
| `source` | Templates, source project facts, dates, endpoints, and manually maintained task facts | No |
| `generated-tasks` | Task and goal types, labels, links, and intended task ordering | Yes, update 01 |
| `generated-time` | Computed temporal relationships | Yes, update 02 |

Only the two generated graphs belong to the scripts. Keep manually entered
facts in `source`, even when they describe a generated task. Query the source
and generated graphs together; query 03 explicitly selects all three and
does not depend on a store's default-union setting.

For use with the full ontology, load the **asserted** Turtle source into the
`source` graph using the exact IRI above. Loading it into the default graph
will not make it visible to these updates. An existing repository containing
exported inferences is not a clean input: those triples would remain in their
original graphs after a rebuild. Use a fresh test repository or separately
resolve that migration before applying the pattern to existing data.

For a later shared application, execute the clear and insert operations in a
transaction and commit after success, or build replacement graphs before
switching readers to them. The SPARQL text alone does not guarantee an atomic
refresh across the two files. This first experiment assumes no concurrent
reader or writer needs a consistent intermediate view.

## Task generation

The input includes an explicitly typed `gist:Project` linked by
`gist:isBasedOn` to an explicitly typed `gist:TaskTemplate`. Its component
templates are explicitly typed `gist:TaskTemplate` instances linked to that
process by `gist:isPartOf`.

Update 01 generates one task per project/component-template pair. It creates
a separate goal based on each template goal, following the existing example,
and carries `gist:precedes` ordering to the generated tasks, including its
transitive consequences. **Intended workflow order does not establish the
actual temporal order**; the dates determine the temporal relations in update 02.

A task already asserted in `source` with matching `gist:isPartOf` and
`gist:isBasedOn` links is reused. Otherwise its IRI is:

```text
project IRI + "/task/" + SHA256(full template IRI)
```

Goal IRIs similarly use the task IRI and a hash of the template-goal IRI.
Labels provide the human-readable names. Repeating the update produces the
same identifiers. This lets source dates, participants, and later annotations
remain attached to the same tasks after a rebuild. Source task/goal labels
take precedence when present.

The supplied demo uses these generated identifiers for the original Alex
schedule. The input holds dates and participants for those identifiers; the
update supplies their task types, links, goals, labels, and ordering. For a
new unscheduled project, it creates the task structure without inventing dates.

Version 1 assumptions:

- Projects and templates have IRIs. Each project has one process template.
- Each component occurs once per project, at one level of decomposition.
  Repeated steps, loops, conditional branches, and nested task generation
  require a later occurrence model.
- There is at most one asserted task for each project/template pair and at
  most one asserted goal for each task/template-goal pair.
- Template goals have IRIs. Labels are optional; templates normally have one
  `skos:prefLabel` per language. Multiple labels do not create extra task IRIs.
- Orderings are acyclic. This prototype does not validate all workflow inputs.
- Participants, actual dates, status, and other task-specific facts remain
  source data. Project participation is not automatically propagated.

Removing a template component removes its generated task structure on the
next run. Source facts about that identifier are retained. An old manually
asserted task is likewise not deleted. Update 02 continues to consider any
source entity with suitable endpoints, including a retired task whose dates
remain recorded. Task retirement and history are separate lifecycle decisions.

## Temporal generation

Update 02 implements the following relationships. It inserts their inverses
and the `intervalIn` consequences explicitly, which avoids depending on an
inferred-axiom export for these results.

| SWRL result | Condition | Additional inserted result |
|---|---|---|
| `time:before(A,B)` | End of A precedes beginning of B | `time:after(B,A)` |
| `time:intervalOverlaps(A,B)` | start(A) < start(B) < end(A) < end(B) | `intervalOverlappedBy(B,A)` |
| `time:intervalContains(A,B)` | start(A) < start(B), end(B) < end(A) | `intervalDuring(B,A)`, `intervalIn(B,A)` |
| `time:intervalStarts(A,B)` | Same beginning node; end(A) < end(B) | `intervalStartedBy(B,A)`, `intervalIn(A,B)` |
| `time:intervalMeets(A,B)` | A's end node is B's beginning node | `intervalMetBy(B,A)` |
| `time:intervalEquals(A,B)` | Same beginning and end nodes | Both orientations and self-equality follow from matching |

The comparisons read `time:inXSDDateTimeStamp`. That property may carry
`xsd:dateTimeStamp` or `xsd:dateTime` literals in this application, provided
they have explicit UTC offsets. Comparisons bind
`xsd:dateTime(STR(?literal))` and compare the resulting **date-time values**,
not strings. The stored source literal is unchanged. This uses SPARQL 1.1's
standard date-time comparisons without relying on a native `dateTimeStamp`
comparison implementation.

The timestamp filters reject unsupported literal datatypes, unsuccessful
casts, and missing offsets for the comparisons. The endpoint check reports
those issues as well as missing or multiple endpoints, multiple timestamp
literals, and non-positive durations. Treat a nonempty report as data to
resolve before trusting the results. It is a diagnostic, not a full SHACL
profile. Shared-node rules can still match malformed or undated intervals,
just as their SWRL counterparts can.

For valid, fully dated intervals with shared boundary individuals as in the
examples, these reproduce the six revised rules' relationship results.
Specific limits are deliberate:

- Meets, starts, and equals require **the same endpoint RDF node**. Two
  different nodes carrying equal timestamps are not substituted for each
  other. No `owl:sameAs` reasoning is performed.
- Self-equality is retained; the visualization query filters it out.
- The before predicate remains `time:before`, not `time:intervalBefore`.
- No general instant-ordering graph is generated.
- No `intervalFinishes`/`intervalFinishedBy` rule is added in this version.
- All source intervals are compared, including those from different projects.
  Pairwise work can still grow quadratically. There is no incremental cache.
- This is not full OWL entailment. It does not reproduce gist class
  classification, arbitrary domain/range inferences, consistency checking, or
  other conclusions that Pellet might export. Those can be addressed separately.
- Extra deductions from asserted temporal relations without dates, equality
  axioms, or other ontology axioms are outside this endpoint-based calculation.
- The duplicate `gist:actualStartMinute`/`gist:actualEndMinute` values in the
  current example are preserved as source data. Keep them synchronized when
  editing dates; these updates use only the OWL-Time endpoints and timestamps.

## Verification

The supplied local verification checks actual SPARQL execution, seven tasks
and seven goals, stable identifiers on a repeated rebuild, preservation of
source facts, the eight-node/twelve-edge graph, removal of stale relationships
after a date change, timezone-equivalent values, shared-node semantics, a new
unscheduled project, and removal of generated structure after deleting a step.

The original verification also compared update 02 against the uploaded
`W3C Time With SWRL Rules V2 W Infs.ttl`, using the corresponding asserted
`W3C Time With SWRL Rules V2(1).ttl` as input. All **55** triples for the
supported temporal predicates matched exactly: no missing or extra results.
That comparison covers the historical example; the onboarding demo separately
exercises overlaps and equality between distinct tasks. No Pellet run was made.

## Sources

- [Existing process/time walkthrough](https://github.com/mdebellis/Time-Ontology-With-SWRL-Rules/blob/main/Gist_Workflow_and_Time/Process_And_Time_Example.md)
- [gist](https://github.com/semanticarts/gist) — the vocabulary used by the
  example. This bundle does not redistribute the gist ontology.
- [OWL-Time](https://www.w3.org/TR/owl-time/)
- [SPARQL 1.1 Update](https://www.w3.org/TR/sparql11-update/)
- [SPARQL 1.1 Query](https://www.w3.org/TR/sparql11-query/)

The demo's invented person, process, goals, and schedule are adapted from
Michael DeBellis's supplied example. The update design and its limitations
are application choices, not claims about gist's prescribed workflow behavior.
