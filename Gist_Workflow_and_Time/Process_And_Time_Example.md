# Process and Time: An Employee Onboarding Example

This example combines **gist 14.1.0**, **W3C OWL-Time**, and SWRL rules to describe a reusable process, a particular execution of that process, and the temporal relationships between its tasks. The inferred relationships are exported from Protégé, loaded into AllegroGraph, and visualized with Gruff.

The scenario is the onboarding of a fictional employee, Alex Example. It is inspired by the employee-onboarding example in gist's `TaskTemplate` documentation. The specific tasks, goals, participant, and schedule are demonstration data created for this experiment.

The three figures show complementary views:

| Figure | View | Main question |
| --- | --- | --- |
| 1 | Reusable task templates and their ordering | What is the intended process? |
| 2 | A project, its tasks, and their templates | How does this execution relate to the reusable process? |
| 3 | Inferred temporal relationships | How do the actual task intervals relate? |

## Namespaces and files

The ontology IRI is `https://www.in2use.com/In2Use_Process_And_Time_Ontology`.

```turtle
@prefix gist: <https://w3id.org/semanticarts/ns/ontology/gist/> .
@prefix time: <http://www.w3.org/2006/time#> .
@prefix ipt:  <https://www.in2use.com/process-time/> .
```

`gist:` and `time:` retain the upstream vocabulary IRIs. The new example individuals use `ipt:`.

The working ontology is `Process_And_Time.ttl`. It contains the merged ontologies, the SWRL rules, and the asserted example data. An inference export supplies the derived statements used in the temporal graph. The ontology also retains earlier temporal test data; the queries below select the onboarding example.

To render the figures on GitHub, place this Markdown file in the same directory as `GistGraph1.png`, `GistGraph2.png`, and `GistGraph3.png`. The image links are relative to this file.

## 1. Define the reusable process

`ipt:EmployeeOnboardingTemplate` is an individual of `gist:TaskTemplate`. Seven additional task-template individuals describe its component activities. Each component is connected to the overall template by `gist:isPartOf`.

The templates use `gist:precedes` to specify a partial ordering. Several activities can occupy the same stage of the process; they do not have to be arranged in one linear sequence.

![Gruff view of seven onboarding task templates connected by precedes relationships.](GistGraph1.png)

*Figure 1. A view of the reusable onboarding process. All seven activity nodes are task-template individuals.*

The complete ordering asserted in the source is:

| Activity | Activities that must be completed beforehand in this example |
| --- | --- |
| Collect employee information | None |
| Configure accounts | Collect employee information |
| Prepare the computer | Collect employee information |
| Conduct HR orientation | Collect employee information |
| Conduct technical training | Configure accounts; prepare the computer; conduct HR orientation |
| Provide onboarding buddy support | Configure accounts; prepare the computer; conduct HR orientation |
| Complete the onboarding review | Conduct technical training; provide onboarding buddy support |

Here, the intended scheduling convention is that a predecessor finishes no later than its successor starts. `gist:precedes` itself is a generic ordering property: it does not enforce this scheduling constraint. It is transitive, so additional ordering statements can be inferred across multiple steps.

The supplied Figure 1 does not display every dependency in the table. In particular, the HR-orientation and computer-preparation links to training and buddy support are not visible. It also shows an accounts-to-review link consistent with transitive ordering. Treat the image as a view of the graph; the table and Query 1 specify the full reduced ordering for this example. The screenshot alone does not establish why particular links were included or omitted.

## 2. Describe a particular execution

`ipt:AlexOnboardingProject` is an individual of both `gist:Project` and `gist:Task`. Its seven concrete tasks are individuals of `gist:Task`.

The model uses two relationships to connect the execution to the process definition:

| Relationship | Meaning in the example |
| --- | --- |
| `gist:isPartOf` | A concrete task belongs to Alex's project; a step template belongs to the overall process template. |
| `gist:isBasedOn` | A concrete task follows a step template; Alex's project follows the overall onboarding template. |

For example:

