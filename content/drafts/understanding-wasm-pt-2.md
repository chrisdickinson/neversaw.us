+++
title = "understanding wasm pt 2: whence wasm"
slug = "understanding-wasm-pt-2"
date = 2023-06-29
+++

# understanding wasm

## part 2: whence wasm

"Write once, run anywhere" is a great sales pitch. It grabs your attention.
It's pithy! It invites the reader to fill in the blanks of "who is writing
what, where is it going, and how does it get there" with the answer that most
appeals to them. This was Java's sales pitch. WebAssembly seems to have the
same goal. Given that Java still exists, why do we need WebAssembly? What makes
them different?

I found that, in order to answer that question, I had to build some context for
myself around the history of Java, Smalltalk, and JavaScript. Each of these
languages presented not just a virtual machine, in the sense that we talked
about in the last post, but a virtual _platform_: a vision for computing that
required abstracting over the specifics of many different physical machines.
Each language was conceived under vastly different market pressures with
different ideas about who their primary audience was & how programs might be
distributed. When taken together, WebAssembly emerges from their stories as
a natural next step.

---

## Java

Since we're wondering out loud about "why we need WASM if we have Java", let's
start here.

If you're unfamiliar with Java, it is a general-purpose, object-oriented
programming language first released in January 1996 by Sun Microsystems, in
concert with Netscape Navigator 2.0. Java resembles C++, at least superficially.
I don't think I'm overstepping by saying that Java's object model looks most
like what most new programmers first _think_ C++'s object model looks like,
before seeing the gory details where that model meets the machine.

```java
class Greeter {
    String msg;

    public Greeter(String m) {
        msg = m;
    }

    public String Greet() {
        return msg + ', world!';
    }

    public static void main(String[] args) {
        Greeter greeter = new Greeter("Hello");
        System.out.println(greeter.Greet());
    }
}
```

The computer industry in 1996, at the time of Java's release, looks strange
from a modern point of view. The divide between professional hardware and
consumer hardware was _far_ more pronounced than it is today. Professional
computers (**"workstations"**) typically had custom hardware and operating
systems. At this point in time, a program might have to be compiled for
several instruction set architectures (**"ISAs"**, per [last post][last-post])
— SPARC, PA-RISC, MIPS, and Alpha — and one of several operating systems, which
were typically workstation-vendor specific: Silicon Graphic's IRIX, Alpha's
VMS/Ultrix/Prism, SunOS, or Windows NT[^today]. Personal computers, meanwhile,
predominantly ran Windows on 32-bit Intel x86 processors. Apple clung to
life, throwing Mac OS and IBM/Motorola PowerPC processors into the mix.
Compiling, testing, and distributing software to each of these targets was a
major hassle.

Then there was the web. ViolaWWW, Mosaic[^mosaic], and eventually Netscape
hinted of a future where all of these computers would communicate with each
other not just via text and file download, but with rich, graphical
applications. And this future was _imminent_.

> Even though the Web had been around for 20 years or so, with FTP and
> telnet, it was difficult to use. Then Mosaic came out in 1993 as an
> easy-to-use front end to the Web, and that revolutionized people's
> perceptions. The Internet was being transformed into exactly the network
> that we had been trying to convince the cable companies they ought to be
> building.
>
> - James Gosling, ["Happy 3rd Birthday, Java!"][happy-3rd-birthday-java]

Sun released the Java development toolkit for free, a language "built for the
'net", so developers could "write once, run anywhere." The Java Virtual Machine
implementation — the Java Runtime — was implemented in C for each major
combination of processor ISA and operating system. The specifics of each
machine and operating system combination were to be hidden well enough from
programs in the runtime environment that one could write a single
implementation of an application in Java and ship it to every target.

Except, uh.

> All the stuff we had wanted to do, in generalities, fit
> perfectly with the way applications were written, delivered, and used on
> the Internet. It was just an incredible accident. And it was patently
> obvious that the Internet and Java were a match made in heaven. So that's
> what we did.
>
> - James Gosling, ["Happy 3rd Birthday, Java!"][happy-3rd-birthday-java]

Java wasn't actually built for the net. It was built as part of "Project
Green"[^green], a system for controlling embedded consumer home devices via
radio: phones, VCRs, TVs, and door knobs. This was a four year-long
moonshot[^moonshot] which was near failure[^jim-clark] when lead technologist,
Patrick Naughton, wrote a last-ditch business plan that targeted the PC market
instead. He almost got fired for it. On the strength of a Java web browser
demo, WebRunner, the plan was saved. This plan involved creating an ecosystem
of Java developers while strategically partnering with Netscape to distribute
the Java runtime. "Run anywhere" came to include "on any consumer's PC, via the
web."

Sun stood to gain from this: they could license the language runtime to large
providers like IBM, Apple, or Microsoft, build a base of developers for their
nascent server market, and experiment more freely with hardware architecture on
their workstations. Netscape, at the time, had something like a 90% share of
the browser market, but was fending off Microsoft. Microsoft had approached
Netscape in mid-1995 [with a proposition][propo] for a "special relationship":
take Microsoft's investment, become a preferred developer, and only ship
Netscape Navigator to pre-Windows 95 operating systems. Stop competing with
Microsoft's Internet Explorer browser. Netscape needed an ally, and Sun wanted
Microsoft's share of the PC market.

They teamed up: Netscape and Sun co-designed a language meant for bootstrapping
and orchestrating larger Java applets, meant for non-programmers, in order to
prevent Microsoft from positioning Visual Basic in that space[^vbscript]. This
language, originally called "LiveScript", "Mocha", and finally "JavaScript",
was inspired by Scheme, Self, and Hypertalk — about which, more later.

Netscape added an `<applet>` HTML tag in order to support Java and began building a plugin
interface to support embedding other media types[^check]. The `<applet>` tag would run
Java in-process in an embedded Java Virtual Machine implementation, while the
plugin API would allow developers to distribute plugins for other media types
as shared libraries. These libraries would be compiled to their audience's
native ISA and operating system. With these additions, the web was no longer
static text — it was dynamic. Java caught on like wildfire.

The sudden appearance and rapid adoption of Java and Netscape caused Sun's
arch-enemy, Microsoft, great alarm[^plan9].

