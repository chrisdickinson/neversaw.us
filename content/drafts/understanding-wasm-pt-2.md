+++
title = "understanding wasm pt 2: a problem statement"
slug = "understanding-wasm-pt-2"
date = 2023-05-06
updated = 2023-05-06

[extra]
toc = true
+++

# understanding wasm

## part 2: a problem statement

In the last post, we asked a series of questions about WASM. To recap:

- Where did WASM come from -- what problems was it created to solve?
- How did WASM come to be developed and supported by multiple vendors, while
  the JVM remained single-vendor?
- Are WASM and the JVM really the same type of thing?
- What does "virtual machine" mean?

We ended up doing a bit of definitional legwork around virtualization in the
last post. We built up these terms because WebAssembly bills itself as a
"virtual instruction set architecture". [Dan Gohman][dan-gohman-kinda] and
[Yoshua Wuyts][yosh-wasi] have written about what this means, but the common
thread is that WebAssembly defies categorization: what it _is_ depends on your
point of view.

I am going to take an overbroad angle on this: **what problem motivated the creation of WASM?**

The categorical ambiguity of WebAssembly makes it difficult to answer this
question succinctly. Did we need better security? Yes. A more efficient
virtualization format? Yes. A late-bound abstraction over multiple machine
architectures? Yes.

And WASM provides all of those things.

But, rather than embracing the kinda, I'm going to squeeze some blood out of
this here rock: why did we need all of these things in the first place?

We need better security because we need to be able to run other people's
software without having to trust them. We need to be able to run other people's
software without trusting them because they are using that software to a
service. We want smaller virtualization formats so that we can run more
software on a single piece of hardware. We want abstraction over machine
architectures because we don't know what architecture other people's software
was written against.

In other words: we back into computing history, in particular the history of
_personal_ computing. Who should have computers? Who should write software? How
do we distribute that software? How do we make a living from that software? Who
decided all of this?

