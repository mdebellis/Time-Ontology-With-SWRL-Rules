"""Run the SPARQL demonstration locally: python verify_demo.py.

Requires RDFLib (tested with 7.6.0). This checks the SPARQL files themselves;
it does not require or emulate Pellet or connect to an AllegroGraph server.
"""
from pathlib import Path
from rdflib import Dataset, Namespace, RDF, Literal

HERE = Path(__file__).resolve().parent
G = Namespace('https://www.in2use.com/process-time/graph/')
I = Namespace('https://www.in2use.com/process-time/')
GIST = Namespace('https://w3id.org/semanticarts/ns/ontology/gist/')
T = Namespace('http://www.w3.org/2006/time#')
XSD = Namespace('http://www.w3.org/2001/XMLSchema#')
TASK_UPDATE = (HERE / '01_generate_tasks.ru').read_text()
TIME_UPDATE = (HERE / '02_rebuild_time_relations.ru').read_text()
CHECK = (HERE / '00_check_endpoints.rq').read_text()


def fresh():
    return Dataset().parse(HERE / 'onboarding_demo.trig', format='trig')


def run():
    d = fresh()
    source = d.graph(G.source)
    source_before = set(source)
    assert not list(d.query(CHECK)), 'Unexpected endpoint issues'
    d.update(TASK_UPDATE)
    d.update(TIME_UPDATE)
    tasks = d.graph(G['generated-tasks'])
    temporal = d.graph(G['generated-time'])
    assert len(set(tasks.subjects(RDF.type, GIST.Task))) == 7
    assert len(set(tasks.subjects(RDF.type, GIST.Intention))) == 7
    assert len(list(tasks.triples((None, GIST.precedes, None)))) == 17
    assert len(temporal) == 68
    task_for = {
        template: task
        for task in tasks.subjects(RDF.type, GIST.Task)
        for template in tasks.objects(task, GIST.isBasedOn)
    }
    collect = task_for[I.CollectInformationTemplate]
    accounts = task_for[I.ConfigureAccountsTemplate]
    computer = task_for[I.PrepareComputerTemplate]
    training = task_for[I.TechnicalTrainingTemplate]
    buddy = task_for[I.BuddySupportTemplate]
    final = task_for[I.FinalReviewTemplate]
    assert (collect, T.intervalMeets, accounts) in temporal
    assert (accounts, T.intervalOverlaps, computer) in temporal
    assert (training, T.intervalEquals, buddy) in temporal
    assert (buddy, T.intervalEquals, training) in temporal
    assert (final, T.intervalFinishes, I.AlexOnboardingProject) not in temporal
    # The user-facing graph query reproduces the expected Figure 3 view.
    view = d.query((HERE / '03_view_temporal_relations.rq').read_text()).graph
    assert len(view) == 12
    assert len(set(view.subjects()) | set(view.objects())) == 8
    # Rebuilding must preserve identities and leave the source untouched.
    first_tasks, first_time = set(tasks), set(temporal)
    d.update(TASK_UPDATE)
    d.update(TIME_UPDATE)
    assert set(tasks) == first_tasks and set(temporal) == first_time
    assert set(source) == source_before
    print('PASS: seven tasks, seven goals, stable rebuild, source unchanged')
    print('PASS: 68 temporal triples; Figure 3 has eight nodes and twelve edges')
    # Shorten the account task. Its overlap must disappear in BOTH directions.
    changed_end = I.Instant_2026_10_05_1100_PDT
    source.set((changed_end, T.inXSDDateTimeStamp,
                Literal('2026-10-05T09:45:00-07:00', datatype=XSD.dateTimeStamp)))
    source.set((accounts, GIST.actualEndMinute,
                Literal('2026-10-05T09:45:00-07:00', datatype=XSD.dateTime)))
    d.update(TIME_UPDATE)
    assert (accounts, T.intervalOverlaps, computer) not in temporal
    assert (computer, T.intervalOverlappedBy, accounts) not in temporal
    assert (accounts, T.before, computer) in temporal
    assert (computer, T.after, accounts) in temporal
    print('PASS: changed date removes stale overlap and creates before/after')
    # Equivalent timezone representation must not change computed ordering.
    source.set((changed_end, T.inXSDDateTimeStamp,
                Literal('2026-10-05T16:45:00Z', datatype=XSD.dateTime)))
    before_offset_change = set(temporal)
    d.update(TIME_UPDATE)
    assert set(temporal) == before_offset_change
    print('PASS: dateTime/dateTimeStamp and equivalent UTC offsets')
    # Shared-node semantics are deliberate: an equal-valued new boundary
    # does not stand in for the shared individual in the meets rule.
    source.set((accounts, T.hasBeginning, I.DistinctBoundaryForTest))
    source.add((I.DistinctBoundaryForTest, T.inXSDDateTimeStamp,
                Literal('2026-10-05T09:30:00-07:00', datatype=XSD.dateTimeStamp)))
    d.update(TIME_UPDATE)
    assert (collect, T.intervalMeets, accounts) not in temporal
    print('PASS: shared-node equality semantics retained')
    # A new project produces tasks without fabricating schedule information.
    source.add((I.UnscheduledProject, RDF.type, GIST.Project))
    source.add((I.UnscheduledProject, GIST.isBasedOn, I.EmployeeOnboardingTemplate))
    d.update(TASK_UPDATE)
    new_tasks = set(tasks.subjects(GIST.isPartOf, I.UnscheduledProject))
    assert len(new_tasks) == 7
    assert not any(list(source.objects(t, T.hasBeginning)) for t in new_tasks)
    assert not list(tasks.triples((None, T.hasBeginning, None)))
    print('PASS: new project generates seven tasks without inventing dates')
    # Removal of a reusable step retracts its generated structure. Assertions
    # about the retired task, such as measurements, remain in the source.
    source.remove((I.BuddySupportTemplate, GIST.isPartOf, I.EmployeeOnboardingTemplate))
    d.update(TASK_UPDATE)
    assert len(set(tasks.subjects(RDF.type, GIST.Task))) == 12
    assert not list(tasks.triples((buddy, None, None)))
    assert list(source.objects(buddy, T.hasBeginning))
    print('PASS: removed step retracts generated structure, preserves source facts')
    # Ensure the diagnostic query reports a missing endpoint and no offset.
    source.remove((accounts, T.hasEnd, None))
    source.set((I.DistinctBoundaryForTest, T.inXSDDateTimeStamp,
                Literal('2026-10-05T09:30:00', datatype=XSD.dateTime)))
    issues = {(row.interval, str(row.issue)) for row in d.query(CHECK)}
    assert (accounts, 'Missing end') in issues
    assert (accounts, 'Invalid/unsupported timestamp or missing UTC offset') in issues
    print('PASS: endpoint diagnostic detects missing data and timezone offsets')


if __name__ == '__main__':
    run()