[<iframe frameborder="0" scrolling="no" style="border:0px" src="https://books.google.com/books?id=WTgEAAAAMBAJ&lpg=PP1&pg=PA6&output=embed" width=640 height=500></iframe>](https://books.google.com/books?id=0joEAAAAMBAJ&hl=en)
<sup>"Java Brews Trouble For Microsoft", Nick Wingfield and Martin LaMonica, Infoworld Nov 95</sup>

Microsoft controlled the lion's share of the PC market but were struggling to
make inroads into the workstation market with Windows NT. They were aware of
the web, but they were convinced they had time to build something better.
Something they could control[^unfair]. They called this ["Project
Blackbird"][microsoft-blackbird-press-release]: a model for bringing their
Object Linking and Embedding (**"OLE"**) API to the Web.

_(You may be familiar with OLE or its related technologies, the Component Object
Model (**"COM"**) and ActiveX; these are the APIs that allow embedding of rich
content from one application to another in Windows, among other things. If
you've ever pasted an Excel spreadsheet into a Word document, you've seen OLE
at work.)_

[<iframe frameborder="0" scrolling="no" style="border:0px" src="https://books.google.com/books?id=0joEAAAAMBAJ&lpg=PP1&pg=PA35&output=embed" width=640 height=500></iframe>](https://books.google.com/books?id=WTgEAAAAMBAJ&hl=en)
<sup>"Microsoft and Netscape open some new fronts in escalating Web Wars", Bob Metcalfe, Infoworld Aug 95</sup>

Microsoft's plan was to distribute signed OLE objects over the internet using
MSN as their flagship example. However, it wasn't set to ship until 1996 at the
earliest, and Netscape had already made huge inroads by 1994.

Microsoft responded [in character][the-internet-tidal-wave] to the threat: they
included their browser[^their], Internet Explorer, for free[^spyglass] in every copy of
Windows 95. Overnight, Netscape's primary product had been reduced to a
_feature_ of another, more popular product. Internet Explorer emulated NPAPI on
top of their own ActiveX plugin model, a remnant of the Project Blackbird plan.
They supported the `<applet>` tag by licensing the rights to build a Windows
Java runtime implementation (**"MSJVM"**) from Sun. This license included a
proviso that Microsoft were required to provide a complete implementation of
standard Java APIs. Sun was wary of Microsoft embracing, extending, and
extinguishing Java by diluting the language.

Netscape was forced to diversify their product line and, in the process, [ran
head-long into the limits][what-netscape-learned] of what was possible with
Java at the time. Multiple rewrites of Netscape products from C and C++ into
Java were abandoned. Java wasn't a silver bullet: it wasn't fast enough and the
quality of virtual machine runtimes varied too greatly.

Sun was aware of, and acting on, the Java performance problem as early as 1997.
They [purchased a company][strongtalk] working on an optimizing just-in-time
compiler VM for another language, Smalltalk. Sun put the team to work on
building a JIT VM, called "HotSpot", for Java.

When the dust settled on the first browser war, Microsoft had a controlling
stake of the browser market. The web would stagnate for years, while innovation
mostly appeared via the window Netscape left open: NPAPI. Other plugins
thrived; most notably, Flash.

In 1997, Sun [brought suit][sun-sues-microsoft] against Microsoft: the MSJVM
bundled into Windows was incomplete. Sun alleged Microsoft was up to its usual
tricks: embracing the language, only to squeeze it out of existence. The
lawsuit [was eventually settled][sun-microsoft-settle] in 2002; Microsoft would
remove MSJVM and require users to download a JVM plugin from Sun in order to
support Java web applets. Other browser vendors were unwilling (or unable) to
pay to license a Java runtime to vendor directly, and so Java was relegated to
plugin status. End-users would have to find and download appropriate versions
of the Java runtime whenever they wished to run an applet. This friction, on
top of sluggish performance and poor browser integration, sealed Java's fate as
a web platform technology. 

The HTML5 spec would later deprecate the `applet`, `object`, and `embed` tags
in favor of web-native solutions. Browser vendors wished to remove the NPAPI
plugin interface. NPAPI had become a major source of security bugs and a point
of divergence with mobile browsing.

> Java’s problem as a web client was that it wanted to be it’s own platform.
> Java wasn’t well integrated into the HTML-based architecture of web browsers.
> Instead, Java treated the browser as simply another processor to host the
> Sun-controlled “write once, run [the same] everywhere” Java application
> platform.
>
> It’s goal wasn’t to enhance native browser technology—it’s goal was
> to replace them.
>
> - Allen Wirfs-Brock, ["The Rise and Fall of Commercial Smalltalk"][the-rise-and-fall-of-commercial-smalltalk]

---

## Smalltalk

I want to back up to the Smalltalk folks and their just-in-time compiler
virtual machine. What's Smalltalk?

> The purpose of the Smalltalk project is to provide computer support for the
> creative spirit in everyone. [...] If a system is to serve the creative
> spirit, it must be entirely comprehensible to a single individual.
>
> - Dan Ingalls, ["Design Principles of Smalltalk"][smalltalk-design]

Java virtualized the machine in order to provide a stable language platform for
developers out of a pragmatic need. Smalltalk virtualized the machine in
service of a core metaphor out of an ideal: universal programming literacy. It
wasn't just a language: it was a consistent point of view that carried from the
operating system through to every program running on the machine. There was no
separation between operating system and program: there were only objects.

> [M]illions of potential users meant that the user interface would have to
> become a learning environment along the lines of Montessori and Bruner[.]
>
> - Alan Kay, ["The Early History of Smalltalk"][smalltalk-history]

This makes sense, given Smalltalk's lofty goals and inspirations. The first
version of Smalltalk was written in 1972, part of a vision for computing that
included universal literacy. If you've heard Steve Jobs refer to the computer
as a "bicycle for the mind", this is where he got the idea.

![Smalltalk-80 GUI](https://computerhistory.org/wp-content/uploads/2020/12/Smalltalk-80-GUI.jpg "Smalltalk 80 GUI")
<sup>via the <a href="https://www.computerhistory.org/revolution/input-output/14/347/1859">Computer History Museum</a></sup>

> [LISP] started a line of thought that said "take the hardest and most
> profound thing you need to do, make it great, and then build every easier
> thing out of it". That was the promise of LISP and the lure of lambda— [all
> that was] needed was a better "hardest and most profound" thing. Objects
> should be it.
>
> - Alan Kay, ["The Early History of Smalltalk"][smalltalk-history]

Smalltalk's core metaphor was one of objects passing messages to other objects.
Objects could be made to react as the programmer chose to any incoming message,
whether that message type was known ahead of time or not. The metaphor was
carefully chosen: when designing a class of object, the programmer was to put
themselves in the shoes of the object itself; to think in terms of what the
object "saw". (Garbage collection, the automatic deletion of unused objects,
fell out from this metaphor naturally: when an object was no longer visible
from any other object, it _must_ disappear. Thus, garbage collection was an
inherent property of the Smalltalk environment.) It was an enormously flexible
design, one that redefined "virtual machine" to include the entire operating
system.

> So why didn't Smalltalk take over the world? 
> 
> With 20/20 hindsight, we can see that from the pointy-headed boss perspective, the Smalltalk value 
> proposition was: 
> 
> Pay a lot of money to be locked in to slow software that exposes your IP, looks weird on screen and 
> cannot interact well with anything else; it is much easier to maintain and develop though!
> 
> On top of that, a fair amount of bad luck.
>
> - Gilad Bracha, ["Bits of History, Words of Advice"][bits-of-history-words-of-advice][^pun]

Smalltalk's flexibility came at a cost. Garbage collection cycles could be painfully
slow[^erlang], the lack of rigidity made "programming in the large"
difficult[^microsoft], and the language-as-operating-system environment meant
it was difficult to integrate into other operating systems. Gilad Bracha argues
that one of the properties that sealed Smalltalk's fate was its open nature.
Programs were shipped as images containing all of the objects comprising the
entire operating system. The intent was universal programming literacy, after
all, so the system continued to be modifiable after the fact. The software
market of the 1980s had gone a different direction: software was an immutable
artifact produced by programmers and sold to consumers. Companies didn't want
to ship all of their valuable intellectual property along with the appliance
they were selling.

So, what happened to Smalltalk?

The market for Smalltalk machines peaked in the 1980s. The language itself was
most influential in what it inspired and invented. In addition to the Apple
Lisa, the Xerox Alto also inspired Carnegie Melon University professor Raj
Reddy to coin the term ["3M computer"][3m_computer] ("a **M**egabyte of memory,
a **M**egapixel display, and a **M**illion instructions per second — for less
than a Megapenny, or $10K), which indirectly created the workstation market we
talked about earlier[^workstation]. The language itself inspired integrated
development environments, debuggers, and entire windowing system features we
take for granted today. The pedagogy Smalltalk developed for
classrooms[^goldberg] would go on to inspire one of the students in that
classroom to invent HyperCard[^hypercard].

But, most relevant to this discussion, Smalltalk contributed huge advances in
optimizing virtual machines through its later dialects,
[Self][the-influence-of-self] and [Strongtalk][strongtalk-history]. I gestured
at the creation of the HotSpot VM earlier. It was, in fact, the folks working
on these two projects that Sun hired: among others, Gilad Bracha[^bracha],
David Ungar[^generational-gc], Urs Hölzle and Lars Bak. Their work on improving
the performance of Smalltalk would be adapted to improve the performance of
bytecode virtual machines in general.

And what of Smalltalk? Java largely supplanted it, as some
[feared][will-java-kill-smalltalk] it would. Smalltalk wasn't the right thing,
but it pointed _at_ the right thing.

> Smalltalk did something more important than take over the world—it defined the
> shape of the world!
>
> - Allen Wirfs-Brock, ["The Rise and Fall of Commercial Smalltalk"][the-rise-and-fall-of-commercial-smalltalk]

Which brings us, somewhat ironically, to JavaScript.

---

## JavaScript

Nobody liked JavaScript[^unfair-js].

JavaScript was an unlikely survivor of the first browser war: a "toy" scripting
language meant only to combat Visual Basic and coordinate the larger Java
applets marshalled by websites. As it was first imagined, it lacked features
considered core to other serious languages — or hid those features behind
strange constructions. But it grew steadily, riding along with every browser
shipped, forever backwards-compatible.

JavaScript as it existed until 2014 was an ugly language: the elegant object
model of Self combined with function closures from Scheme integrated with
document object models inspired by HyperTalk, all of which were slathered in a
thick coat of Java syntax.

```js
function Greeter(msg) {
  if (!(this instanceof Greeter)) {
    return new Greeter(msg)
  }
  this.msg = msg;
}

// All functions had a field, "prototype", that
// pointed at an object.
Greeter.prototype.greet = function () {
  return this.msg + ', world!';
}

// When the function is invoked with "new", a
// new object would be created whose internal
// "[[Prototype]]" slot pointed at the 
// function's ".prototype" object.
//
// We walked uphill both ways in the snow.
var obj = new Greeter("Hello");

// The language didn't ship with "console.log",
// or any way to log text, really.
//
// You had to use browser APIs, like "alert".
alert(obj.greet());
```

But the language grew in fits and starts, subject at once to the pressure of
the aims of giant corporations and to the expectations of the largest userbase
in the world: every website. First, JavaScript became functional. Then
JavaScript got fast — for the consumers. Then JavaScript got pretty — for
programmers.

```js
// JavaScript after 2014:
class Greeter {
    constructor(msg) {
        this.msg = msg;
    }

    greet() {
        return `${this.msg}, world!`;
    }
}

const obj = new Greeter("Hello");
console.log(obj.greet());
```

In 1999, Internet Explorer shipped the second version of the MSXML ActiveX
library as part of Internet Explorer 5. There's some irony here: Microsoft's
Project Blackbird was a platform play to give them control of the nascent web
platform, implemented using ActiveX. MSXML ActiveX would give us AJAX --
"Asynchronous JavaScript and XML", later standardized in the platform as
`XMLHttpRequest`. AJAX would unlock a new breed of web applications, from
webmail to maps. The second browser war kicked off. This time, Microsoft lost.

- 1998: The open-source Mozilla project was founded by former members of
  Netscape.
- 2001: "JavaScript Object Notation" (**"JSON"**) was "discovered" by Douglas
  Crockford at Yahoo.
- 2002: Mozilla releases Phoenix (now "Firefox")
- 2004: Ruby on Rails released.
- 2005: Prototype, a polyfill/cross-document-model javascript framework, first
  released
- 2005: Git first released.
- 2006: Firebug, a JavaScript development plugin for Firefox browser, first
  released
- 2006: jQuery, a polyfill & cross-document-model development framework, first
  released
- 2007: Mootools, ditto.
- 2007: Google purchases Doubleclick.
- 2008: Google releases Chrome, a web browser with a high-performance JIT
  JavaScript VM, V8.
- 2008: GitHub launches.
- 2008: "JavaScript: The Good Parts" is released.
- 2009: Firefox 3.5 launches with TraceMonkey, a high-performance JIT
  JavaScript VM.
- 2009: Node.js, an evented JavaScript language platform powered by V8, first
  released.

To extract a theme: JavaScript as it existed between 1995 and 2009 did not ship
with a particularly complete standard library, nor did it ship with any
dedicated syntax for modularity. However, it was possible to build these
libraries _in_ JavaScript. And people did.

Google emerged as a new, major player during this time period. They made money
by serving ads ahead of search results; the faster (and safer) they could get
relevant results in front of users, the more money they could make. Thus
incentivized, they employed Lars Bak to translate the optimization techniques
he perfected on the Java and Smalltalk VMs to JavaScript, creating
V8[^v8-comic]. [Firefox][pic], [Safari][safari] and other browser vendors
adopted these techniques.

The newfound ubiquity of fast JavaScript VMs led, inevitably, to a renewed
interest in using JavaScript as a "write once, run anywhere" platform.

There were other pressures on the web through this time, however. Notably: the
Dot Com bubble burst, Apple created a new computing market with the iPhone and
iPad products, Google shipped the Android smartphone operating system, Oracle
acquired Sun Microsystems, and Microsoft found itself struggling to enter the
new markets Apple had opened. The window Netscape left open for Java, NPAPI,
attracted other plugins: Flash and Silverlight. Despite the functionality they
unlocked, managing these plugins was difficult and perilous, pushing both
dependency management and security vetting onto end users. A bug in a plugin
could assume the full privileges of the user's account on the computer, and any
website (or frame within a website) could deliver an exploit for such a bug.

Thus, Apple [famously][thoughts-on-flash-apple] doomed Flash by denying it
access to the iPhone platform in favor of web platform technologies. The new
mobile web would not have plugins.

JavaScript remains fast and ubiquitous today. And yet, at the turn of the '10s,
there was still no good alternative to NPAPI plugins for desktop browsers. Like Smalltalk,
JavaScript was still difficult to program "in the large"; like Java, running
existing software required a language port — companies with large C++
applications had to manually rewrite them in JavaScript. Google was
particularly interested in solving this problem, having just launched its
ChromeOS project, which would replace the traditional user-visible operating
system layer with a web browser. They launched three projects: [Dart][dart][^dart], PPAPI
(["Pepper"][pepper]), and Native Client (["NaCl"][nacl][^nacl], a pun on "Salt".) While Dart was capable
of compiling to JavaScript as a target, it lost some language capabilities in
the process — it was clearly intended to _replace_ JS long-term. PPAPI and
NaCl endeavoured to harden the NPAPI plugin interface by running plugin ISA code
in a virtual machine[^pnacl]. Competing browser vendors balked at the cost of supporting an
entirely separate virtual machine; they were at an impasse.

---

### Interlude: Virtual ISAs

It's worth revisiting that 90's workstation market at this point. The market
for custom RISC processors unexpectedly shrunk dramatically in the 2000's
because Intel x86 processors caught up to the performance of the more expensive
RISC designs while remaining relatively low-cost. This was completely unexpected.

In fact, x86 seemed to be _doomed_ at the turn of the century. Much was made of
perceived performance boundaries of the x86 ISA; the most common prediction
being a shift to "very large instruction word" (**"VLIW"**) architectures.
There was a scramble to find a way to build a compatibility bridge from x86 to
this VLIW future.

This is where the term "virtual ISA" originates.

The 1997 [DAISY][daisy] paper, 1998's ["Achieving high performance via
co-designed virtual machines"][co-design], and 2003's ["LLVA: A Low-level
Virtual Instruction Set Architecture"][llva] originated the idea of a "virtual
instruction set architecture" ("virtual ISA" or "V-ISA") to address the
inflexibility and seemingly imminent obsolescence of x86. They were written in
reaction to Java's virtual machine; the LLVA paper in particular defines
several useful design goals for both the "Virtual Instruction Set Computer"
(**"VISC"**") and "Virtual Abstract Binary Interface" (**"V-ABI"**) in order to
differentiate their approach from the JVM. Quoting (with some paraphrasing)
from the LLVA paper:

1. **Simple, low-level operations that can be implemented without a runtime
   system.** To serve as a processor-level instruction set for arbitrary software
   and enable implementation without operating system support, the V-ISA must
   use simple, low-level operations that can each be mapped directly to a small
   number of hardware operations.
2. **No execution-oriented features that obscure program behavior.** The V-ISA
   should exclude ISA features that make program analysis difficult and which
   can instead be managed by the translator, such as limited numbers and
   types of registers, a specific stack frame layout, low-level calling
   conventions, limited immediate fields, or low-level addressing modes.
3. **Portability across some family of processor designs.** [A] good V-ISA design
   must enable some broad class of processor implementations and maintain
   compatibility at the level of virtual object code for all processors in that
   class (key challenges include endianness and pointer size).
4. **High-level information to support sophisticated program analysis and
   transformations.** Such high-level information is important not only for
   optimizations but also for good machine code generation, e.g., effective
   instruction scheduling and register allocation
5. **Language independence.** Despite including high-level information
   (especially type information), it is essential that the V-ISA should be
   completely language-independent, i.e., the types should be low-level and
   general enough to implement high-level language operations correctly and
   reasonably naturally.
6. **Operating system support.** The V-ISA must fully support arbitrary operating
   systems that implement the V-ABI associated with the V-ISA.

The authors note that language platform virtual machines like Java fail to meet
the **first**, **fifth**, and **sixth** requirement. The paper goes on to propose
a design for such a virtual ISA and ABI.

Ultimately, the x86 ISA proved not to be a bottleneck. Intel engineers devised
a means to virtualize the x86 ISA itself in hardware[^transmeta] (a possibility
hinted at in the linked papers above.) That is, [a modern x86 processor][x86]
decodes x86 instructions into micro-operations (or **"µops"**), which allows
for a RISC-like hardware implementation behind the scenes. Having found success
with this approach, Intel abandoned their VLIW architecture, IA-64, in favor of
continuing forward with x86 processors.

> A primary goal in using VMs in the manner just described is to provide
> platform independence. That is, the Java bytecodes can be used on any
> hardware platform, provided a VM is implemented for that platform. In
> providing this additional layer of abstraction, however, performance is
> typically lost because [of] inefficiencies in matching the V-ISA and the
> native ISA via interpretation and just-in-time (JIT) compilation.
>
> - ["Achieving High Performance via Co-Designed Virtual Machines"][co-design]

Put a pin in that for now.

---

## asm.js

In the early 2010's, JavaScript experienced rapid syntax changes — additions
— to remove warts from the language and make it more straightforward to use.
At the same time, JIT VMs were experimenting with different approaches and
heuristics in order to find the best balance between immediate execution and
high performance for long-lived processes. Certain constructions in the
language would opt entire functions out of optimization passes. Other, more
subtle deoptimizations had to do with "hidden classes."

Let's take a thousand-mile high view of the optimizations that JavaScript
inherited from Smalltalk VMs[^caveat].

First: ["generational scavenging"][generational-gc] garbage collection (**"GC"**).
In broad strokes: garbage collectors must decide whether or not a given object
is "alive", remove it if it isn't, and reclaim the memory space for future use.
There are a variety of ways to achieve this. One might mark all of the "live"
objects in one pass then "sweep" the dead objects to reclaim their space ("mark
and sweep"). Or count the number of live references on every object —
increasing and decreasing them as objects refer to them to reclaim the space
immediately when the number of references drops to zero. Both of these
approaches have overhead: they pause the execution of the program (either all
at once or in small time slices) to do their work. They also suffer from
fragmentation: occasionally a costly compaction phase is needed, since objects
may be of different sizes and locations within memory.

"Scavenging" describes the approach of taking all live objects and explicitly
copying them to a new region before freeing the old region. "Generational"
refers to an observation from [Baker][baker], [Henry Lieberman, and Carl
Hewitt][hewitt]: most objects are short-lived. A GC algorithm can take this
into account by writing all new objects into a single memory space, then only
copying out objects that survive one or more runs of the GC algorithm (a
**"generation"**) to a memory space reserved for old objects. This helps address
massive mark/sweep or compaction pauses without incurring the constant overhead
of reference counting (and associated difficulties with breaking circular
references.)

Second: tagged pointers. This takes advantage of the "word alignment"
properties for pointers on certain architectures — that is, pointers optimally
point to a multiple of the processor's native word size in bytes. On a 16-bit
system, that means the three least significant bits of every pointer are
unused. LISP, Smalltalk, Java, and JavaScript capitalize on this: they use
these three (or more) bits as "tag" information. In particular, one bit could
indicate whether the value was an object or a "primitive" value, like an
integer or boolean. Smalltalk used one of the tag values to indicate that the
value was a "small integer" (or "Smi"), a 31-bit integer; JavaScript inherited
this property. This is handy for performance: the pointer can be used instead
as an immediate value without a subsequent fetch, and most arrays can be
indexed by small integers.

Third: [polymorphic inline caches][self-pic] (**"PICs" or "ICs"**.) These are
part of the type-feedback mechanism introduced by Self. Since any given bit of
Smalltalk, Java, and JavaScript code may deal abstractly with many different
types of objects, JIT VMs for these languages insert inline caches into
generated code. These inline caches collect information on the "types" that
pass through a given branch. If, after a few executions, the types are
consistent, the JIT [may optimize][mraleph-mono] that branch by rewriting it
from VM bytecode to native machine code, translating the inline cache calls as
necessary. If the inline cache is later invalidated by a new type of object
passing through the branch, the VM may execute the bytecode version of the code
or, eventually, "de-optimize" and decide to remove the optimized machine code.
Inline caches consult both the tag bits mentioned above as well as the object's
["hidden class"][mraleph-hidden-class], which is a separate tag representing
which fields and associated types have been added to the object since its
inception (A sort of "vector in class-space", so to speak.)

These optimizations — ubiquitous in browser engines, though in slightly
different forms — made JavaScript a compelling compilation _target_. In 2010,
work kicked off on Emscripten, a C/C++ to JavaScript compiler. In 2011, Fabrice
Bellard released [JSLinux][jslinux]: a Linux operating system and virtual machine compiled
to JavaScript using a patched version of his QEMU software. Finally, in 2013,
Alon Zakai released `asm.js`[^lljs].

`asm.js`[^asmjs] relies on the following optimizations:

- Loads and stores from typed arrays are optimized (JavaScript's standardized "buffer of bytes" object.)
- Certain bitwise operations can be used as type annotations, to be consulted
  by ICs later. That is, the VM knows that `x|0` always returns a 32-bit
  integer; likewise `(x+y)|0` is always 32 bits, so no need to insert overflow
  checks. Optimizing VMs are capable of translating these type-annotated
  operations directly to native ISA operations.
- All operations work against a single, long-lived typed array, treating it as
  the addressable space for the process — which means performance doesn't
  suffer from GC pauses or stutter.

`asm.js` specified a strict subset of JavaScript, one that could be validated
cheaply ahead of time by compatible VMs, but would run with acceptable
performance in agnostic VMs. Mozilla called this technique "ahead of time"
(**"AOT"**) compilation, and released a killer demo: the [Unreal
engine][unreal], 250K lines of C++, compiled to `asm.js` and running in the
browser at a steady framerate[^graal].

[This][johnresig] demo [kicked][mraleph] off [a whirlwind][acko] of [discussion][daveherman].

---

### WebAssembly

By 2015, [all interested parties concluded][wasm-announce] that `asm.js`
pointed [in the right direction][eich-wasm], that a language like `asm.js`
should be encoded as distributable bytecode. Google got on board with the
effort, dropping the NaCl/Pepper/PNaCl project, and WebAssembly was born.
Chrome dropped support for NPAPI the same year and Firefox followed suit in
2017. The window Netscape opened, NPAPI, was finally shut.

WebAssembly pulled the same magic trick C did: it extracted an existing, useful
abstract machine definition from several concrete implementations, like finding
David in the block of marble. Rather than requiring that browser vendors
implement a second virtual machine, WebAssembly support could be added
incrementally, sharing code between the JS and WASM runtimes. WebAssembly machine
definition supports C's abstract machine — C, C++, Golang, and Rust can compile
to this target — acting as a virtual instruction set architecture.

For its part, WebAssembly described a zero-capability system with no set system
interface, making it an ideal sandbox. Riding along with the web platform meant
a free ticket to just about every computer with a screen: from fridges to
laptops to phones to embedded views within applications. It also meant taking
on the security and isolation pressure of the web.

Like Java, WebAssembly was written for one purpose but well-adapted to serve
others. Because WASM describes a machine, not an implementation, it is not
constrained to run only in browser JIT VMs. WASM has been successully used
outside of the browser via runtimes like wasmtime and wasmer and as a
sandboxing intermediate representation for 3rd-party C code via
[`wasm2c`][wasm2c] and [RLBox][rlbox][^rlbox]. ("Has a" vs. "Is a": WebAssembly
is not _a_ "virtual machine" runtime, it _has many_ indepedent virtual machine
_runtimes_. The performance of browser WASM runtimes may not be indicative of
overall performance boundaries for the ISA.) 

> Through VM co-design, the V-ISA abstraction can be exploited to exceed native
> processor performance.
>
> - ["Achieving High Performance via Co-Designed Virtual Machines"][co-design]

---

When you're talking about virtualizing _any_ component of a system, you're
doing so because you want to hide the specifics. There are a variety of reasons
to hide the specifics — they might change, they might stand in the way of
working through higher-level problems, or you might wish to hide the
limitations of inexpensive components. In the case of Smalltalk, Java, and
JavaScript, the specifics were hidden in order to present a unified view of the
system to a programming language through a virtual machine.

Prior to `asm.js`, each of these languages presented a virtual machine to
programs that was attuned to the needs of that host language. `asm.js` and
WebAssembly discovered a **virtual instruction set computer** hiding in the
optimizing virtual machine runtimes of JavaScript. A similar virtual instruction set
computer could probably be found [in the JVM][graal] or even the Strongtalk VM, but
neither of those VMs had the advantage of riding along with the browser or
being subject to the particular performance, isolation, and security
requirements of the web platform.

---

Today, we're about halfway into the fictional future that Gary Bernhardt predicted his 2014
talk, ["The Birth and Death of JavaScript"][birth-and-death]. In the talk, he describes
using `asm.js` as the foundation of a virtual instruction set computer, one that removes
the overhead of process isolation -- the boundary between operating system and userland
process can be dissolved.

And you know what? We haven't talked at _all_ about WebAssembly's operating
system interface.

> If WASM+WASI existed in 2008, we wouldn't have needed to created Docker.
> That's how important it is. Webassembly on the server is the future of
> computing. A standardized system interface was the missing link. Let's hope
> WASI is up to the task!
>
> - Solomon Hykes via [twitter][docker-quote]

And we're not going to, at least not in this post. Next time: what is WASI? What is
a process runtime environment? What is an ABI? Let's find out!

---

## Bibliography, Links, Reading list

So. This post was a doozy: there's at least a few drafts on the cutting room
floor, including one brute-force attempt to walk straight up from 1945 to
today. This is my first time writing anything resembling a history, let alone a
history that's within _living memory_ for a lot of the people involved. In that
spirit I tried to be as meticulous as I could about gathering and linking to
references. Invariably I've lost a few over time. (And thanks in particular to
Ron Gee for turning up ["On Inheritance"][on-inheritance] and [a few other papers][ron-gee] from
early 90's Microsoft -- great sleuthing!)

All of these sources were instrumental in building my mental model for where
WebAssembly fits into the story of computing (and, of course, the post above.)
To be honest, I think this post was so difficult to write precisely because the source
material is so interesting! There are a lot of themes that one _could_ pluck
out, and I encourage you to check out as much as you can of these.

- 1945\. ["As we may think"][as-we-may-think], Vannevar Bush.
- 1965\. ["Cramming more components onto integrated circuits"][moores-law], Gordon E. Moore.
- 1968\. ["The Mother of All Demos"][moad], Douglas Engelbart.
- 1968\. ["Alan Kay shows the Rand Tablet"][grail-interface], Alan Kay.
- 1972\. ["On the Criteria To Be Used in Decomposing Systems into Modules"][parnas], D.L. Parnas.
- 1977\. ["Teaching Smalltalk"][teaching-smalltalk], Adele Goldberg and Alan Kay. Covers the curriculum for teaching Smalltalk to 7th and 8th graders.
- 1978\. ["Actor Systems for Real-time Computation"][baker], Henry Givens Baker, Jr.
- 1978\. ["Portability of C Programs and the UNIX System"][portability], S. C. Johnson, D. M. Ritchie.
- 1980\. ["Mindstorms"][papert-mindstorms], Simon Papert.
- 1981\. ["Design of Smalltalk"][design-smalltalk], Daniel H. H. Ingalls.
- 1983\. ["A real-time garbage collector based on the lifetimes of objects"][hewitt], Henry Lieberman, Carl Hewitt.
- 1983\. ["Smalltalk-80: Bits of History, Words of Advice"][smalltalk-80-bits-of-history], Glenn Krasner.
- 1984\. ["Generation Scavenging: A non-disruptive high performance storage reclamation algorithm"][generational-gc], David Ungar.
- 1987\. ["Summary of Discussions from OOPSLA-87's Methodologies & OOP Workshop"][oopsla-87], Norman L. Kerth, John Hogg, Lynn Stein, Harry H. Porter, III.
- 1990\. ["On Inheritance: What it means and how to use it"][on-inheritance], Tony Williams.
- 1991\. ["Optimizing Dynamically-Typed Object-Oriented Languages With Polymorphic Inline Caches"][self-pic], Urs Hölzle, Craig Chambers, David Ungar.
- 1993\. ["Steve Jobs and the NeXT big thing"][next-big-thing], Randall E. Stross.
- 1993\. ["The Early History of Smalltalk"][early-history], Alan Kay.
- 1993\. (est). ["A Brief History of the Web"][www-book-history], Tim Berners-Lee.
- 1995\. ["Microsoft Announces Tools to Enable a New Generation of Interactive Multimedia Applications for The Microsoft Network"][microsoft-blackbird-press-release], Microsoft.
- 1995\. ["The Internet Tidal Wave"][gates-tidal-wave], Bill Gates.
- 1996\. ["Apple Macintosh System 7.5.3"][hypercard-online], Apple. (Try hypercard here!)
- 1996\. ["The Long, Strange Trip to Java"][long-strange-java], Patrick Naughton.
    - 2022\. [Hackernews Comment on "The Long Strange Trip to Java"][naughton-comment], Chuck McManis.
- 1996\. ["Will Java Kill Smalltalk?"][will-java-kill-smalltalk], Jeff Sutherland.
- 1997\. ["DAISY: dynamic compilation for 100% architectural compatibility"][daisy], Kemal Ebcioğlu, Erik R. Altman.
- 1997\. ["The SK8 Multimedia Authoring Environment"][sk8], Apple.
- 1997\. ["Microsoft's $8 Million Goodbye to Spyglass"][spyglass-suit], Peter Elstrom, Michael Mercurio.
- 1997\. ["Sun Sues Microsoft on Use of Java System"][sun-sues-microsoft], John Markoff.
- 1998\. ["Barksdale takes on MS in trial"][propo], Dan Goodin.
- 1998\. ["Achieving High Performance via Co-Designed Virtual Machines"][co-design], J. E. Smith, Tim Heil, Subramanya Sastry, Todd Bezenek.
    - (It's a postscript file, so you might look into using Ghostscript to convert it. Use `ps2pdf`.)
- 1998\. ["Happy Third Birthday, Java"][happy-3rd-birthday-java], Jon Byous.
- 1999\. ["What Netscape learned from cross-platform software development"][what-netscape-learned], Michael A. Cusumano, David B. Yoffie.
- 2000\. ["Sun Microsystems, Inc. History"][sun-microsystems], Jay P. Pederson.
- 2000\. ["How the Web was Born: The Story of the World Wide Web, p213"][viola-hypercard], James Gillies, R. Cailliau.
- 2000\. ["The Xerox PARC Visit"][not-pirates], Alex Soojung-Kim Pang, Wendy Marinaccio.
- 2001\. ["Micro-Operation Cache: A Power Aware Frontend for Variable Instruction Length ISA"][intel-microcode-cache], Baruch Solomon, Ave Mendelson, Doron Orenstien, Yoav Almog, Ronny Ronen.
- 2001\. ["Modern Microprocessors: A 90-Minute Guide!"][x86], Jason Robert Carey Patterson. (updated 2016.)
- 2002\. ["Sun, Microsoft settle Java suit"][sun-microsoft-settle], Stephen Shankland.
- 2002\. ["Vision & Reality of Hypertext and Graphical User Interfaces, Ch 2.1.10"][vision-and-reality-of-hypertext-and-guis-2-1-10-hypercard-mprove], Matthias Müller-Prove.
- 2003\. ["LLVA: A Low-level Virtual Instruction Set Architecture"][llva], Vikram Adve, Chris Lattner, Michael Brukman, Anand Shukla, Brian Gaeke.
- 2004\. (est) ["What's a Megaflop?"][whats-a-megaflop], Andy Hertzfeld.
- 2006\. (est) ["The History of the Strongtalk Project"][strongtalk-history].
- 2007\. ["A History of Erlang"][a-history-of-erlang], Joe Armstrong.
- 2007\. ["Mark Anders Remembers Blackbird"][blackbird], Tim Anderson.
- 2008\. ["Introducing SquirrelFish Extreme"][safari], Maciej Stachowiak.
- 2009\. ["Native Client: A Sandbox for Portable, Untrusted x86 Native Code"][nacl], Bennet Yee, David Sehr, Gregory Dardyk, J. Bradley Chen, Robert Muth, Tavis Ormandy, Shiki Okasaka, Neha Narula, Nicholas Fullagar.
- 2010\. ["Thoughts on Flash"][thoughts-on-flash-apple], Steve Jobs.
- 2010\. ["PICing on JavaScript for fun and profit"][pic], Chris Leary.
- 2011\. ["Dart Language"][dart], Google.
- 2011\. ["JS Linux"][jslinux], Fabrice Bellard.
- 2012\. ["Learnable Programming"][learnable-programming], Bret Victor.
- 2012\. ["Explaining JavaScript VMs in JavaScript - Inline Caches"][mraleph-pic], Vyachyslav Egorov.
- 2012\. ["LLJS: Low Level JavaScript"][lljs], James Long.
- 2012\. ["Texas Jury Strikes Down Patent Troll's Claim to Own the Interactive Web"][texas-jury], Joe Mullin.
- 2013\. ["ARM vs RISC"][arm-design-priorities], Chris Siebenmann.
- 2013\. ["Hidden Classes vs JSPerf"][mraleph-hidden-class], Vyachyslav Egorov.
- 2013\. ["Youtube: Unreal Engine 3 in Firefox with asm.js"][unreal], Mozilla, Epic Games.
- 2013\. [asmjs.org][asmjsorg], Alon Zakai. The original website for the `asm.js` project. The slides link is broken but I've included [a link][asmjs-slides] to a working version.
- 2013\. ["Asm.js: The JavaScript Compile Target"][johnresig], John Resig.
    - ["On Asm.js"][acko], Steven Wittens.
        - ["On 'On Asm.js'"][daveherman], Dave Herman.
    - ["Why Asm.js bothers me"][mraleph], Vyachyslav Egorov.
- 2014\. ["The Birth and Death of JavaScript"][birth-and-death], Gary Bernhardt.
- 2015\. ["What's up with monomorphism?"][mraleph-hidden], Vyachyslav Egorov.
- 2015\. ["WebAssembly"][wasm-announce], Luke Wagner.
    - ["From Asm.js to WebAssembly"][eich-wasm], Brendan Eich.
- 2015\. ["Smaller, Faster, Cheaper, Over: The Future of Computer Chips"][nyt-engelbart], John Markoff.
- 2016\. ["JEP 295: Ahead-of-time Compilation"][graal], Vladimir Kozlov, John Rose, Mikael Vidstedt.
- 2017\. ["The Xerox Alto, Smalltalk, and rewriting a running GUI"][ken-shirriff], Ken Shirriff.
- 2020\. ["JavaScript: The First Twenty Years"][js-first-twenty], Allen Wirfs-Brock, Brendan Eich.
- 2020\. ["Bits of History, Words of Advice"][bits-of-history-words-of-advice], Gilad Bracha.
    - ["The Rise and Fall of Commercial Smalltalk"][commercial-smalltalk], Allen Wirfs-Brock.
- 2020\. [Oldweb.today][oldweb], Webrecorder.
- 2020\. ["'C is how the computer works' is a dangerous mindset for C Programmers"][steveklabnik], Steve Klabnik.
- 2020\. ["understanding webassembly code generation throughput"][wingo-generation], Andy Wingo.
- 2020\. ["Securing Firefox with WebAssembly"][ff-rlbox-1], Nathan Froyd.
    - 2021\. ["WebAssembly and Back Again: Fine-Grained Sandboxing in Firefox 95"][ff-rlbox-2], Bobby Holley.
    - ["RLBox Overview"][rlbox].
- 2022\. ["The influence of Self"][the-influence-of-self], Patrick Dubroy.
- 2021\. ["Modifiable Software Systems: Smalltalk and HyperCard"][modifiable-software-systems], Josh Justice.
- 2023\. ["structure and interpretation of flutter"][wingo-dart-flutter], Andy Wingo.
- 2023\. ["C as Abstract Machine"][c-not-created-as-abstract-machine], Chris Siebenmann.
- 2023\. ["Parsers | TLB Hit Podcast"][tlb-hit], Chris Leary, JF Bastien.
- 2023\. ["Embrace the 'Kinda'"][dan-gohman-kinda], Dan Gohman.
- 2023\. ["What is WASI?"][yosh-wasi], Yoshua Wuyts.

If you're still here, congratulations. Treat yourself to a 1987 interview with
Bill Atkinson on "The Computer Chronicles".

<iframe src="https://archive.org/embed/CC501_hypercard" width="640" height="480" frameborder="0" webkitallowfullscreen="true" mozallowfullscreen="true" allowfullscreen></iframe>

---


#### Footnotes

<!--footnotes-->

[^today]: Today, a workstation may sport consumer hardware at a
  drastically upgraded scale (think "the mac pro vs the imac", or "nvidia
  quadro vs the RTX line".)

  Now, if you're working for IBM or Oracle, don't fret: I haven't forgotten you.
  Some of the architectures I talk about still exist, though mostly in the realm
  of high-performance compute!

---

[^mosaic]: Heck of a footnote, here: [Mosaic was inspired by
  ViolaWWW][www-book-history], which [was inspired by HyperCard][viola-hypercard], which was
  inspired by Smalltalk ([and LSD][hypercard-lsd]), which was inspired by Engelbart's [NLS][moad],
  who was inspired by the 1945 article ["As We May Think"][as-we-may-think] by Vannevar Bush.

  What's more: ViolaWWW [saved the web][texas-jury] from a patent troll in 2012.

---

[^green]: Project Green's business plan was titled "Behind the Green Door", a
  reference to an adult film from 1972. _Ahem._ You can read about this (and more)
  in Patrick Naughton's essay, ["The Long, Strange Road to Java"][long-strange-java].

---

[^moonshot]: This moonshot started when Patrick Naughton was nearly recruited
  by Steve Jobs at NeXT Computers due to his frustration with how the Sun
  NeWS project was being handled.

  You can read Naughton's account of the project [here][long-strange-java]. You can also
  check out another contemporaneous account in [this comment][naughton-comment].

---

[^jim-clark]: Java's last resort was a bid for Time Warner's WebTV business.
  According to Patrick Naughton, at the 11th hour, SGI bought their way in to
  the bid, undercutting Project Green.

---

[^vbscript]: Note: it did not prevent Microsoft from _trying_. They, in fact, shipped
  versions of Internet Explorer with support for `<script type="text/vbscript">`.

---

[^check]: So. Double-check me on this one. By the time Firefox 1.0 was released,
  as far as I can tell from spelunking through the [source code][ff-1] (in `layout/html/base/src/nsObjectFrame.cpp`
  and `modules/plugin/base/src/nsPluginHostImpl.cpp`), Java ran through the plugin
  system. In Netscape Communicator 3.0's [source code][ns-c3], however, `lib/layout/layjava.c`
  and `lib/libjava/lj_embed.c` seem to indicate that `<applet>` tags ran Java in-process, not
  through the plugin API. I know that Microsoft moved their MSJVM _out_ of Internet Explorer
  and began requiring a separate plugin download in the early 2000s, but I'm not sure
  exactly when Java went from "browser built-in" to "browser plugin."

---

[^plan9]: And Microsoft wasn't the only one! Java was so popular, in fact, that
  AT&T dropped Plan 9 in favor of their Inferno virtual machine operating
  system — patterned after Java.

[<iframe frameborder="0" scrolling="no" style="border:0px" src="https://books.google.com/books?id=xT4EAAAAMBAJ&lpg=PA3&pg=PA3&output=embed" width=640 height=500></iframe>](https://books.google.com/books?id=xT4EAAAAMBAJ&pg=PA3#v=onepage&q&f=false)
<sup>"AT&amp;T reveals plans for Java Competitor", Jason Pontin, Infoworld Feb 96</sup>

---

[^unfair]: Lest you think I am being unfair to the Microsoft of the '90s:

  > [Blackbird] was a kind of Windows-specific internet, and was surfaced to some
  > extent as the MSN client in Windows 95. Although the World Wide Web was
  > already beginning to take off, Blackbird’s advocates within Microsoft
  > considered that its superior layout capabilities would ensure its success
  > versus HTTP-based web browsing. It was also a way to keep users hooked on
  > Windows.
  >
  > - Mark Anders, ["Mark Anders remembers Blackbird"][mark-anders-remembers]
---

[^their]: Well, "their" browser. Internet Explorer was originally licensed from
  Spyglass, Inc, who had obtained a license to the source of NCSA Mosaic.

---

[^spyglass]: Microsoft was also cannily exploiting the terms of their contract
  with Spyglass: since they were releasing Internet Explorer for free, they didn't
  _technically_ need to pay any royalties on it. Spyglass sued Microsoft, who
  settled out of court for [8MM dollars][spyglass-suit].

---

[^pun]: The title of this post is a play on a previous, seminal Smalltalk book,
    ["Smalltalk-80: Bits of history, Words of Advice."][smalltalk-80-bits-of-history].

---

[^erlang]: Ahem:

  > By now the lab had acquired a SUN workstation with Smalltalk on it. But the
  > Smalltalk was very slow—so slow that I used to take a coffee break while it
  > was garbage collecting. To speed things up, in 1986 we ordered a Tektronix
  > Smalltalk machine, but it had a long delivery time. [...] One day I
  > happened to show Roger Skagervall my algebra—his response was “but that’s a
  > Prolog program.” I didn’t know what he meant, but he sat me down in front
  > of his Prolog system and rapidly turned my little system of equations into
  > a running Prolog program. I was amazed. This was, although I didn’t know it
  > at the time, the ﬁrst step towards Erlang.
  >
  > Joe Armstrong, ["A History of Erlang"][a-history-of-erlang]:

  In other words: Smalltalk's VM was so slow that it inadvertantly inspired the
  creation of Erlang. _Cough._

---

[^microsoft]: In a memo Wikipedia claims as "foundational to the design of COM and OLE", Tony
  Williams wrote:

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

---

[^workstation]: Universities formed a consortium for the purposes of procuring
  a 3M computer. Apple, IBM, and others were in the running. Steve Jobs
  looked at this market after being ejected from Apple and concluded that he
  could address that market with a small team, unencumbered by legacy
  technology. He founded NeXT. (See also ["What's a
  megaflop"][whats-a-megaflop] and ["Steve Jobs: The Next Big
  Thing"][next-big-thing], pp 58, 74, 95, and 135.)

  So in a way: if there were no Smalltalk, there would be no NeXT; nobody to
  snipe Patrick Naughton from Sun and hence, no Java.

---

[^goldberg]: Adele Goldberg struck on the idea of "design templates" to address this gap:
  the idea of providing Smalltalk students paper templates to describe objects &
  their methods. A completed template held a table with three columns per row:
  the first column described a message the object may receive, the second column
  held a plain English description of what action would be carried out, and the
  third column held Smalltalk code written to achieve the English desription of
  the action. These could be handed out in varying states of completion to
  students (See page 22 of ["Teaching Smalltalk"][teaching-smalltalk])
  
  [<img src="/img/smalltalk-design-template.png" width="100%" alt="an image of a smalltalk design template" />][teaching-smalltalk]

---

[^hypercard]: Bill Atkinson, the inventor of HyperCard [was a
  student][vision-and-reality-of-hypertext-and-guis-2-1-10-hypercard-mprove]
  in the Smalltalk classroom series. Alan Kay, of the Language Research Group
  at Xerox PARC & inventor of Smalltalk, would advise him on Hypercard.

  HyperCard also included the Hypertalk programming language, which would serve
  as one of the other inspirations behind JavaScript.

  And lest we forget, Hypertalk would also inspire [SK8][sk8].

---

[^bracha]: Gilad Bracha would go on to co-author the 2nd and 3rd editions of the Java Language Specifications.
  He was also a major contributor to the 2nd edition of the Java Virtual Machine specification and worked on
  the Dart language at Google.

---

[^generational-gc]: Notably, David Ungar is the author of ["Generational Scavenging"][generational-gc], a paper describing
  generational garbage collection. This technique is key in writing high-performance garbage collected
  languages and builds on work by H.G. Baker, S. Ballard, S. Shirron, and others.

---

[^unfair-js]: I'm being unfair: at least a few people liked JavaScript, myself
  included. But even folks who liked JavaScript during its awkward ES3/5
  years have to admit, it was a bit programmer-hostile.

---

[^v8-comic]: And they got famous cartoonist, Scott McCloud, of "Understanding Comics" fame,
  to draw [a comic][mccloud-v8] for it! Ugh, so cool.

---

[^dart]: Dart is still a going concern! Andy Wingo writes an excellent history
  of Dart [here][wingo-dart]. Notably, Gilad Bracha and Lars Bak were
  involved in the development of the language!

---

[^nacl]: JF Bastien highlights some interesting parsing work on the NaCl project
  on his podcast. A transcript is available [here][tlb-hit].

---

[^pnacl]: NaCl virtualized native ISAs, but PNaCl attempted to use LLVM IR (remember that
  from last post?) as a transfer format instead. [A quote on this from Derek Schuff][eth-pnacl], an
  engineer at Google advising the Ethereum project on their next distributed VM:

  > I'm guessing you are unfamiliar with PNaCl. This is more or less the
  > approach taken by PNaCl; i.e. use LLVM as the starting point for a wire
  > format. It turns out that LLVM IR/bitcode by itself is neither portable
  > nor stable enough to be used for this purpose, and it is designed for
  > compiler optimizations, it has a huge surface area, much more than is
  > needed for this purpose.
  >
  > PNaCl solves these problems by defining a portable target triple (an
  > architecture called "le32" used instead of e.g. i386 or arm), a subset of
  > LLVM IR, and a stable frozen wire format based on LLVM's bitcode. So this
  > approach (while not as simple as "use LLVM-IR directly") does work. However
  > LLVM's IR and bitcode formats were designed (respectively) for use as a
  > compiler IR and for temporary file serialization for link-time
  > optimization. They were not designed for the goals we have, in particular a
  > small compressed distribution format and fast decoding. We think we can do
  > much better for wasm, with the experience we've gained from PNaCl.

---

[^transmeta]: This is, in fact, a lot like what the Transmeta Crusoe did: accepting x86 instructions
  and using "code-morphing" to turn those into VLIW instructions.

---

[^caveat]: OK, I say these optimizations are inherited from Smalltalk but many of them
  originated in LISP and were merely _adopted_ by Smalltalk.

---

[^lljs]: I want to note that James Long was working on [LLJS][lljs] shortly before
  `asm.js` came out. 

---

[^asmjs]: The original slides for the asm.js talk are available [here][asmjs-slides];
  the website is still available [here][asmjsorg].

---

[^graal]: Released in 2017, Java SE 9 would include [ahead-of-time compilation
  support via GraalVM][graal]. In the same version, Java deprecated applets,
  later removing them in Java SE 11 in 2018.

---

[^rlbox]: RLBox was built to make it safe for Firefox to embed 3rd-party C/C++ libraries
  that are too small (or called too frequently) to justify a process-level sandbox. You
  can read more about it in [these][ff-rlbox-1] two [posts][ff-rlbox-2].

<!--links-->

[3m_computer]: https://en.wikipedia.org/wiki/3M_computer
[_3m-computer]: https://en.wikipedia.org/wiki/3M_computer
[a-history-of-erlang]: https://www.labouseur.com/courses/erlang/history-of-erlang-armstrong.pdf
[acko]: https://acko.net/blog/on-asmjs/
[arm-design-priorities]: https://utcc.utoronto.ca/~cks/space/blog/tech/ARMvsRISC
[as-we-may-think]: https://www.theatlantic.com/magazine/archive/1945/07/as-we-may-think/303881/
[asmjs-slides]: https://web.archive.org/web/20130219011422/https://kripken.github.com/mloc_emscripten_talk
[asmjsorg]: http://asmjs.org/
[baker]: http://publications.csail.mit.edu/lcs/pubs/pdf/MIT-LCS-TR-197.pdf
[birth-and-death]: https://www.destroyallsoftware.com/talks/the-birth-and-death-of-javascript
[bits-of-history-words-of-advice]: https://gbracha.blogspot.com/2020/05/bits-of-history-words-of-advice.html
[blackbird]: http://www.itwriting.com/blog/363-mark-anders-remembers-blackbird-and-other-microsoft-hits-and-misses.html
[blackbird_wiki]: https://en.wikipedia.org/wiki/Blackbird_(online_platform)
[c-not-created-as-abstract-machine]: https://utcc.utoronto.ca/~cks/space/blog/programming/CAsAbstractMachine
[co-design]: https://users.cs.northwestern.edu/~srg/Papers/03-21-02/vm.ps
[commercial-smalltalk]: https://wirfs-brock.com/allen/posts/914
[daisy]: https://dl.acm.org/doi/pdf/10.1145/384286.264126
[dan-gohman-kinda]: https://blog.sunfishcode.online/embrace-the-kinda/
[dart]: https://dart.dev/
[daveherman]: http://calculist.org/blog/2013/11/27/on-on-asm-js/
[design-smalltalk]: https://www.cs.virginia.edu/~evans/cs655/readings/smalltalk.html
[docker-quote]: https://twitter.com/solomonstre/status/1111004913222324225?lang=en
[early-history]: http://worrydream.com/EarlyHistoryOfSmalltalk/
[eich-wasm]: https://brendaneich.com/2015/06/from-asm-js-to-webassembly/
[engelbart]: https://en.wikipedia.org/wiki/Douglas_Engelbart
[ff-1]: https://ftp.mozilla.org/pub/firefox/releases/1.0/source/
[first-post]: /2023/05/10/understanding-wasm/part1/virtualization/
[gates-tidal-wave]: https://lettersofnote.com/2011/07/22/the-internet-tidal-wave/
[generational-gc]: https://dl.acm.org/doi/pdf/10.1145/800020.808261
[generational-scavenging]: https://dl.acm.org/doi/pdf/10.1145/800020.808261
[graal]: https://openjdk.org/jeps/295
[grail-interface]: https://www.youtube.com/watch?v=LLRy4Ao62ls
[happy-3rd-birthday-java]: https://web.archive.org/web/19990224053407/http://java.sun.com:80/features/1998/05/birthday.html
[hewitt]: https://dl.acm.org/doi/pdf/10.1145/358141.358147
[hype-cycle]: https://en.wikipedia.org/wiki/Gartner_hype_cycle
[hypercard-lsd]: https://boingboing.net/2018/06/18/apples-hypercard-was-inspire.html
[hypercard-online]: https://archive.org/details/AppleMacintoshSystem753
[hypercard-video]: https://archive.org/details/CC501_hypercard
[intel-microcode-cache]: https://websrv.cecs.uci.edu/~papers/compendium94-03/papers/2001/islped01/pdffiles/p004.pdf
[johnresig]: https://johnresig.com/blog/asmjs-javascript-compile-target/
[last-post]: /2023/05/10/understanding-wasm/part1/virtualization/
[learnable-programming]: http://worrydream.com/#!/LearnableProgramming
[lljs]: https://web.archive.org/web/20150904012034/http://lljs.org/
[llva]: https://llvm.org/pubs/2003-10-01-LLVA.pdf
[mansfield]: https://en.wikipedia.org/wiki/Mike_Mansfield#Mansfield_Amendments
[mark-anders-remembers]: http://www.itwriting.com/blog/363-mark-anders-remembers-blackbird-and-other-microsoft-hits-and-misses.html
[mccloud-v8]: https://www.google.com/googlebooks/chrome/big_12.html
[microsoft-blackbird-press-release]: https://ftp.zx.net.nz/pub/archive/ftp.microsoft.com/developr/drg/Multimedia/Blackbird/BBPR.htm
[moad]: https://www.youtube.com/watch?v=yJDv-zdhzMY
[modifiable-software-systems]: https://www.youtube.com/watch?v=x-FkNd5DkOQ
[moores-law]: http://www.monolithic3d.com/uploads/6/0/5/5/6055488/gordon_moore_1965_article.pdf
[mraleph-hidden-class]: https://mrale.ph/blog/2013/08/14/hidden-classes-vs-jsperf.html
[mraleph-hidden]: https://mrale.ph/blog/2015/01/11/whats-up-with-monomorphism.html
[mraleph-mono]: https://mrale.ph/blog/2015/01/11/whats-up-with-monomorphism.html
[mraleph-pic]: https://mrale.ph/blog/2012/06/03/explaining-js-vms-in-js-inline-caches.html
[mraleph]: https://mrale.ph/blog/2013/03/28/why-asmjs-bothers-me.html
[nacl]: https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/34913.pdf
[naughton-comment]: https://news.ycombinator.com/item?id=30619733
[next-big-thing]: https://archive.org/details/isbn_9780689121357/page/374/mode/2up?q=%223m+computer%22
[not-pirates]: https://web.stanford.edu/dept/SUL/sites/mac/parc.html
[ns-c3]: https://archive.org/details/netscape-communicator-3-0-2-source
[nyt-engelbart]: https://www.nytimes.com/2015/09/27/technology/smaller-faster-cheaper-over-the-future-of-computer-chips.html
[oldweb]: https://oldweb.today
[on-inheritance]: https://docs.google.com/document/d/1DbktFAMPW4mRZT9SKdHHE6bZRxLbLefiwCgH205w9aM/preview
[oopsla-87]: https://dl.acm.org/doi/pdf/10.1145/62139.62140
[papert-mindstorms]: http://worrydream.com/refs/Papert%20-%20Mindstorms%201st%20ed.pdf "Mindstorms"
[parnas]: https://www.win.tue.nl/~wstomv/edu/2ip30/references/criteria_for_modularization.pdf
[pepper]: https://en.wikipedia.org/wiki/Google_Native_Client#Pepper
[pic]: https://web.archive.org/web/20100930092419/http://blog.cdleary.com/2010/09/picing-on-javascript-for-fun-and-profit/#id31
[pirates]: https://en.wikipedia.org/wiki/Pirates_of_Silicon_Valley
[portability]: https://www.bell-labs.com/usr/dmr/www/portpap.html
[propo]: https://web.archive.org/web/20121108043059/http://news.cnet.com/Barksdale-takes-on-MS-in-trial/2100-1001_3-216862.html
[rand-tablet]: https://en.wikipedia.org/wiki/RAND_Tablet
[safari]: https://webkit.org/blog/214/introducing-squirrelfish-extreme/
[self-pic]: https://bibliography.selflanguage.org/_static/pics.pdf
[sk8]: https://sk8.dreamhosters.com/sk8site/sk8.html
[smalltalk-80-bits-of-history]: https://www.google.com/books/edition/Smalltalk_80/3rQmAAAAMAAJ?hl=en
[smalltalk-design]: https://www.cs.virginia.edu/~evans/cs655/readings/smalltalk.html
[smalltalk-history]: http://worrydream.com/EarlyHistoryOfSmalltalk/
[spyglass-suit]: https://web.archive.org/web/19970629174318/http://www.businessweek.com/bwdaily/dnflash/january/new0122d.htm
[squeak]: https://squeak.js.org/
[strongtalk-history]: http://strongtalk.org/history.html
[strongtalk]: http://www.strongtalk.org/
[sun-microsoft-settle]: https://www.cnet.com/tech/tech-industry/sun-microsoft-settle-java-suit/
[sun-microsystems]: http://www.fundinguniverse.com/company-histories/sun-microsystems-inc-history/
[sun-sues-microsoft]: https://www.nytimes.com/1997/10/08/business/sun-sues-microsoft-on-use-of-java-system.html
[teaching-smalltalk]: http://bitsavers.informatik.uni-stuttgart.de/pdf/xerox/parc/techReports/SSL-77-2_Teaching_Smalltalk.pdf
[texas-jury]: https://www.wired.com/2012/02/interactive-web-patent/
[the-influence-of-self]: https://dubroy.com/blog/self/
[the-internet-tidal-wave]: https://lettersofnote.com/2011/07/22/the-internet-tidal-wave/
[the-rise-and-fall-of-commercial-smalltalk]: https://wirfs-brock.com/allen/posts/914
[thoughts-on-flash-apple]: https://web.archive.org/web/20170615060422/https://www.apple.com/hotnews/thoughts-on-flash/
[tlb-hit]: https://tlbh.it/005_parsers.html
[unreal]: https://www.youtube.com/watch?v=BV32Cs_CMqo
[viola-hypercard]: https://www.google.com/books/edition/How_the_Web_was_Born/pIH-JijUNS0C?hl=en&gbpv=1&pg=PA213&printsec=frontcover
[vision-and-reality-of-hypertext-and-guis-2-1-10-hypercard-mprove]: https://mprove.de/visionreality/text/2.1.10_hypercard.html
[wasm-announce]: https://blog.mozilla.org/luke/2015/06/17/webassembly/
[what-netscape-learned]: https://dl.acm.org/doi/pdf/10.1145/317665.317678
[whats-a-megaflop]: https://www.folklore.org/StoryView.py?project=Macintosh&story=Whats_A_Megaflop?.txt
[will-java-kill-smalltalk]: https://web.archive.org/web/19961113014356/http://www.onemind.com/smalltalk.html
[wingo-dart-flutter]: https://wingolog.org/archives/2023/04/26/structure-and-interpretation-of-flutter
[wingo-dart]: https://wingolog.org/archives/2023/04/26/structure-and-interpretation-of-flutter
[wingo-generation]: https://wingolog.org/archives/2020/04/14/understanding-webassembly-code-generation-throughput
[www-book-history]: https://www.w3.org/DesignIssues/TimBook-old/History.html
[x86]: https://www.lighterra.com/papers/modernmicroprocessors/#whataboutx86
[yosh-wasi]: https://blog.yoshuawuyts.com/what-is-wasi/
[steveklabnik]: https://steveklabnik.com/writing/c-is-how-the-computer-works-is-a-dangerous-mindset-for-c-programmers
[long-strange-java]: https://www.landley.net/history/mirror/java/javaorigin.html
[ken-shirriff]: http://www.righto.com/2017/10/the-xerox-alto-smalltalk-and-rewriting.html
[ron-gee]: https://hachyderm.io/@rgee@mstdn.social/110387805070748529
[jslinux]: https://bellard.org/jslinux/tech.html
[wasm2c]: https://github.com/WebAssembly/wabt/blob/main/wasm2c/README.md
[rlbox]: https://rlbox.dev/
[ff-rlbox-1]: https://hacks.mozilla.org/2020/02/securing-firefox-with-webassembly/
[ff-rlbox-2]: https://hacks.mozilla.org/2021/12/webassembly-and-back-again-fine-grained-sandboxing-in-firefox-95/
[js-first-twenty]: https://dl.acm.org/doi/pdf/10.1145/3386327
[eth-pnacl]: https://github.com/ewasm/design/blob/ea77a2a8f91da131975fa37f5ec51744e044592e/comparison.md