[<img width="100%" alt="talking heads: once in a lifetime" src="https://i.ytimg.com/vi/5IsSpAOD6K8/hqdefault.jpg?sqp=-oaymwEmCOADEOgC8quKqQMa8AEB-AH-BIAC4AOKAgwIABABGFsgRChlMA8=&rs=AOn4CLBBv8sjsAldTge-5NtfbyXor5QKkA" />](https://www.youtube.com/watch?v=5IsSpAOD6K8)
<sup>and you may ask yourself, "How did I get here?"</sup>

---

## the short version

I provide the short version [here](#tldr).

---

## the long version

### A quick disclaimer

Despite this being "the long version", I'm really only walking down the library
stacks, gesturing at a few classics as they relate to the topic at hand.

You can find out more from these primary sources, which I encourage you to check
out if any of this history lights a spark in you:

- ["Mindstorms"][papert-mindstorms] by Simon Papert
- ["The Early History of Smalltalk"][early-history] by Alan Kay
- ["Design Principles of Smalltalk"][design-smalltalk] by Daniel H. H. Ingalls
- ["The Rise and Fall of Commercial Smalltalk"][commercial-smalltalk] by Allen Wirfs-Brock
- ["Learnable Programming"][learnable-programming] by Bret Victor

These sources are both more accurate and more complete. I struggled with how
much to include in this essay, but my hope is to link these essays together in
a way that fleshes out the context around where we are now, today, with
WebAssembly.

Our problem statement is multipart, layered. At the very root of it is _"Who
should have computers>?"_ Nothing about the phones in our hands, laptops on our
desktops, servers in our clouds, nor the software that runs on them was
inevitable. They were born out of a specific vision of **personal computing**
motivated by pressing need.

The audience for computing was _much smaller_ in the early 60's, where our
story starts.

### The Sixties {.clearfix}

We start with [Douglas Engelbart][engelbart].

Engelbart has been described as "a prophet of Biblical dimensions". He devoted
his life's work towards the goal of augmenting humanity through computing,
inspired by [a 1945 essay by Vannevar Bush][as-we-may-think]. As we'll see, his
ideas cast a long shadow.

<aside>

### Moore's law

In 1960, Engelbart traveled to the University of Philadelphia to speak about
recent studies on the scaling rate of integrated circuits. 

Gordon Moore was in attendance. Moore would go on to become famous in 1965 for
[stating "Moore's law"][moores-law]: the number of transistors in an integrated
circuit doubled roughly every two years.

</aside>

In 1967, Engelbart traveled to the University of Utah to give a lecture, which
a young Alan Kay attended. Engelbart, who would later give ["The Mother of All
Demos"][moad] in 1968, was there to talk about hypermedia. He described
hypermedia as "thought vectors in concept space"; we might recognize it as
traversable linked documents with embedded media. His demo: the oNLine System
("NLS"). This machine included "graphics, multiple panes, efficient navigation
and command input, interactive collaborative work, etc." The ultimate goal was
to augment the human mind. It was a peak into a future that would not arrive
for decades.

> The impact of [Engelbart's] vision was to produce in the minds of those who
> were "eager to be augmented" a compelling metaphor of what interactive
> computing should be like, and I immediately adopted many of the ideas for the
> FLEX machine.
>
> Kay, "The Early History of Smalltalk"

This talk set a fire in Kay, who saw the future clearly -- at least, a
_possible_ future. Kay grasped the implications of what hypermedia and Moore's
law held for the computer industry as it has existed up until that point.
Contemporaneous application development tools sufficed for the thousands of
extant mainframes, but were too brittle to service this new, diverse audience
of users. It was clear to Kay: "personal computing" was the future. Personal
computers supporting hypermedia would become -- must become -- ubiquitous; a
new universal tool to augment the human mind.

> \[M]illions of potential users meant that the user interface would have to
> become a learning environment along the lines of Montessori and Bruner\[.]

However, in 1970, ARPA funding for personal computing research in academia
dried up. [The Mansfield amendment to the 1970 Military Authorization
Act][mansfield] prohibited funding research that lacked a direct military
application. An exodus from academia occurred. Kay landed at Xerox, which was
building a nascent computer science research division at the Palo Alto Research
Center ("Xerox PARC"). Here Kay formed the "Language Research Group" ("LRG").
Kay staffed this group based on "who had sparkles in their eyes" when he
described the vision[^vision] for the future of personal computing: the
Dynabook. The Dynabook was to be the ultimate manifestation of Engelbart's
hypermedia NLS: a computer for every person, starting at childhood.

<img src="/img/dynabook.png" width="100%" alt="a drawing of a two children using tablet computers with embedded keyboards" />

Xerox PARC would be the place that Engelbart's acolytes would first try to
bring personal computers to market.

At this point in time, if you bought hardware, you were probably a large
institution (a bank, a university, a government office.) You probably also
contracted for specific software to run on that hardware. Time-sharing had
only been invented mid-decade, in 1965!

### The Seventies

#### Smalltalk

A computer, however, is nothing without software to operate it.

It's within the aformentioned Language Research Group that Smalltalk[^naming]
was born. Smalltalk was motivated by the search for a core metaphor that would
be easy to learn, universal, and unreasonably powerful.

<aside class="right">

> [LISP] started a line of thought that said "take the hardest and most profound
> thing you need to do, make it great, and then build every easier thing out of
> it". That was the promise of LISP and the lure of lambda—needed was a better
> "hardest and most profound" thing. Objects should be it.
>
> - Alan Kay, "The Early History of Smalltalk"

</aside>

Although Kay drew inspiration from LISP, he was unhappy with the barnacles that
it had accrued over the years. He felt that the various concessions to
practicality confused LISP's core metaphor[^kay-lisp]. At the same time, he was
inspired by a long line of predecessor technology (including the CAL-TSS) that
worked toward the object metaphor, but stopped short of embracing it
universally.

<aside class="left">

> **Uniform Metaphor:** A language should be designed around a powerful metaphor
> that can be uniformly applied in all areas. 
>
> - Dan Ingalls, "Design Principles of Smalltalk"

</aside>

Smalltalk's core metaphor was that of "communicating objects". That is, Smalltalk would
model the computer as containing an nigh-infinite regress of smaller computers,
represented as "objects." Each object was "equally powerful" to the whole
computer[^on-power]. Objects were to communicate with each other by passing
messages. Objects could react as they chose to any message they received,
including those they did not understand ahead of time. The theory was that
programmers would take the role of the object they were currently editing
(called `self`) and, from that frame, accomplish their higher-level "goals" by
orchestrating messages to related objects.

<aside class="right">

> The basic principle of recursive design is to make the parts have the same
> power as the whole.
>
> - Bob Barton

</aside>

Today, we might understand the original conception of objects better as
services, a sort of distributed system within a single computer[^erlang].

<aside class="left">

> The purpose of the Smalltalk project is to provide computer support for the
> creative spirit in everyone. [...] If a system is to serve the creative
> spirit, it must be entirely comprehensible to a single individual.
>
> - Dan Ingalls, "Design Principles of Smalltalk"

</aside>

The language was designed to be taught. Owing to the original target audience
of the Dynabook, it was especially interested in being accessible to children.
It drew inspiration from Simula[^simula], LOGO, and LISP.

![Smalltalk-80 GUI](https://computerhistory.org/wp-content/uploads/2020/12/Smalltalk-80-GUI.jpg "Smalltalk 80 GUI")
<sup>via the <a href="https://www.computerhistory.org/revolution/input-output/14/347/1859">Computer History Museum</a></sup>

<aside class="left">

For more info on the Smalltalk environment, check out [Ken Shirriff's blog](http://www.righto.com/2017/10/the-xerox-alto-smalltalk-and-rewriting.html).

</aside>

This happened against the background of a Cambrian explosion of computing
systems. Metaphors we now view as commonplace -- like hierarchical file systems
and processes -- were still in flux. Smalltalk programs are usually distributed
as "images" of object graphs; single files that capture the state of the live
system. To modify a program, you would run the image and make your
modifications from within the running system. This is bizarre to contemplate
from the modern programming frame of files-in-version-control. However, much of
modern computing -- both programming and user experience -- is owed to
Smalltalk, which developed overlapping windows, menus, popovers, integrated
development enviroments ("IDE"), unit testing, and software testing, among
other patterns.

<aside class="left">

### A Brief Aside on Modularity

At this point in the history of programming, the field had begun grappling with
how to work together effectively on large programs. This is a sub-problem of
"who writes software" that asks "and how do they write it together?" Is there
a way that they can approach problems that minimizes the cost of future changes?

In 1972, concurrent with the events I describe within the Language Research
Group, D.L. Parnas published a paper, ["On the Criteria To Be Used in
Decomposing Systems into Modules"][parnas].

It continues to be relevant today!

</aside>

Most importantly for the story we're following: Smalltalk objects
as-implemented were goal-driven, designed to snap together modularly like LEGO
or an Erector set. The entire system was built out of objects -- there was no
"operating system", at least from a certain point of view. Smalltalk objects
were endlessly _recomposable_, as [Bret Victor would later put it][learnable-programming].

However, the LRG uncovered problems while doing user research in 1974: while the
participants were perfectly capable of being taught to read and write Smalltalk
code in the course of a day, they were unable to take that knowledge and apply
it towards higher level goals. Kay looked into why that gap proved so hard to
cross:

> Finally, I counted the number of nonobvious ideas in this little program.
> They came to 17. And some of them were like the concept of the arch in
> building design: very hard to discover, if you don't already know them. 
>
> The connection to literacy was painfully clear. It isn't enough to just learn
> to read and write. There is also a literature that renders ideas. Language is
> used to read and write about them, but at some point the organization of
> ideas starts to dominate mere language abilities.

<aside>

### Towards Programming Literacy

Adele Goldberg struck on the idea of "design templates" to address this gap:
the idea of providing Smalltalk students paper templates to describe objects &
their methods. A completed template held a table with three columns per row:
the first column described a message the object may receive, the second column
held a plain English description of what action would be carried out, and the
third column held Smalltalk code written to achieve the English desription of
the action. These could be handed out in varying states of completion to
students [^goldberg-p-22].

[<img src="/img/smalltalk-design-template.png" width="100%" alt="an image of a smalltalk design template" />][teaching-smalltalk]

</aside>

Xerox PARC had yet to ship the Dynabook. Indeed, the first personal computers
(at least, the first ones "worth criticizing", quoth Kay) would be released by
Apple. 

We're going to leave Xerox PARC in 1979, with Apple's fabled Promethean visit.

Apple, in fact, made two visits. First they got the "sanitized" demonstration
of Xerox PARC's Smalltalk tooling, then they got the "classified"
demonstration, courtesy of Xerox's investment in Apple. The Language Research
Group itself was having trouble getting traction within Xerox to bring their
innovations to market; Apple meanwhile was looking for confirmation on their
existing product direction with the LISA and Macintosh[^pirates].

The demo was a resounding success[^demo].

The Apple LISA would be released in 1983, followed by the Macintosh in 1984.
Microsoft released the first version of Windows in 1985.

At this point in time, if you bought hardware, you were more-or-less expected
to be able to write your own software for it.

### The Eighties {.clearfix}

#### Hypercard; How Do We Teach Our Customers to Program?

Consumers were broadly adopting PCs. Now the industry was starting to grapple
with how they'd get software for their computers. While Smalltalk had some
success in pedagogy, it fell far short of the universal literacy it had aimed
for: it didn't seem likely that everyone with a computer would produce their
own software, or would even wish to modify it. The machines available were
either too expensive or too slow; it faltered trying to find its footing.
Smalltalk wouldn't be viable on affordable hardware until 1985.

A new approach was needed for consumer software, which had now bifrucated
wholly from "enterprise" software run by companies. There were two approaches
to consumer software: the personal computer as an appliance, and the personal
computer as a supermarket. Apple pioneered the former, Microsoft thrived in the
latter.

We now focus on Apple's HyperCard, a "software erector set."

<iframe src="https://archive.org/embed/CC501_hypercard" width="640" height="480" frameborder="0" webkitallowfullscreen="true" mozallowfullscreen="true" allowfullscreen></iframe>

HyperCard was directly inspired by Smalltalk & Engelbart's hypermedia. Bill
Atkinson, the primary developer of HyperCard, had taken part in PARC's
"Smalltalk in the classroom" courses as a child in the 1970's[^bill-70s]. (&
Alan Kay, in fact, advised on the HyperCard project![^modifiable]) It was a
streamlining of the object-oriented concept of SmallTalk for a consumer
market: instead of generic objects, HyperCard used a virtual stack of index
cards as its core metaphor. Text, graphics, and buttons could be laid out on
the index cards.

A HyperCard button could link to another card, play sounds, trigger a
transition -- all powered by a scripting language, "HyperTalk", embedded in the
button.

<div id="hypercard-bits" style="flex-direction: row; display: flex; width: 100%">
<style>#hypercard-bits > * { flex-grow: 1; flex-basis: 33%; flex-shrink: 0; padding-right: 1%; }</style>

[<img src="/img/hypercard-0.png" width="100%" alt="an image of hypercard" />](/img/hypercard-0.png)

[<img src="/img/hypercard-1.png" width="100%" alt="an image of hypercard" />](/img/hypercard-1.png)

[<img src="/img/hypercard-2.png" width="100%" alt="an image of hypercard" />](/img/hypercard-2.png)

</div>

<sup>via the <a href="https://archive.org/details/AppleMacintoshSystem753">Internet Archive</a> (You can run HyperCard in your browser!)</sup>

As opposed to Smalltalk, the software was modal -- given a "stack"
someone shared with you, you could choose to either "play" the stack or edit
the stack. Each had a distinct interface [^modality-note]. The software came
with a user guide, itself written as a HyperCard stack. This guide gave
interested users a handy, referencable corpus of design patterns to kickstart
their own literacy with the program.

HyperCard widgets -- buttons, cards, and stacks -- were designed to be
recomposable. If you liked an effect or some information from a stack someone
handed you, you were free to embed it wholesale into your own stack via copy
and paste. Or, if you were interested, you could edit their stack and see how
they accomplished the effect in order to reproduce it yourself[^goldberg-quote].

Hypercard stacks were confined to a single computer. They couldn't link across
machines. Still, HyperCard was distributed with every Macintosh, giving it a
built-in audience (albeit one tied to the popularity of the Mac.)

#### OLE: Forget Teaching -- Let's Sell Some Software

Microsoft, on the other hand, pushed a "supermarket" approach to software
distribution. You could purchase your computer hardware from compatible
vendors, then purchase an operating system and some programs to run on it.
(While you could buy software for an Apple computer, it arrived with usable
software -- including an operating system -- out of the box.) The Mac waned in
popularity in the mid-to-late 80's and early 90's in favor of Microsoft's
Windows PC products. 

Microsoft perfected a much different solution to the problem of distributing
software: software was a one-time purchase. You buy a toaster, you plug it in,
and it makes toast for you. It makes toast until it breaks (or you find
yourself in want of a four-slot toaster.)

Instead of working through a universally-digestible LEGO metaphor to unlock the
potential of computing, the customer could simply drive to the store, pick up a
box containing some floppy disks, and open their wallet. This usefully
constrained the problem that Microsoft's operating system had to solve: instead
of navigating consumers through the jellyfish-like adaptability of Smalltalk,
Microsoft could sell interchangable parts that conformed to a more rigid,
cellular modularity.

{{ youtube(id="KxaCOHT0pmI") }}

- talk about: windows pcs a bit
  - we just talked about two integrated systems for building software, but they're failing
    to reach the consumer market
  - we want to differentiate how microsoft is working
    - C-based interface, "object oriented" C apis, COM, OLE, DDE -- starting to make their
      operating system and applications extensible through plugins
    - this is a giant pain for consumers (DLL hell)
  - here is the goal:
    - they were on a path to extensibility using native libraries with the expectation that you
      would buy and sell them
    - they started down the road to blackbird
    - sun and netscape scooped them: sun on the server side, netscape on the client side

<aside class="left">

> Beau Shiel likens software constructed in traditional (i.e. structured) ways to
> dinosaurs, whose rigid skeletal structure resists adaptation.  He compares
> exploratory programming systems (like Smalltalk-80 and Interlisp-D) to
> jellyfish, noting their fluidity and pointing out that even jellyfish have
> their ecological niche.
>
> [...]
>
> Unfortunately, while a jellyfish will assume the shape of its container, you
> can't build a bridge with them. 
>
> Tony Williams, ["On Inheritance: What it Means and How To Use it"][on-inheritance], 1990

</aside>

TKTK talk about the PC and C++ separately

Software re-use through shared libraries was experiencing a renaissance within
Windows at the time. "Object-oriented programming" was catching on in
popularity through another Simula-derived language, C++ (itself built on top of
the C language.) C++ disagreed with Smalltalk on what "object-oriented" meant.

Where Smalltalk devolved power onto objects by letting them intercept and
handle any kind of message, C++ opted for a more rigid approach: messages were
represented by methods on a class. C++ classes formed a closed set of methods
available, and unknown method invocation was treated as an error at
compile-time.

<aside>

### DDE, COM, OLE, and ActiveX

TKTK differentiate COM, OLE, DDE, and ActiveX. Talk about what they are.

</aside>

 TKTK: expand on this, why was this important to computing at the time? In a memo foundational to the Component Object Model
("COM") and Object Linking and Embedding ("OLE") specs that were to come,
Antony William wrote:

> In World War II Barnes Wallis designed an aircraft (the Wellington bomber)
> for resilience to a particularly hostile form of change: the removal of
> potentially large, particularly unpredictable parts by means of high
> explosives.  These aircraft were highly popular with their aircrews because
> of their ability to fly home with massive damage.
> 
> The key to this ability was the decentralization of the strength of the
> aircraft structure, away  from a rigid airframe (or skeleton) into a cellular
> shell inside the skin. The rigidity was moved down a level of granularity.
> into the cell structures, not discarded in favour of a bag full of helium.
>
> Tony Williams, ["On Inheritance: What it Means and How To Use it"][on-inheritance], 1990

COM and OLE were motivated by the ability to _embed_ content or functionality
from one application into another: graphics, audio, text, spreadsheets,
presentations, etc. OLE enabled Microsoft Word to embed a spreadsheet from
Microsoft Excel -- a compelling feature at the time! It was Engelbart's hypermedia -- this time as a product feature.

### The Nineties

#### The Internet Era; What Happens if You Don't Have to Buy Software to Run It?

In the early 90's, the first web browsers started showing up on the scene.  The web was another modal interface: one could
browse[^or-surf] the web or use their favorite text editor to author hypertext
markup language documents. Navigating links between pages formed very basic --
but unbounded -- HyperCard-like "stacks" of page history.

<aside>

### The influence of HyperCard

One early browser, ViolaWWW, explicitly credited HyperCard on its home page!

</aside>

Most websites were static at this point: HTTP dovetailed nicely with the
hierarchical filesystem metaphor popularized by UNIX in the preceding decade.
The static nature of the web was changing rapidly, however: NeXT Computer,
Microsoft, and Sun Microsystems were all invested in dynamically
generating HTML documents on request.

Microsoft, in particular, was not happy that an "open" standard stood to eat
into the profits they saw from selling software and software creation
accessories. They were [actively working][blackbird-announce] on an
OLE/ActiveX-based web replacement -- called [Project Blackbird][blackbird] --
up until Netscape released the first version of Netscape Navigator in 1994,
taking the world by storm.

[blackbird-announce]: https://ftp.zx.net.nz/pub/archive/ftp.microsoft.com/developr/drg/Multimedia/Blackbird/BBPR.htm

<iframe frameborder="0" scrolling="no" style="border:0px" src="https://books.google.com/books?id=0joEAAAAMBAJ&lpg=PP1&pg=PA35&output=embed" width=640 height=500></iframe>

Sun and Netscape joined forces to combat Microsoft -- Netscape offered Sun a
venue to push its Java language, while Sun's strong server story gave
Netscape's Navigator a richer web to visit. To complete the product story, Sun
and Netscape collaborated on an in-browser language to fill the role that
Visual Basic performed for the Microsoft ecosystem. This language niche was to
be filled by JavaScript. JavaScript was written to look superficially like
Java, but was influenced primarily by Self, Scheme, HyperTalk, and Logo.
JavaScript could wire together Java-applet-containing `<object>` tags, powered
by the Netscape Plugin API ("NPAPI".) NPAPI would allow websites to execute
dynamically-linked plugins, running directly on the user's machine as shared
libraries.

Netscape would sell browsers, Sun would sell servers. The internet would be
programmed in Java. The vision was that one could write an applet in Java and
deploy it anywhere.

<iframe frameborder="0" scrolling="no" style="border:0px" src="https://books.google.com/books?id=WTgEAAAAMBAJ&lpg=PP1&pg=PA6&output=embed" width=640 height=500></iframe>

<aside class="left">

### What happened to Smalltalk?

Allen Wirfs-Brock covers this era in ["The Rise and Fall of Commercial Smalltalk"][commercial-smalltalk].

Particularly relevant to our interests is [Self][the-influence-of-self], a
successor language often called "Smalltalk, only moreso". Self's VM invented
novel just-in-time compilation techniques (["hidden classes"][mraleph-hidden]
and ["polymorphic inline caches"][mraleph-pic].) Two engineers involved in the
Self compiler, Lars Bak and Urs Hölzle, founded Animorphic Systems alongside
Dave Griswold to bring Self's advances back to Smalltalk as
["Strongtalk"][strongtalk].

But all of these efforts would be consumed by Java, Sun's programming language
meant to push a universal object oriented programming language. Gilad Bracha, a
co-author of the original Self paper, notes in ["Bits of History, Words of
Advice"][smalltalk-bits]:

> [...] ParcPlace declined an offer from Sun Microsystems to allow ParcPlace
> Smalltalk to be distributed on Sun workstations. Sun would pay a per machine
> license fee, but it was nowhere near what ParcPlace was used to charging.

Sun acquired Animorphic Systems in 1997 and put the StrongTalk team to work on
optimizing Java. Years later, in 2008, Lars Bak would come to work at Google on
an optimizing compiler for JavaScript.

</aside>

Microsoft was caught wrong-footed. Microsoft had tried (and failed) to acquire
Netscape in early 1994. Project Blackbird would not ship until 1996 at the
latest; far too late to counter Sun and Netscape's efforts. The alarm reached
the top of the company. Bill Gates issued a memo in May 1995 that would
dramatically change [the company's approach][gates-tidal-wave] to internet
technologies, having reached a deal to license SpyGlass MOSAIC's technology
for use in Windows earlier that year.

Microsoft punched back at Netscape and Sun by packaging their browser, Internet
Explorer, in Windows for no additional cost. They even presented a NPAPI
interface through an ActiveX shim, embracing and extending the embedding API
with their own proprietary technology. Netscape no longer had a product. This
earned Microsoft an anti-trust case that it ended up losing (though Gates
propped up Apple, then verging on bankruptcy, in order to have a competitor to
point to.) In very short order, Microsoft had won the browser war.

Java reigned surpreme as enterprise server technology. Browsers stagnated:
browser technology didn't advance much in the late 90's. Where advances
occurred, they occurred within the context of NPAPI: plugins rose to dominance.
(This is perhaps unsurprising given the fascination with shared libraries in
the 1990s!) However, despite the push to entrench Java as the language of the
web, slow startup times and poor UI integration meant that another plugin rose
to prominence: Flash.

### The Aughts

#### The Mobile Era, The Rise and Fall of Flash

The 00's saw a great changing of the guard: Sun Microsystems went defunct,
Microsoft faltered while Apple dominated. Amazon and Google rose to prominence.
At the start of the aughts, the industry reckoned with the nature of their
market: how do we sell software? The disks-in-a-box model failed to capture
the ongoing cost of support and development. One could sell upgrades, sure,
but not every new release was sure to attract users (looking at you, Windows ME.)

This decade saw the rise of the engagement market and "software as a service."

So, what happened?

---

Let's talk about soundness for a second. The machine architectures we used (and
still use) were of a class of architectures called "von Neumann" machines.
These machines have the useful property that code is data and data is code:
that is, a program may map a page of memory as "executable", write new program
code to it, and transfer control to it. This enables a number of important
patterns, like just-in-time compilation. However, it comes with a downside: if
a program is unsound, a malicious user may write their _own_ program into a bit
of memory and transfer control to it. The malicious user's program now has the
same level of access to the machine as the original program.

This was the fundamental flaw with NPAPI, with plugins. They allowed the web to
advance during that Microsoft-instigated winter of browser stagnation, but at
the cost of security. The language family, C, used to write plugins hailed from
a time before the concept of anonymous, malicious users -- when access to
machines was more closely controlled and traceable to users.

Flash and ActiveX had bugs.

The market was moving away from the concept of "computer ownership" as a sort
of expert activity. After all, if every person was to have their own personal
computer, it was not reasonable to expect every person to become an expert in
maintaining that computer.

Apple announced the iPhone in 2007. Not only would everyone have a computer, it
would fit in your pocket. Safer technology was needed.

---

html5, js

---

Themes:
  - the dotcom bust: how do we sell technology?
  - enterprise technology replaced with "consumer" technology: a shift from java to ruby on rails, python, javascript
  - hardware virtualization lead to the creation of clouds
  - ajax restarts the browser wars
  - google buys doubleclick, facebook launches: the engagement economy starts

- the aftermath
  - java wasn't particularly interested in interoperating with the web browser, it wished to replace it
  - but it integrated poorly: slow startup time, bad interactivity with other browser controls, non-native ui
  - flash fared a lot better: it was another modal editing environment, this time based around postscript and (a variant of) javascript called actionscript


The problem with Plugins: despite the fact that the API was hardened, they were
run as dynamically linked libraries. If they had any soundness issues, they could
be used to take control of a user's computer. TKTK what is a soundness issue?

JavaScript and HTML stagnated for years. Progress appeared via Flash (TKTK PostScript, history of Flash in aside?). Flash was
a modal editing interface but was not sandboxed and was not particularly
efficient. google appeared. ActiveX sewed seeds of own demise via `new
ActiveXObject('Microsoft.XMLHTTP')` and XHR. Gmail, maps. The first web apps.
oembed. Apple, google, mozilla collaborated on HTML5. The iphone. JS resurgent.

Google releases chrome. Innovations in Self & the smalltalk vm come back to JS. Apple
kills flash by not allowing it on the iphone. Fast JS VMs become ubiquitous. Google buys doubleclick in 2007.

<details>

<summary>The stuff I'm glossing over...</summary>

- Hardware Virtualization Support
- cgroups in linux in 08
- slicehost, linode, AWS
- Heroku '07
- oEmbed
- netflix microservices in '10

</details>

### The Teens

#### A Ubiquitous Virtual Machine, Sandboxing, and Containerization

The era of good (javascript) feelings. Google tries to kill JS with Dart, NaCl,
and PPAPI. (It's not good for programming in the large.) lljs. asm.js. The
unreal demo. Extracting a useful abstract machine from existing virtual
machines, as C did in the late 70s. WASM. Microservices resurgent.

<details>

<summary>The stuff I'm glossing over...</summary>

- Walled gardens and social media
- Docker
- Kubernetes

</details>

### The Twenties

#### TL;DR {#tldr}

Here. Now.

WASM is hard to define because it represents the joining of a lot of stories that
split in the eighties and nineties:

- The path from computing as a good to computing as a service
- The path from a single "software development" audience, to a discrete "enterprise" and "consumer" audiences, back to a single audience
- The path from software and hardware being maintained together to hardware as a consumable resource for software

WebAssembly is a new narrow waist between code and computing substrate: a
contract through which any software can be computed safely alongside any other
software, on nearly any substrate. It's a late reaction to the shift from
"software as a good" to "software as a service": something which needs to be
continually updated across a massive distribution network.

---

<!-- md citations / footnotes -->
[^vision]: I want to call out that a shared vision is the most effective way I've seen to
  build a productive team. Not only does it set stakes for values going into the organization,
  but it builds trust by freeing leadership from making specific technical decisions -- as Kay
  puts it, whenever he didn't have an answer for a technical question, he could point at the
  vision of the Dynabook and say "do whatever gets us closer to that."

[^naming]: I note this because it appealed to my sense of humor, but the name
  Smalltalk -- as in, "programming should be a matter of ..." was a direct
  reaction to "indo-european god" naming conventions at the time. That is,
  "Zeus", "Thor", etc -- all promised the world but delivered very little. Kay
  figured that "if a language named Smalltalk did anything useful, people would
  be pleasantly surprised."

[^kay-lisp]: (in particular around EXPRs vs FEXPRs and special constructions
  that betrayed the "everything is a function" metaphor.)

[^on-power]: "Equally powerful" in the sense that they are "equally capable",
  or have "equal control."

[^erlang]: You might think, as I did, that this sounds a _lot like_ Erlang. Indeed,
  Joe Armstrong [had some exposure][erlang-history] to Smalltalk (see §3.1); but he
  appeared to have lost interest in Smalltalk in favor of Prolog. He also observes
  that the garbage collection process was painfully slow.

[^simula]: Simula would also inspire C++. FORESHADOWING.

[^goldberg-p-22]: See page 22 of ["Teaching Smalltalk"][teaching-smalltalk].

[^pirates]: [From everything I could gather][not-pirates], it was a much less
  dramatic affair than is [commonly told][pirates]. The excitement sprang from
  a confirmation of shared vision & a realization of the potential of object
  oriented software and hardware working in concert.

[^demo]: Quoth Kay:

  > One of the best parts of the demo was when Steve Jobs said he didn't like
  > the blt-style scrolling we were using and asked if we could do it in a
  > smooth continuous style. In less than a minute Dan \[Ingalls] found the
  > methods involved, made the (relatively major) changes and scrolling was now
  > continuous!

  Years later, Jobs would found NeXT computing, whose operating sytem,
  NeXTSTEP, would be primarily programmed in Objective-C -- a object-oriented
  variant of the C language that took direct inspiration from Smalltalk. I
  don't have any concrete evidence that the PARC demo had any affect on Job's
  predisposition towards Objective-C, but I can't imagine the demo made selling
  him on using it difficult!

[^bill-70s]: Via [this link](https://mprove.de/visionreality/text/2.1.10_hypercard.html).

[^modifiable]: See ["Modifiable Software Systems"][modifiable-software-systems] at 12:07.

[^modality-note]: I note here that Atkinson is of a different generation than
  Kay: I call this out because Kay calls modality out as a _limitation_ as an
  editor, rather than a design choice. HyperCard uses modality to divide the
  possibility space of what a user can expect to accomplish in half -- so that
  playing and editing are two separate activities.

[^goldberg-quote]: At [OOPSLA-87][oopsla-87], Adele Goldberg categorized these forms of reuse as
  "literal" and "structural":

  > Goldberg said that there are two extremes of re-usability: literal reuse and structural
  > reuse. Literal reuse is just copying the code. Structural reuse is borrowing the “structure”
  > or “framework” of someone else’s solution.

[^or-surf]: Or "surf" -- it was the nineties, dude!

[^TKTK]: Points for research:
  - when did C start driving hardware design?

[^unsigned]: Before `unsigned`, it was custom to type-pun `char*` pointers to get
  unsigned integer behavior.

[^cite-1978-unix]: And a whole bunch of past experience writing portable
  software in Fortran. If you missed the link in the [first post][first-post], I'd recommend
  you go read ["Portability of C Programs and the Unix System"][portability].

[^new-life]: TKTK the [micro-operation cache][intel-microcode-cache] and [AMD][tktk]'s pressure
  on 64-bit ISAs drove intel to abandon itanium. Core processors were more than fast enough & the
  number of cores could be scaled. EGH THIS IS BAD

<!-- md links -->

----

[arm-design-priorities]: https://utcc.utoronto.ca/~cks/space/blog/tech/ARMvsRISC
[blackbird]: https://en.wikipedia.org/wiki/Blackbird_(online_platform)
[c-not-created-as-abstract-machine]: https://utcc.utoronto.ca/~cks/space/blog/programming/CAsAbstractMachine
[design-smalltalk]: https://www.cs.virginia.edu/~evans/cs655/readings/smalltalk.html
[early-history]: http://worrydream.com/EarlyHistoryOfSmalltalk/
[first-post]: /2023/05/10/understanding-wasm/part1/virtualization/
[grail-interface]: https://www.youtube.com/watch?v=LLRy4Ao62ls
[hype-cycle]: https://en.wikipedia.org/wiki/Gartner_hype_cycle
[hypercard-video]: https://archive.org/details/CC501_hypercard
[intel-microcode-cache]: https://websrv.cecs.uci.edu/~papers/compendium94-03/papers/2001/islped01/pdffiles/p004.pdf
[learnable-programming]: http://worrydream.com/#!/LearnableProgramming
[mansfield]: https://en.wikipedia.org/wiki/Mike_Mansfield#Mansfield_Amendments
[moad]: https://www.youtube.com/watch?v=yJDv-zdhzMY
[modifiable-software-systems]: https://www.youtube.com/watch?v=x-FkNd5DkOQ
[moores-law]: http://www.monolithic3d.com/uploads/6/0/5/5/6055488/gordon_moore_1965_article.pdf
[nyt-engelbart]: https://www.nytimes.com/2015/09/27/technology/smaller-faster-cheaper-over-the-future-of-computer-chips.html
[on-inheritance]: https://docs.google.com/document/d/1DbktFAMPW4mRZT9SKdHHE6bZRxLbLefiwCgH205w9aM/preview
[oopsla-87]: https://dl.acm.org/doi/pdf/10.1145/62139.62140
[papert-mindstorms]: http://worrydream.com/refs/Papert%20-%20Mindstorms%201st%20ed.pdf "Mindstorms"
[portability]: https://www.bell-labs.com/usr/dmr/www/portpap.html
[rand-tablet]: https://en.wikipedia.org/wiki/RAND_Tablet
[teaching-smalltalk]: http://bitsavers.informatik.uni-stuttgart.de/pdf/xerox/parc/techReports/SSL-77-2_Teaching_Smalltalk.pdf
[wingo-dart-flutter]: https://wingolog.org/archives/2023/04/26/structure-and-interpretation-of-flutter
[wingo-generation]: https://wingolog.org/archives/2020/04/14/understanding-webassembly-code-generation-throughput
[tktk]: find-source-material-dweeb
[erlang-history]: https://www.labouseur.com/courses/erlang/history-of-erlang-armstrong.pdf
[parnas]: https://www.win.tue.nl/~wstomv/edu/2ip30/references/criteria_for_modularization.pdf
[engelbart]: https://en.wikipedia.org/wiki/Douglas_Engelbart
[as-we-may-think]: https://www.theatlantic.com/magazine/archive/1945/07/as-we-may-think/303881/
[gates-tidal-wave]: https://lettersofnote.com/2011/07/22/the-internet-tidal-wave/
[blackbird]: http://www.itwriting.com/blog/363-mark-anders-remembers-blackbird-and-other-microsoft-hits-and-misses.html
[commercial-smalltalk]: https://wirfs-brock.com/allen/posts/914
[not-pirates]: https://web.stanford.edu/dept/SUL/sites/mac/parc.html
[pirates]: https://en.wikipedia.org/wiki/Pirates_of_Silicon_Valley
[smalltalk-bits]: https://gbracha.blogspot.com/2020/05/bits-of-history-words-of-advice.html
[hypercard-online]: https://archive.org/details/AppleMacintoshSystem753
[mraleph-pic]: https://mrale.ph/blog/2012/06/03/explaining-js-vms-in-js-inline-caches.html
[mraleph-hidden]: https://mrale.ph/blog/2015/01/11/whats-up-with-monomorphism.html
[strongtalk]: http://strongtalk.org/history.html
[the-influence-of-self]: https://dubroy.com/blog/self/
[squeak]: https://squeak.js.org/
[dan-gohman-kinda]: https://blog.sunfishcode.online/embrace-the-kinda/
[yosh-wasi]: https://blog.yoshuawuyts.com/what-is-wasi/

<!-- scratch notes


-->

----