```turtle
ipt:AlexConfigureAccounts
    a gist:Task ;
    gist:isPartOf ipt:AlexOnboardingProject ;
    gist:isBasedOn ipt:ConfigureAccountsTemplate .

ipt:ConfigureAccountsTemplate
    a gist:TaskTemplate ;
    gist:isPartOf ipt:EmployeeOnboardingTemplate .

ipt:AlexOnboardingProject
    a gist:Project, gist:Task ;
    gist:isBasedOn ipt:EmployeeOnboardingTemplate .
```

![Gruff view connecting Alex's onboarding project to seven concrete tasks, their corresponding templates, and the overall onboarding template. Blue links mean is based on; green links mean is part of.](GistGraph2.png)

*Figure 2. The project, its component tasks, and the reusable templates on which they are based.*

The concrete tasks appear in green under Gruff's **Historical Event** legend. They remain tasks; their actual-end timestamps also support the inferred `gist:HistoricalEvent` classification. The project is displayed in cyan, and the templates in purple. These are display choices for individuals that can have several RDF types.

The source also gives the templates and tasks goals, represented as `gist:Intention` individuals, and associates Alex with the execution using `gist:hasParticipant`. Those links are outside the views shown here.

The concrete project and task individuals were explicitly created for the example. Linking a task to a template with `gist:isBasedOn` does not itself generate tasks, copy a template's structure, or validate an execution against its ordering.

## 3. Give the execution actual dates and times

The fictional execution takes place on **5 October 2026**, from **09:00 to 17:00**, with an explicit UTC offset of **−07:00**. These are actual timestamps in the example data, rather than planned timestamps.

| Task | Start | End | Individual |
| --- | --- | --- | --- |
| Collect employee information | 09:00 | 09:30 | `ipt:AlexCollectInformation` |
| Configure accounts | 09:30 | 11:00 | `ipt:AlexConfigureAccounts` |
| Prepare the computer | 10:00 | 11:30 | `ipt:AlexPrepareComputer` |
| Conduct HR orientation | 11:30 | 12:30 | `ipt:AlexHROrientation` |
| Conduct technical training | 13:00 | 16:00 | `ipt:AlexTechnicalTraining` |
| Provide onboarding buddy support | 13:00 | 16:00 | `ipt:AlexBuddySupport` |
| Complete the onboarding review | 16:00 | 17:00 | `ipt:AlexFinalReview` |

Each task has a `time:hasBeginning` and a `time:hasEnd` pointing to `time:Instant` individuals. Each instant carries a `time:inXSDDateTimeStamp` value. Equal boundaries reuse the same instant individual in this example.

For example, account configuration begins at 09:30 and ends at 11:00:

```turtle
ipt:AlexConfigureAccounts
    time:hasBeginning ipt:Instant_2026_10_05_0930_PDT ;
    time:hasEnd ipt:Instant_2026_10_05_1100_PDT .

ipt:Instant_2026_10_05_0930_PDT
    a time:Instant ;
    time:inXSDDateTimeStamp
        "2026-10-05T09:30:00-07:00"^^<http://www.w3.org/2001/XMLSchema#dateTimeStamp> .
```

The source also includes matching `gist:actualStartMinute` and `gist:actualEndMinute` values for gist's event model. If a schedule is edited, both representations must be updated; this experiment has no synchronization rule between them.

## 4. Infer relationships between task intervals

The merged ontology adds this axiom:

```turtle
gist:Event rdfs:subClassOf time:ProperInterval .
```

This experiment-specific alignment lets temporal properties apply directly to the task and project individuals. The source also explicitly states `gist:Event rdfs:subClassOf owl:Thing` for the author's preferred Protégé presentation; that assertion is semantically redundant and does not remove the OWL-Time superclass relationship.

The SWRL rules compare timestamped instants, establish their ordering, and use the intervals' boundaries to derive temporal relationships. OWL inverse-property axioms provide corresponding inverse relationships. Figure 3 selects five relationship types to keep the result readable.

![Gruff view of Alex's project and seven tasks connected by interval during, interval equals, interval meets, interval overlaps, and interval starts relationships.](GistGraph3.png)

*Figure 3. Selected temporal relationships visible in AllegroGraph after the inferred axioms were exported from Protégé and loaded into the repository.*

| Example relationship | Explanation from the schedule |
| --- | --- |
| Collect information `time:intervalMeets` Configure accounts | Collection ends exactly when account configuration begins: 09:30. |
| Configure accounts `time:intervalOverlaps` Prepare the computer | 09:30 < 10:00 < 11:00 < 11:30: account configuration starts first, the tasks overlap, and computer preparation ends later. |
| Prepare the computer `time:intervalMeets` HR orientation | Both share the 11:30 boundary. |
| Technical training `time:intervalEquals` Buddy support | Both run from 13:00 to 16:00. |
| Technical training `time:intervalMeets` Final review | Training ends and the review starts at 16:00. Buddy support also meets the review. |
| HR orientation `time:intervalDuring` Onboarding project | Orientation starts after the project starts and ends before the project ends. |
| Collect information `time:intervalStarts` Onboarding project | Both start at 09:00, but information collection ends earlier. |

`time:intervalEquals` expresses equal temporal extent. It does not make training and buddy support the same task. The source explicitly declares the project and its seven tasks to be distinct individuals.

Likewise, Allen's `intervalDuring` is strict: both boundaries are inside the larger interval. Information collection shares the project's start, so its more specific relationship is `intervalStarts`.

The supplied graph displays the expected relationships for this view. It provides evidence that the export-and-load path worked for these results; it is not a claim that the rule set implements every Allen relation.

## 5. Reproduce the Gruff views

1. Load `Process_And_Time.ttl` in Protégé and run the configured reasoner that processes the SWRL rules.
2. Use **Export Inferred Axioms as Ontology**, including inferred object-property assertions. The AllegroGraph repository needs the source assertions as well as the inferred results: include the assertions in the export, or load them separately.
3. Load the resulting RDF into AllegroGraph and open the repository in Gruff. The supplied screenshots show Gruff 9.3.3 with AllegroGraph 9.0.2.
4. In Gruff's Query View, run a query below and choose **Create Visual Graph**. Labels, colors, line styles, and node positions can be adjusted for presentation.

The queries return graphs using `CONSTRUCT`; they do not insert triples into the repository. Queries 1 and 2 use the asserted model. Query 3 reads the temporal conclusions already present in the repository; it does not calculate them from timestamps.

### Query 1: Template ordering

The filter removes ordering links that have an intermediate template. For this example, the result is seven nodes and eleven links. The retained predicate remains `gist:precedes`; the query does not assert `gist:precedesDirectly`.

```sparql
PREFIX gist: <https://w3id.org/semanticarts/ns/ontology/gist/>
PREFIX ipt:  <https://www.in2use.com/process-time/>

CONSTRUCT {
  ?step gist:precedes ?next .
}
WHERE {
  ?step gist:isPartOf ipt:EmployeeOnboardingTemplate ;
        gist:precedes ?next .
  ?next gist:isPartOf ipt:EmployeeOnboardingTemplate .

  FILTER NOT EXISTS {
    ?step gist:precedes ?middle .
    ?middle gist:isPartOf ipt:EmployeeOnboardingTemplate ;
            gist:precedes ?next .
  }
}
```

### Query 2: Project, tasks, and templates

This produces sixteen nodes and twenty-two links for the example.

```sparql
PREFIX gist: <https://w3id.org/semanticarts/ns/ontology/gist/>
PREFIX ipt:  <https://www.in2use.com/process-time/>

CONSTRUCT {
  ?task gist:isPartOf ?project ;
        gist:isBasedOn ?step .
  ?step gist:isPartOf ?process .
  ?project gist:isBasedOn ?process .
}
WHERE {
  VALUES ?project { ipt:AlexOnboardingProject }

  ?project gist:isBasedOn ?process .
  ?task gist:isPartOf ?project ;
        gist:isBasedOn ?step .
  ?step gist:isPartOf ?process .
}
```

### Query 3: Selected Allen relationships

The `gist:isPartOf*` paths include both the project and its component tasks. The filters remove self-links and show temporal equality in only one direction. With the expected inferences, the result is eight nodes and twelve links.

```sparql
PREFIX gist: <https://w3id.org/semanticarts/ns/ontology/gist/>
PREFIX ipt:  <https://www.in2use.com/process-time/>
PREFIX time: <http://www.w3.org/2006/time#>

CONSTRUCT {
  ?a ?relation ?b .
}
WHERE {
  ?a gist:isPartOf* ipt:AlexOnboardingProject .
  ?b gist:isPartOf* ipt:AlexOnboardingProject .

  VALUES ?relation {
    time:intervalMeets
    time:intervalOverlaps
    time:intervalStarts
    time:intervalDuring
    time:intervalEquals
  }

  ?a ?relation ?b .

  FILTER (?a != ?b)
  FILTER (
    ?relation != time:intervalEquals ||
    STR(?a) < STR(?b)
  )
}
```

To include more temporal ordering links, add `time:before` to the `VALUES` block. The current SWRL rule concludes `time:before`, rather than `time:intervalBefore`. This produces a denser view.

## Current scope and limitations

- **Rule coverage:** The source contains seven SWRL rules. There is no rule deriving `time:intervalFinishes` or `time:intervalFinishedBy`. Final review has the dates needed to finish the project, but that conclusion is not supplied by the current rules. It is also outside Query 3's selected predicates.
- **Boundary equality:** The meets, starts, and equals rules reuse an instant variable at shared boundaries. They depend on a shared instant individual or established identity; merely giving two distinct instant individuals equal timestamp values does not establish that identity in these rules.
- **Event/interval alignment:** Treating every `gist:Event` as a `time:ProperInterval` is a local modeling decision. gist's own documentation distinguishes an event from its time interval. The alignment should be reconsidered if the model needs instantaneous events or separate event and interval individuals.
- **Execution support:** This example represents process structure and a dated execution. It does not implement task generation, resource allocation, schedule optimization, or automated checking that an execution satisfies every template dependency.
- **Snapshot maintenance:** An exported inference graph represents the dates and assertions at export time. Changing dates requires refreshing the derived results and removing obsolete conclusions.
- **Scaling:** The instant-ordering rule can generate many pairwise `time:before` statements. Direct timestamp comparisons in SPARQL and AllegroGraph's native temporal query facilities are candidates for a later performance experiment; neither has been benchmarked here.

## Attribution and provenance

This is an independent experimental extension of upstream ontology material.

- **gist 14.1.0:** Developed by [Semantic Arts](https://github.com/semanticarts/gist), distributed under [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/). Preserve upstream credit and notices, identify modifications, retain reused gist terms in their original namespace, and place new terms outside that namespace.
- **OWL-Time:** Based on the [W3C Time Ontology in OWL](https://www.w3.org/TR/owl-time/). The merged source retains W3C/OGC rights and contributor information; those notices should accompany redistributed material.
- **SWRL temporal rules:** Taken from Michael DeBellis's [Time Ontology With SWRL Rules](https://github.com/mdebellis/Time-Ontology-With-SWRL-Rules), as preserved in the merged source.
- **Local modifications and example:** The ontology merges gist and OWL-Time, adds the event-to-proper-interval alignment, and adds the fictional onboarding templates, project, tasks, goals, participant, and timestamps under the In2Use namespace. The screenshots were supplied by Michael DeBellis from his AllegroGraph/Gruff session.

gist's license permits commercial reuse and adaptation subject to its conditions. Association with a commercially published book does not, by itself, require this example to live in a separate repository. Repository-wide licensing should clearly identify the upstream components and preserve their terms.

For further details, see [gist's license](https://github.com/semanticarts/gist/blob/develop/LICENSE.txt), the [CC BY 4.0 license summary](https://creativecommons.org/licenses/by/4.0/), and the [Gruff documentation](https://franz.com/agraph/support/documentation/gruff.html).
