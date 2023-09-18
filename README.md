# Time-Ontology-With-SWRL-Rules
I took the W3C Time ontology and added SWRL rules to implement all the Allen temporal relations. This was all serendipity. A couple weeks ago I wanted to write a little tutorial for Protégé showing people how to create a Customized Tab in Protégé built around the Rules View. One of the reasons to use the Rules view is that it works with rdfs:labels rather than only the IRI's of classes and properties as the SWRLTab does. So I needed an example ontology to extend with some rules that didn't have intuitive IRIs for my example. I had just been looking at the Basic Formal Ontology (BFO) for other work I'm doing and it occureed to me it would be straight forward to use it as an example and to implement some of the Allen temporal relations for my example. That tutorial is here: https://www.michaeldebellis.com/post/creating-a-rules-view-tab

After I created a couple of rules for the tutorial example, it occurred to me that it would be pretty straight forward to write a few more and implement the complete Allen model on top of BFO. That can be found here: https://github.com/mdebellis/BFO-Allen-Model
Then I remembered that I had talked with someone a while ago about writing rules for the Allen relations in the W3C Time Ontology and it was trivial to just copy/paste the rules and test data and make minor revisions based on the different names for the Allen operators in BFO and the Time ontology. I think this ontology models all the Allen operators correctly. The biggest issue is that SWRL will be slow as one gets into hundreds of thousands of Intervals and Instances. 
One thing I would like to do in the future: I've read some papers on taking SWRL rules and transforming them to SPARQL SPIN rules. I was going to write something like that until I saw people had already done it.  I love SWRL but it is too inefficient for most real work. A great way to use it would be to prototype the rules with SWRL and then transform them to SPIN rules once the logic is working for better performance. In the future, I may use this as a test case and see if I can use one of the SWRL->SPIN transformation projects to convert the SWRL rules to SPIN and get acceptable performance. 

9/18/23 Update
It seems that only xsd:dateTimeStamp works for the Time ontology not xsd:dateTime. Unfortunately, the SWRL spec doesn't currently do comparisons on xsd:dateTimeStamp as it does for dateTimes. The odd thing is when I change the rules to look at xsd:dateTimeStamp everything works for the examples I created in this ontology. However, when I load the test data from the Time ontology it doesn't work. My advice for anyone who wants to use this would be just to modify the Time ontology to use xsd:dateTime as well as xsd:dateTimeStamp. The Time ontology used to support xsd:dateTime as well as xsd:dateTimeStamp but the guys who manage the repository decided to take it out. 
