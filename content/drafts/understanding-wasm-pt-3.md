+++
title = "Understanding Wasm, Part 3: A System Interface"
slug = "understanding-wasm-pt-3"
date = 2023-08-31
description = "Understanding WASM, Part 3: A System Interface"

+++

# Understanding WASM

## Part 3: A Virtual System

_(This is part 3 of a series. See [part 1, "Virtualization"][part-1] and [part 2, "Whence WASM"][part-2].)_ 

It's not enough for a virtual architecture, like WebAssembly, to be portable
across physical processors: after all, if that's all it could do we'd be
limited to calculating numbers. Chris Lattner's ["Low-level Virtual
Architecture"][llva] established a handy rubric that we've been using to judge
WebAssembly as a Virtual Instruction Set Architecture. WebAssembly has:

1. ✅ **Simple, low-level operations.** 
2. ✅ **No execution-oriented features.**
3. ✅ **Portability across processor designs.**
4. ✅ **High-level information to support optimization.**
5. ✅ **Language independence.**
6. ❓ **Operating system support.**

Solomon Hykes claimed that if WASI had existed in 2008, he and his companions
at dotCloud[^docker] wouldn't have had to invent Docker. This is a pretty bold
claim! Docker not only solved a lot of issues for developers over the course of
the last decade, it changed the course of the "platform as a service" market.

This quote sets up WebAssembly (and WASI) as an alternative to Docker; not only
than that, it might be _better_ than Docker. So, uh, what gives? What is WASI?
What is Docker? What does "the future of computing" even mean in this context?

----------------------------------------------------------------------------------------------------------------------------------------------------------------

## Contain your Enthusiasm

Let's start with Docker. Docker was launched in 2013 by dotCloud. The
high-level metaphor of Docker is that of **shipping containers**. Standardized
containers revolutionized the shipping industry: a standard form factor meant a
standard way to load, unload, and transport material. The technology made
shipping _everything_ faster, cheaper, and more reliable. This is Docker's
raison d'être: to do for computer applications and operations teams what
standard containers did for the shipping industry.

The metaphor is pretty durable: the concrete problem that Docker solved was
that of shared resources. Consider: given a large company, two developers may
develop two different web serving applications (**"services"**) that expect to
listen on the same network port[^port]. Before containerization, these two
developers would have to sync up: who gets to listen on port 80? They'd have to
agree, up-front, before being able to deploy their software. Worse, if they
couldn't come to agreement about the use of resources, they'd have to involve a
third-party &mdash; someone from the operations department &mdash; who might solve the
problem by introducing a _third_ server, a reverse proxy layer, to resolve
the conflict.

Docker solves this by giving each service a **virtualized** view of the
operating system's resources. Both developers may remain agnostic of each other
AND the operations team. The operations team can map network ports as necessary
-- or rely on orchestration software, like Nomad or Kubernetes, to do this for
them. Standard containers yield standard tools.

So far, so good. So what _is_ Docker?

Docker is a virtualization technology, just like all of the other
virtualization technologies we've talked about in previous posts. However, it
achieves virtualization through a combination of technologies supported by the
kernel of the host operating system: seccomp, namespaces, and control groups.
Namespaces allow for partitioning of operating system concepts across
processes. Seccomp ("secure computing") allows or disallows the set of system
requests a process may make. Control groups partition use of hardware
resources: the amount of CPU time, number of processors, and amount of memory
processes in the group can use. Each namespace, control group, and seccomp
profile has to be layered properly to make durable the illusion that the
process is running on a virtualized system.

Docker comprises a long-lived process (or "daemon", in this case called
`containerd`) for running these virtualized containers (via `runc` or `crun`),
a user interface for _controlling_ those containers, a registry protocol for
_sharing_ container images, and a file format describing how to _build_ those
container images. The long-lived process, container builder, and registry
protocol is usually called the "runtime", while the user interface for
starting, stopping, and managing container state is called a "frontend". The
file format for building docker images, a `Dockerfile`, specifies a series of
commands that construct a container image; each command forms a distinct,
content-addressable "layer". `Dockerfile`s may source other `Dockerfile`s
during the build process, common layers are reused between builds.

dotCloud rebranded themselves as Docker in an attempt to capture some of the
value of this ecosystem in 2013; to ensure trust that the ecosystem would
outlive the company the "Open Container Initiative" was formed in 2015. As a
result, there are alternative runtimes (`crio` from Redhat), frontends
(Rancher), or combinations of the two (`podman`.)

Containers rely on kernel support: on operating systems that don't support
namespaces and cgroups containers are typically run in a virtual machine
process. Windows supports containers natively through a `hcsshim` runtime that
provides namespace and cgroup support through Window's native Host Compute
Service. Apple's macOS, however, runs docker containers by spinning up a
virtualized Linux host to run a Docker daemon and container processes.

While the Docker/OCI containerization model is ubiquitous today, the
capabilities underpinning it have a much longer history.

---

> I never intended to use these tools to simulate a system in real-time. I wanted
> to watch the cracker’s keystrokes, to trace him, learn his techniques, and warn
> his victims. The best solution was to lure him to a sacrificial machine and tap
> the connection. The Ethernet is easy to tap, and modified tcpdump software can
> separate and store the sessions. But I didn't have a spare machine handy, so I
> took the software route. (Steve Bellovin did construct such a machine. We never
> managed to lure anyone interesting to it.)
>
> I consulted the local gurus about the security of a `chroot` environment. Their
> conclusion: it is not perfectly secure, but if compilers and certain programs
> are missing, it is very difficult to escape. 
>
> - ["An Evening with Berferd"][berferd], Bill Cheswick, 1990

The need to consolidate servers, decouple hardware provisioning from service
scaling, and migrate batch processes between high performance compute nodes
created a renaissance of virtualization technologies in the late 90's and early
2000's. The rapid adoption of the internet drove these use cases, thawing a
nearly twenty year long freeze in virtual machine research.

Let's walk backwards through time for a second.

Docker was originally implemented using an earlier containerization model
called "LXC" ("Linux Containers"), introduced in 2008. LXC, like many of its
contemporary containerization models, was built on the model of a virtual
machine. Rather than Docker's model of taking a single process and giving it a
virtual system environment, LXC containers typically virtualized an `init`
process (like `systemd`, `upstart`, or SysV `init`[^init].) This made them
"feel" much more like a virtual machine, with their own long-lived daemons,
periodic tasks, and system logs.

Linux Containers were made possible in part by Google's contribution of control
groups (`cgroups`) to the Linux kernel in 2007. Control groups allowed userland
to communicate resource quotas for process subtrees to the kernel: effectively
allowing container runtimes to dictate the maximum CPU time, parallelism,
network, memory, and disk usage a set of sub-processes should be able to use.
This doesn't affect the ability of those processes to _see_ certain subsystems:
control groups don't affect what the process has access to, only the available
quality of service for that access. This control allowed Google to more
efficiently allocate shared resources using their internal orchestration
software[^borg].

Namespaces are related to earlier `jail` capabilities. They control what
operating system subresources are visible to jailed processes. The earliest
jail-like capability, `chroot`, was added to AT&T Unix in 1979. It was also
added to the Berkeley Software Distribution ("**BSD**"[^bsd]) in 1982. `chroot`
allowed a process to "pivot" the root directory to a subdirectory, effectively
hiding parent directories from a process. This offered [incomplete
protection][break-chroot], thus BSD introduced the `jail` system call in 2000.

[break-chroot]: https://web.archive.org/web/20080113162832/http://www.bpfh.net/simes/computing/chroot-break.html

> In the case of the `chroot(2)` call, a process's visibility of the file
> system name-space is limited to a single subtree. However, the
> compartmentalisation does not extend to the process or networking spaces and
> therefore both observation of and interference with processes outside their
> compartment is possible.
>
> To this end, we describe the new FreeBSD 'Jail' facility, which provides a
> strong partitioning solution, leveraging existing mechanisms, such as
> `chroot(2)`, to what _effectively amounts to a virtual machine environment_.
>
> - ["Jails: Confining the omnipotent root."][jails], Poul-Henning Kamp, Robert N. M. Watson, 2000

Jails were effective but did not address resource management or scheduling
concerns. Sun addressed this in 2004 with Solaris's "Zones", which provided an
LXC- or Docker-like experience. However, Sun fell on hard times during the
2000's, eventually meeting its demise in 2010 after being acquired by Oracle.
As a result, Solaris didn't experience the widespread adoption that various
Linux distributions enjoyed during this time. (We'll touch on the source of
Sun's woes a little later.)

Starting in 2002, Linux began adding namespace support. The mount namespace for
filesystems came first, inspired by Plan 9[^java-killed]. Eric W. Biederman
outlined the necessary namespace support in ["Multiple Instances of the
Global Linux Namespaces"][global-linux-namespaces]:

- `mnt`: The filesystem namespace.
- `uts`: The UNIX Time-sharing namespace (controlling what hostname is visible to the process.)
- `ipc`: Inter-process communication namespace.
- `net`: The network namespace.
- `pid`: The process identifier namespace.
- `user`: The user and group namespace.
- `time`: The time namespace.

Linux added the `user` namespace in 2013 &mdash; the same year Docker was first
released publicly. (This was later followed up with the `cgroup` namespace in
2016.) Namespaces and cgroups form the basis of what we think of as containers
today[^openvz].

As we noted previously, virtualizing the system at the process/system interface
required careful virtualization of each _kind_ of system resource visible to
processes, both in terms of which subresources are visible (files, other
processes, users, etc) _and_ in terms of their quality of service (available
memory or bandwidth.) Each of these resources can be virtualized _separately_,
but the Docker containerization model generally virtualizes them
together[^selinux].

> We have been gratified when casual users mistake the technology for a virtual machine.
>
> - ["Solaris Zones: Operating System Support for Consolidating Commercial Workloads"][solaris-zones]

There's a fork in the road, here. It is important to understand both paths: why
they diverged, how they're starting to merge once again, and what that means
for WebAssembly. Containerized processes virtualize at the system interface;
virtual machines virtualize at the hardware interface. However, processes and
virtual machines are two expressions of the same concept: **time-sharing**.

---

## Processes

Processes are a near-universal concept in modern operating systems. They
comprise three capabilities:

1. **A continuous view of processing resources** that initially includes a
   single advancing program state with the ability to spawn additional,
   concurrent states against the same program within the process
   (**"threads"**.)
2. **A contiguous address namespace**, into which memory may be allocated by
   the operating system upon request. This initially contains the program
   instructions (or **"text"**), environment variables and arguments, read-only
   (or **"static"**) data, space reserved for structures to be initialized at
   startup ("block starting symbol", or **"bss"**[^bss]), and
   room for a "stack" of activation frames. A number of system libraries may
   also be loaded by the operating system into this address space.
3. **A system interface**, made available through a set of supervisory calls
   (**"system calls"**.) Typically this is implemented through use of dedicated
   `syscall` or system interrupt instructions (e.g., `int 0x80`, in x86 assembly)
   available through the instruction set architecture. The use of supervisory
   calls is dictated through calling conventions, including what registers must
   be saved, where parameters to the syscall are placed&mdash;in memory or on registers&mdash; and how results are
   retrieved after control returns to the process thread. These conventions
   describe an "application binary interface", or **"ABI"**.

This is a *virtual* view of the physical machine's resources: an "extended
machine"[^hey]. The operating system is responsible for enforcing the illusion
that each process operates with independent, full access to the system's
resources. This illusion is constructed through the operating system's careful
orchestration of the machine's processor features &mdash; the
processor's memory mapping hardware, interrupts and traps, mode and protection
rings, and use of privileged instructions.

As widespread as the concept of a process is today, it wasn't always so:
processes and operating systems emerged _alongside_ virtual machines in the
'60s.

Hardware and software design were, at the start of the 1960s, intertwined. It
was common practice to design parallel computers &mdash;those with a number of
processors&mdash; by assigning a program to each processor, along with a range
of physical memory to be accessed _by_ that processor. If, during development,
programmers discovered that _one_ process on the system needed additional
space, all other processes had to be reprogrammed to accommodate the new memory
partitions. Similarly, if one process went idle, no other processes could make
use of that idle processor hardware. Programs had to be submitted in batches in
order to maximize utilization of the hardware. Time-sharing systems would
change that.

<iframe width="640" height="480"
src="https://www.youtube.com/embed/Q07PhW5sCEk?si=LAZO7ozHwlvegUlr"
title="YouTube video player" frameborder="0" allow="accelerometer; autoplay;
clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
allowfullscreen></iframe>

In 1961, DARPA, newly flush with cash[^yuri], funded research on time-sharing operating
systems through "Project MAC"[^mac]. MIT, a participating member, brought their
"Compatible Time Sharing System" (**"CTSS"**[^its]) with them, and along with
Bell Laboratories and General Electric, began work on a successor system called
"MULTICS". Several teams coordinated on it.

That term we introduced earlier, "extended machine", originated from this era.
It described a machine that was "easier to program" than the underlying
physical machine. The role of a "monitor" (or "nucleus", or "kernel") was to
support these extended machines by using the "bare machine interface", or
hardware, directly. The monitor scheduled user programs to minimize costly idle
time.

The extended machine typically supported virtual memory, supervisory calls, and
protection rings. Virtual memory was developed so that programs could be
written without advance knowledge of other programs running on the system.

This was accomplished by introducing indirection: the address namespace of a
program no longer mapped directly to the physical address space of memory.
Three techniques were used to accomplish this indirection: paging,
segmentation, or the combination of the two.

With paging, both the process and physical address space are subdivided into
"pages" of memory. Each page represented several hundred "words" of
memory[^words]. Accesses to "non-resident" pages in process address space
trigger hardware faults. The kernel sets traps for those faults: the fault
transfers control to the kernel, which takes action to load the
missing page into physical memory to complete the mapping. Control transfer
back to the process at this point[^tricks]. 

[<img width="640" src="https://www.neversaw.us/img/virtual-memory-paging.png" alt="Illustration from &quot;Segmentation and the Design of Multiprogrammed Systems&quot;, Jack B. Dennis, 1965" />](https://www.neversaw.us/img/virtual-memory-paging.png)
<sup>Illustration from ["Segmentation and the Design of Multiprogrammed Systems"][segmentation-and-the-design], Jack B. Dennis, 1965. "N" represents the process address namespace, "M" the physical namespace. Note how the contiguous "N" namespace maps to a discontiguous namespace in "M".</sup>

Memory segmentation was also used to support virtual memory. Segmentation has
the advantage of allowing larger address namespaces than the native computer
word size would otherwise be capable of representing. Consider that a 16-bit
word can only represent values from 0 to 65535. One popular segmentation scheme
addresses 20-bit values. It accomplishes this by holding another 16-bit value
in a "segment register", shifting it left by 4 bits (multiplying it by 16) and
adding the resulting value to the base offset held in the operand register.
This allows addressing up to 1MiB of memory. When the segment register changes,
the entire segment of memory is made resident at once &mdash; which could be a
single word of memory or a significant subset of physical memory. Some hardware
supports transferring control to the kernel when the segment register changes,
which allows the implementation of virtual memory purely through segmentation.

[<img width="640" src="https://www.neversaw.us/img/virtual-memory-segmentation.png" alt="Illustration from &quot;Segmentation and the Design of Multiprogrammed Systems&quot;, Jack B. Dennis, 1965" />](https://www.neversaw.us/img/virtual-memory-segmentation.png)
<sup>Illustration from ["Segmentation and the Design of Multiprogrammed Systems"][segmentation-and-the-design], Jack B. Dennis, 1965. The left diagram illustrates using a word address to index into the segment. The right diagram illustrates the namespace of segments.</sup>

The variable size of segments could lead to conflict &mdash;or thrash&mdash;
between processes if the two segments happened to overlap. Given the much
expanded range available to them, desktop 64-bit processors tend to use paging
by itself to implement virtual memory. Processors of the era we're discussing
used both techniques in conjunction to combine the advantages of paging with the
ability to increase the addressable memory space.

Finally, protection rings change the instruction set architecture available to
the program, trapping or disallowing use of privileged instructions having to
do with memory mapping, input/output (**"I/O"**) devices, or the manipulation
of software timer interrupts. The operating system runs in a protection ring
with higher privileges. Processes run in a lower ring. Processes may request
services from the operating system, like memory allocation or I/O, by making
supervisory calls. System requests are implemented using interrupt instructions
or dedicated `syscall` instructions available in the instruction set
architecture of the processor.

_(For more on all of this, check out [cpu.land][cpuland] and [Phil Opp's "Writing an OS in Rust" series][philopp])_.

Project MAC's contemporaries included Project GENIE at UC Berkeley and the IBM
System/360 and 370. These technologies were built in competition with MULTICS;
IBM found that they their university bids were being out-competed by
time-sharing systems spun out from Project MAC. This led them to develop early
whole-machine virtualization software.

While extended machines made it possible to safely create and run relocatable
programs, much research revolved around the development of new operating
systems. This was more difficult than developing a program for an extended
machine, as only a single kernel could run at a time. This lead to the
development of "pseudo-machines" or "virtual machine monitors", which used the
bare machine interface to provide many copies of that _same_ bare machine
interface for the purposes of kernel development. Further, these virtual
machine monitors could be _nested_, so long as the appropriate resource
mappings were set up in hardware ahead of time. There was some debate around
"pure" virtual machine monitors as opposed to "impure" VMMs at this time!
"Impure" VMMs presented an extended bare machine interface to the guest; the
guest machine was aware of the virtualization.

IBM implemented virtual machine monitors on the System/370 using a feature of
the processors' protection rings. Whenever a non-privileged program performed a
privileged operation, the processor hardware would fault. The VMM trapped these
privilege faults; mapping incoming requests for resources and operations to
appropriate backing resources without the knowledge of the guest operating
system. In his July 1974 article ["A Survey of Virtual Machine
Research"][a-survey-of-vm-research], Robert P. Goldberg noted that the primary
difficulty in implementing efficient virtualization of machines lies in the
lack of comprehensive hardware support for trapping "privilege-sensitive"
instructions. Indeed, the month prior, he and Gerald J. Popek proposed a
definition for "virtualizable architecture" in ["Formal Requirements for
Virtualizable Third Generation Architectures"][formal-requirements-vm].
Even today, virtualizable architectures can be set to meet "Popek and Goldberg
virtualization requirements"[^third-gen].

[<img width="640" src="https://www.neversaw.us/img/virtual-machine-organization.png" alt="Survey of Virtual Machine Research: Robert P. Goldberg, COMPUTER magazine June 1974" />](https://www.neversaw.us/img/virtual-machine-organization.png)
<sup>Illustration of VMM, extended machine, and interfaces from ["Survey of Virtual Machine Research"][a-survey-of-vm-research], Robert P. Goldberg, COMPUTE June 1974</sup>

So why did virtual machine monitor research halt for so many years?

The Mansfield amendments, passed 1969 and 1973, narrowed the scope of
Department of Defense funds to projects with direct military applications. This
cut public funding for operating systems research. The General Electric 635
used to build MULTICS at MIT cost as much as a passenger jet. MULTICS had been
over-budget and behind schedule for years; Bell Labs pulled out of the MULTICS
project in 1969. The aftermath of the OS research era left many useful ideas
floating in the ether, while virtual machine monitor research would freeze
until the late 1990s[^ibm]. 

<iframe src="https://archive.org/embed/byte-magazine-1984-11/page/n229/" width="640" height="480" frameborder="0" webkitallowfullscreen="true" mozallowfullscreen="true" allowfullscreen></iframe>
[](https://archive.org/details/byte-magazine-1984-11/page/n229/mode/2up)

Many researchers from the Project MAC days joined up at Xerox PARC. There they
developed the Xerox Alto and Smalltalk, which prefigured the modern personal
computer. By the late 1970s, commercial personal computers were available to
consumers: the Apple II, Tandy TRS-80, and others. The IBM PC launched in 1981,
the Apple Lisa in 1983, and the Macintosh in 1984. The earliest versions of
these computers only ran a single program at a time, typically in conjunction
with a disk operating system (**"DOS"**); later they would run many processes
cooperatively. There was only one user and thus, no need to worry about
time-sharing &mdash; these systems could be written to assume cooperation between
all programs running on the machine[^that-said]. In 1982, Intel released the first
commercial chips capable of protected mode operation & on-die memory mapping in
the form of the 80286 processor[^gates-brain-dead]. Taken together with the
rise of high-performance workstations, Microsoft, Intel, and IBM's PC rapidly
chipped away at the market for time-shared minicomputers.

For the most part, those workstations ran a variant of UNIX.

Dennis Ritchie, Ken Thompson, Douglas McIlroy, and Joe Ossanna developed UNIX
at Bell Laboratories in the aftermath of Bell's strategic retreat from the
MULTICS project. UNIX benefited from its circumstances: a small
team[^small] with little supervision working on a comparatively cheap computer
(the PDP-7) proved able to iterate on the best ideas in operating systems
research rapidly. Douglas McIlroy managed the department. Douglas was
[particularly animated][mass-produced] by the possibilities code reuse
unlocked. UNIX did not start out as a time-sharing system, nor was it a
preemptive operating system. It wasn't much more than a filesystem supporting a
game [at first][history-unix].

[history-unix]: https://www.bell-labs.com/usr/dmr/www/hist.html
[mass-produced]: https://www.cs.dartmouth.edu/~doug/components.txt

> Back around 1970-71, Unix on the PDP-11/20 ran on hardware that not only did
> not support virtual memory, but didn't support any kind of hardware memory
> mapping or protection, for example against writing over the kernel. This was
> a pain, because we were using the machine for multiple users. When anyone
> was working on a program, it was considered a courtesy to yell "A.OUT?"
> before trying it, to warn others to save whatever they were editing. 
>
> - ["A hardware story"][history-odd], Dennis Ritchie, 2002 

The initial system was multiprogrammed &mdash; that is, there were two, time-shared
shell processes running, one for each terminal connected to the machine. When
the shell executed another program, it would read the file in over the top of
the shell code and start executing it. The `exit()` syscall would reload the
shell program over the top of the shell and restart execution. Support for a
_tree_ of processes was added rapidly, however. UNIX inherited [Conway's
`fork/join` semantics][conway-fork] from Project GENIE as `fork/exec`: one
command to make a duplicate of the current process as a child of the forking
process, and a second command run in that child process to replace the
duplicate with the target code. This model of copying processes using
prototypal inheritance directly enabled the containerization models we talked
about earlier (Linux eventually grew `clone` and `unshare` to handle removing
privilege from new processes early.)

By 1977 work was underway to port UNIX from the PDP-11 to the Interdata 8/32,
as we noted way back in [the first post in this series][part-1]. (The work had
been validated by porting a copy of UNIX to an IBM System/370 virtual machine.)
With the support of Sun Microsystems, IBM, HP, and others, UNIX and C had swept
through the industry by the late eighties. Entering the 90's, "virtual machine"
came to refer primarily to language virtual machines, like Smalltalk and
Erlang. Consumer operating systems were converging on preemptive, protected
time-sharing, buoyed by advances in Intel's commercial hardware. Hardware
virtualization features, if supported, primarily existed to support older DOS
programs.

First and foremost, UNIX succeeded as **a user interface**. Not necessarily in the
traditional sense, but rather as a programmer's work bench. The system put
forward a comparatively simple, unified model of programming. UNIX inherited
code sharing and linking from MULTICS. This code sharing and linking was
powerful, but ultimately subordinate to the system's user interface. Code
linked into a program shared that program's resources, capabilities, and access
to the system interface.

---

## Return to the fork in the road

The rapid growth of the internet in the mid-90's rekindled virtualization
research. Scaling a website meant procuring and provisioning hardware. This
could not be done quickly. Internet companies were required to expend
considerable money well in advance of expected traffic and were largely unable
to recoup costs if that traffic did not materialize. The industry was looking
for a way to commoditize hardware.

x86 was the most popular processor architecture with the best economies of
scale and broadest software support. However, it could not be virtualized
directly: privileged instructions and memory operations would silently fail
without triggering traps.

> Unfortunately, many current architectures are not strictly virtualizeable.
> This may be because either their instructions are non-virtualizeable, or they
> have segmented architectures that are non-virtualizeable, or both.
>
> Unfortunately, the all-but-ubiquitous Intel x86 processor family has both of
> these problematic properties, that is, both non-virtualizeable instructions
> and non-reversible segmentation. Consequently, no [Virtual Machine Monitor]
> based exclusively on direct execution can completely virtualize the x86
> architecture.
>
> - ["Virtualization System Including a Virtual Machine Monitor For a Computer
>   With Segmented Architecture"][vmware-patent], United States Patent #6,397,232

The late 90's saw a growing interest in direct binary translation (**"DBT"**.)
The hegemony of the x86 processor was predicted to crumble. Efforts such as
DAISY and Transmeta's Crusoe bet against the continued popularity of x86.
Meanwhile, in the language virtual machine space, just-in-time compilation
research blossomed. VMWare was founded in this context, submitting a
[patent][vmware-patent] early on for a direct-binary-translation method of implementing
virtual machine monitors for the x86 architecture.

VMWare's virtual machine monitor worked thusly: entering or exiting a
protection ring triggered the translator, which monitored for execution of
untrapped privileged instructions and inject manual VMM trap calls. This
enabled virtualization but added overhead to every system call.

Because DBT added uneven overhead to kernel execution, it was difficult to
associate system use with virtual machine execution. This prevented accurate
billing systems from being constructed around such virtual machines.

["Xen and the Art of Virtualization"][xen] changed all of that.

> By allowing 100 operating systems to run on a single server, we reduce the
> associated costs by two orders of magnitude. Furthermore, by turning the
> setup and configuration of each OS into a software concern, we facilitate
> much smaller-granularity timescales of hosting.
>
> - ["Xen and the Art of Virtualization"][xen], 2003

Xen achieved this through paravirtualization: instead of pure virtualization,
it achieved "impure", cooperative virtualization by modifying the guest operating
systems. In particular, Xen moved the operating system _out_ of the most
protected ring of the processor: from ring 0 to ring 1. Processes continued to
run in ring 3. This gave the operating system its own "extended machine": while
it lost access to privilege instructions, it gained access to its own
supervisory call system ("hypervisor calls".)

[<img width="640" src="https://www.neversaw.us/img/xen-perf.png" alt="Xen and the Art of Virtualization: Comparison of native Linux, Xen, VMWare Workstation, and User-mode Linux" />](https://www.neversaw.us/img/xen-perf.png)
<sup>Comparison of native Linux, Xen, VMWare Workstation, and User-mode Linux on various benchmarks, from ["Xen and the Art of Virtualization"][xen]. Note that OLTP represents relational database workloads and WEB99 represents web-serving.</sup>

In particular, Xen's performance on web application workloads was a breakthrough.

A few notes on timing: by 2003, the dotcom bubble had burst. The servers that
internet startups had loaded up on flooded the market with cheap used hardware,
causing Sun Microsystems to hemorrhage money. At Amazon, [Benjamin
Black][ben-black-ec2] circulated a document describing a standardized
infrastructure; Bezos tasked Chris Pinkham with developing this in 2004. EC2
launched publicly in 2006, [powered by Xen][xen-announce]. [According to Steve
Yegge][stevey], sometime in 2002-2003 or so, Bezos issued his famous "services
edict", stipulating that all Amazon engineering teams deliver their work in the
form of networked services. By 2009, Netflix had moved their video encoding
operations to AWS. Netflix finished transitioning to the cloud in 2011. And
again, just as a reminder, Docker launched in 2013.

Service oriented architectures &mdash;composed from hundreds of tiny web
microservices making tiny remote procedure calls to one another over
HTTP&mdash; roamed the earth. You might have wondered earlier why two engineers
would come into conflict over a network port on a single machine.

Well, now you know why!

---

> Hardware is really just software crystallized early. It is there to make
> program schemes run as efficiently as possible. But far too often the
> hardware has been presented as a given and it is up to software designers to
> make it appear reasonable. [...]
>
> As Bob Barton used to say: "Systems programmers are high priests of a low
> cult." 
>
> - ["An Early History of Smalltalk"][smalltalk-history], Alan Kay

Cloud virtual machines commoditized hardware, severing the connection between
"procuring and provisioning hardware" and "scaling a web service."

As with memory mapping and protection rings in the 80s, consumer hardware
lagged behind the market's needs. AMD and Intel introduced hardware support
for virtualization of x86(\_64) architectures in 2005 through SVM and VT-X,
respectively. ARM added hardware virtualization support in Cortex-A in 2011[^popek].

Hardware virtualization support allowed operating systems to integrate
hypervisor capabilities: Windows Server added Hyper-V (2008); Linux, Kernel
Virtual Machines ("KVM", 2006); and macOS, Hypervisor.framework (2020). (EC2
started moving from Xen to KVM-based "Nitro" virtual machines in 2017. Brendan
Gregg wrote more about the path from the first version of Xen to Nitro
[here][gregg-nitro].) In lieu of running Xen or VMWare, consumer operating systems
themselves became capable of running guest operating systems, accelerating the
development of new hypervisor software.

---

The core innovation of Docker is not the underlying containerization
technology. As we've established: the underpinnings of the OCI format predate
Docker by many years. Docker's innovation is in its user interface around
authoring, sharing, and running container images. This reusability led to the
creation of standardized orchestration software; virtual machine images have
yet to catch up to this level of popular reusability.

From the hardware perspective, processes and guest operating systems look
nearly the same. Virtualizing the system at the process layer means sharing
more code between the virtualized systems with a finer granularity of
abstractions, but has the advantage of being achievable purely through
software: hardware can't really tell the difference between a container and any
other process.

Because virtualizing the system at the hardware interface layer is more
coarse-grained with less shared code, VMMs are generally considered safer
targets for multi-tenancy &mdash;that is, running untrusted code from third parties
collocated on the same hardware[^meltdown-spectre]. On the other hand, VMMs are
generally perceived as introducing more startup overhead. However, in recent
years, containers and VMMs have converged: Kata containers, AWS' Firecracker,
and others use the container user interface but run the containers inside
lightweight virtual machines, achieving remarkable performance, security, and
density[^comparisons].

---

The more efficiently tasks can be collocated, the better the margins on
equipment; this is a competitive edge for a hosting company. Processes,
whether virtual machines or containers, have overhead. Switching between
processes takes time and memory; density experiments as of TKTK 202X have shown 10K
containers running on a single host. This was a natural place to look for
improvements, and so content delivery networks &mdash; which handle some of the
highest volume of traffic on the internet &mdash; started digging into the problem.
Fastly and Cloudflare both landed on web technologies, launching products
in 2018.

Cloudflare launched Workers, which co-locates many user tasks in a single
process using V8 isolates. V8 is, as we discussed previously, the JIT
JavaScript engine open-sourced by Google as part of their Chrome browser.
Workers customers upload JavaScript applications that implement the
ServiceWorker spec; Cloudflare deploys the application to their edge network, with points
of presence across the globe. As a bonus, since WebAssembly support is
available through the web platform API, users that really needed to could
target WASM. (Though they'd be responsible for writing their own bindings to
the ServiceWorker API.)

Fastly launched Compute@Edge, skipping JavaScript in favor of WebAssembly. But
this posed a problem. While JS could rely on the Web platform as a system
interface, WASM does not automatically provide one. In order to hook WASM up to
their edge compute, Fastly had to _define_ an interface: one that was stable
and versioned.

---

## Enter WASI (finally)

Fastly, Intel, and Mozilla teamed up in 2019 to form the Bytecode Alliance.
Their goal was to define a specification for a standard system interface for
WebAssembly[^and-cranelift-and-wasmtime-but].

The WebAssembly ISA allows imports and exports: functions that the host can
pass _in_ to the WASM module for internal use, and functions that the WASM
module can hand back to the host to be called _by_ the host on demand. The host
may also provide a chunk of memory for the WASM module to operate on. Imported
and exported functions may only take primitive values &mdash; integer and floating
point values of various widths. The host and module may cooperate to transfer
more complicated types. For example, the host and module might agree that a string
is represented as an integer pointer into the module's memory along with an
integer length. 

This is a _lot_ like the sort of **ABI** a process **System Interface** uses.

In fact, the first preview release of WASI explicitly mimicked the POSIX system
interface &mdash; roughly speaking, the system interface common to all variations of
UNIX systems. This differed from contemporary tools, like emscripten and
wasm-bindgen, which treat the interface between the host and WASM module as an
internal detail. Those tools were designed to take an existing application and
get it running in a browser with minimal changes, generating both WASM, HTML,
and the JavaScript to integrate the WASM with the Web Platform. If one were to
recompile an application with a newer version of emscripten and try to drop the
WASM onto an older version of the HTML and JS, it may not work. Likewise, the
WASM from an application compiled with wasm-bindgen could not be dropped onto
emscripten HTML and JS or vice versa. They are not **ABI** compatible.

WASI existed to enable multiple compilers and hosts. It would be a [thin
waist][thin-waist] for WebAssembly[^triple].

---

The first preview of WASI launched in 2019. While it included many POSIX
concepts, it omitted full support for network sockets and process forking.
These features are key to supporting high-performance network servers. The
omission was intentional: system interface ABIs don't just define the boundary
between a process and kernel. They're also used to enable software _linking_ --
the reuse of compiled artifacts: shared objects (`.dylib`, `.so`, or `.dll`.)
Linking can be performed at compile time (static linking) or at process start
(dynamic linking.) While shared object linking wasn't defined as part of the
first WASI preview, neither did the specifiers wish to preclude it in future
versions of the specification.

The standard approach to sockets would have exposed too much power between
linked modules. Sockets are typically represented as a "descriptor" or "handle"
in the form of an integer the operating system hands to the process on request.
Operations on the socket are performed by making a system call referencing that
integer, and all linked modules are assumed to have access to the same system
interface. This model is difficult to secure: malicious linked modules can
"sniff" for active descriptors. The system can't differentiate between linked
modules and the core application logic when receiving calls referencing the
descriptors.

The problem with the POSIX model is that the system interface forms a
monolithic wall between the kernel and the user process, leaving
undifferentiated space on either side. The ABI emphasizes the importance of the
system interface _over_ the importance of the interface between libraries.

Finding a solution to this problem took time.

The second preview of WASI proposes a solution: the WASM component model. This
defines a static linking approach for combining many WASM core modules in a
single file. This proposal is in stage 1, which means that many popular WASM
tools and runtimes do not yet implement it. Despite this, WASI preview 2 hinges
on this proposal, which defines a new interface definition language called
"WebAssembly interface types" ("WIT".) WIT allows for the definition of named
functions, groups of functions, and high-level types like strings and structs.
WIT also allows for groupings-of-groupings with requirements around exports and
imports, called "worlds". WIT worlds can be used to generate host code or as a
target for compiling shared code.

This allows sockets to be represented as higher level objects whose full
capabilities aren't transferred between linked modules, as opposed to an
integer descriptor tracked by the host. (See Dan Gohman's excellent ["No
Ghosts!"][no-ghosts] for more on this.)

WASI preview 2 appears to be targeting a release this year. At the time of
writing the component model proposal is only in stage 1, so many popular tools
and runtimes do not support WASM components (or WASI preview 2.) And many
platform-as-a-service (**"PaaS"**) startups have appeared since Solomon Hyke's tweet.

In the meantime, companies have proposed alternative system interfaces: Deis
labs introduced WAGI in 2020. WAGI sidesteps the issue of missing POSIX support
by using WASI preview 1's standard input and output instead of sockets. This is
reminiscent of the venerable "common gateway interface" (**"CGI"**) from the
1990s. Fermyon, a WASM PaaS company, supports WAGI through its Spin framework.

In 2023, Wasmer introduced WASIX. WASIX, a superset of WASI, aims to target
more of the POSIX API. This is akin to an Emscripten for server applications,
with the goal of lowering the barrier between existing web services and PaaS
WASM companies. Like Emscripten, WASIX values easy portability of existing
applications. As a result, it doesn't editorialize too much on the POSIX API.
At the time of writing, WASIX doesn't support shared object linking. While WASIX
doesn't preclude linking shared objects in the future, it seems likely that it
would follow the existing linking model, for good or ill[^ba-wasix].

---

The common thread through every technology we've talked about is that they were
all created to make it easier for people to work together. To lower the barrier
of cooperation. Processes made it possible to write programs separately,
containers made it possible to use OS resources without up-front coordination,
VMMs made it possible to decouple infrastructure scaling from procuring
hardware. Each of these take a direct conversation between two components and
move it to a third party, an interface. They form a minimal agreement &mdash; the
smallest contract that one must agree to in order to work seamlessly with any
other party that also agrees.

WASI, through the web component model, revises the UNIX system interface,
narrowing it from a programmer's workbench to a secure computing environment.
Taken to the extreme, the WASM component model reinvents the operating system
process model to take modern needs into account. It promises secure
multi-tenancy at runtime while lowering the barrier to cooperation between
library authors and application programmers. From my (maybe optimistic?)
perspective, it's on the cusp of a Docker moment. The technologies that
underpin Docker predated Docker by years. Docker bundled them together and made
it easy to share one's work with others. What does WASM's moment look like?

----------------------------------------------------------------------------------------------------------------------------------------------------------------

## Epilogue

I'm excited to announce that I'll be joining Dylibso as of this month to work
on WASM materials, tools, and smooth out friction in the ecosystem wherever I
find it.

Working on these posts has been hugely educational for me on a number of
levels, and I'd like to thank everyone who reviewed these posts &mdash; C J
Silverio, Eric Sampson, and Aria Stewart &mdash; helped source research &mdash; Ron Gee,
-- and encouraged me. In particular I'd like to thank my family: my wife,
Krysten, and my parents, Mark and Sue, for dealing with an entire summer of me
talking non-stop about writing these posts and reviewed the most radioactive,
unfit-for-human-consumption drafts of these posts ("WASM good? why?")

----------------------------------------------------------------------------------------------------------------------------------------------------------------

## Bibliography and Timeline

So many PDFs this time around!

I'd like to call out ["The Ideal Versus the Real: Revisiting the History of
Virtual Machines and Containers"][ideal-real] by Allison Randal, which dives
more deeply into the history and interrelations between these technologies than
my effort here. Give it a read!

- 1961\. ["Dynamic Storage Allocation in the Atlas Computer"][atlas], John Fotheringham, 
- 1961\. ["One-level storage system"][one-level], Kilburn, Edwards, Lanigan, Sumner
- 1961\. Compatible Time-Sharing System first operational
- 1962\. Atlas Computer operational
- 1963\. ["A multiprocessor system design"][multiprocessor-system-design], Melvin E. Conway
- 1964\. Compatible Time-Sharing System in operational use
- 1964\. IBM System/360
- 1965\. GE 645 hardware simulated at MIT for MULTICS
- 1965\. ["Segmentation and the Design of Multiprogrammed Computer Systems"][segmentation-and-the-design] - Jack B. Dennis
    - cites 1961 "one-level storage system"
- 1966\. ["Programming Semantics for Multiprogrammed Computations"][programming-semantics] - Jack B. Dennis, Earl C. Van Horn
    - cites 1963 "A multiprocessor system design"
- 1967\. GE 645 hardware received at MIT
- 1968\. ["Virtual Memory, Processes,and Sharing in MULTICS"][multics-virtual-memory] - Robert C. Daley, Jack B. Dennis
- 1969\. [UNIX v1 running on a pdp-7][unix-hist]
- 1969\. MULTICS replaces GECOS on GE 645
- 1970\. "Virtual Memory", Peter Denning
    - cites 1961 "one-level storage"
    - cites 1961 "dynamic storage allocation"
    - cites 1966 "Programming Semantics for Multiprogrammed Computations" Jack B. Dennis, Earl C. Van Horn
- 1970\. IBM System/370 released
- 1971\. [UNIX moved to the PDP-11][unix-1st-ed]
- 1973\. ["Virtual machine or virtual operating system"][virtual-machine-or-virtual-operating-system], Bellino, J, C Hans
    - this seems a LOT like paravirtualization and/or containers &mdash; could not achieve full performance
      virtualizing an entire IBM 360 machine, so the VMM provided "higher level" primitives
- 1974\. ["Survey of Virtual Machine Research"][a-survey-of-vm-research], Robert P. Goldberg
    - cites bellino/hans 1973 re: "pure" vs "impure" virtual machines
- 1979\. UNIX v7, introduction of `chroot`
- 1979\. ["Software Engineering in 1968"][sw-in-1968] - B. Randell
- 1981\. ["The Origin of the VM/370 Time-Sharing System"][origin-vm-370] - R. J. Creasy
- 1982\. `chroot` added to BSD
- 1998\. immunix apparmor introduced
- 1998\. VMWare x86
- 1999\. [Resource Containers][resource-containers]
- 2000\. [FreeBSD jails][jails]
- 2000\. SELinux first released OSS
- 2001\. linux vserver
- 2001\. [VMWare releases gsx][vmware-gsx], first x86 server virtualization product
- 2002\. VMWare patent - ["Virtualization System Including a Virtual Machine Monitor For a Computer With Segmented Architecture"][vmware-patent], United States Patent #6,397,232
- 2002\. linux namespaces (2.4.19); mount namespace
- 2002\. linux security modules
- 2003\. ["Xen and the Art of Virtualization"][xen]
- 2003\. SELinux merged into linux kernel (2.6.0-test3)
- 2003\. [Work on AWS EC2 kicks off][ben-black-ec2]
- 2004\. [Solaris Zones][solaris-zones]
- 2005\. [OpenVZ (open virtuzzo)](https://wiki.openvz.org/History)
- 2005\. [intel vt-x, amd-v][gregg-nitro]
- 2006\. Slicehost launched
- 2006\. ["Multiple instances of the global linux namespaces"][global-linux-namespaces] - Eric W. Biederman
- 2006\. AWS EC2 first released - built on xen virtualization
- 2007\. ["Adding Generic Process Containers to the Linux Kernel"][process-containers] - Paul B. Menage, Google
- 2007\. cgroups lands in linux kernel (2.6.24); final form of google process containers
- 2007\. KVM lands in the linux kernel (forked QEMU added KVM support)
- 2008\. LXC released
- 2008\. Microsoft launches Hyper-V for windows server
- 2009\. AWS VPC launch, ELB, Autoscaling, Cloudwatch
- 2009\. Netflix moves movie encoding to the cloud
- 2009\. Canonical adopts apparmor
- 2010\. Netflix moves account signup, etc to the cloud
- 2010\. Hyper-V support [merged into libvirt][libvirt-hyper-v]
    - > In 2010, Bolte et al. incorporated support for Hyper-V into
      libvirt, so it could be managed through a standardized interface,
      together with Xen, QEMU+KVM, and VMware ESX.
- 2011\. Netflix's entire operation is on the cloud
- 2012\. [KVM support merged into mainline QEMU][qemu-kvm]
- 2013\. user namespaces land in the linux kernel (3.8); this completes support for containers [1]
- 2013\. Docker released (based on LXC)
- 2013\. LMCTFY ("Let me contain that for you")
- 2014\. Kubernetes released
- 2014\. Docker Swarm released
- 2014\. docker-compose v1
- 2014\. Docker replaces LXC with `libcontainer`
- 2014\. Canonical begins work on `lxd`, orchestration for LXC containers
- 2015\. Terraform released
- 2015\. Consul released
- 2015\. Hashicorp releases first version of vault, nomad
- 2015\. Docker spins `runc` out of its container runtime
- 2016\. dirty cow container CVE (https://blog.paranoidsoftware.com/dirty-cow-cve-2016-5195-docker-container-escape/)
- 2016\. CRI-O launched
- 2016\. docker-compose v2
- 2016\. LXD released
- 2017\. docker-compose v3
- 2018\. Kata, gVisor, Nabla
- 2019\. CRI-O handed over to cncf
- 2019\. Docker Swarm start of 2-year EOL
- 2020\. ["The Ideal Versus the Real: Revisiting the History of Virtual Machines and Containers"][ideal-real] - Allison Randal

[atlas]: https://www.andrew.cmu.edu/course/15-440/assets/READINGS/fotheringham1961.pdf
[one-level]: https://www.dcs.gla.ac.uk/~wpc/grcs/kilburn.pdf
[qemu-kvm]: https://lists.gnu.org/archive/html/qemu-devel/2012-12/msg00123.html

---

[^docker]: Which would later be rebranded as "Docker", after their most famous
    product.

---

[^port]: A port is a numbered resource, managed by an operating system,
    representing a stream of incoming or outgoing network requests.

---

[^init]: Init processes are responsible for setting up the userland system:
    they are the root of the tree of userland processes; setting up daemons for
    resolving DNS, networking, devices, filesystem mounts, and more.

---

[^borg]: AKA ["Borg"][borg].

---

[^bsd]: It's out of scope for this post, but suffice it to say that UNIX
    split in the 80's and 90's: roughly, Linux, BSD, and SysV. Linux provides
    the kernel of popular distributions like Redhat, CentOS, Ubuntu, Debian,
    and Android. BSD provides a specification for a kernel for operating
    systems: most conspicuously, Apple's modern operating systems and SunOS.
    SunOS's successor, Solaris, was based on AT&T's UNIX System V, along with
    HP's HP-UX and IBM's AIX.

---

[^java-killed]: Plan 9! Which, as you'll recall from the last article, Java
    killed! In the 80s and 90s, "virtual machine" in the sense of "system
    emulation" had withered so far as to be supplanted by "virtual machine"
    meaning "language model runtime."

---

[^openvz]: Ok, I'm adding this one as a footnote because this is a long post
    already. I'm only going to gesture at linux-vserver, which was focused on scaling
    webservers through containerized networking. However, Virtuozzo (and its successor project,
    OpenVZ) approached containerization for an entirely different reason: to enable
    checkpoint/restore of work on high-performance batch clusters. This would allow
    relocation of processes between computers ("nodes") in a cluster by namespacing
    all of their system resources. This required maintaining patches against the linux
    kernel at the time, so as far as I can tell it never really took off, but it did
    spawn the ["Checkpoint and Restore in Userspace" (**"CRIU"**) project][criu].

---

[^selinux]: And I didn't touch on SELinux, which the NSA contributed to the Linux kernel
    for, um, _reasons_

---

[^bss]: "BSS" is also known as "better save space".

---

[^hey]: Hey, there's that "machine" word again.

---

[^yuri]: Which had _nothing at all_ to do with Yuri Gagarin's recent orbital trip, I'm _sure_.

---

[^mac]: "MAC" expanded to "Mathematics and Computation" early on, later
    expanding to "Multiple Access Computer", "Machine Aided Cognitions", and
    "Man and Computer". It also funded the MIT AI lab.

---

[^its]: MIT also originated the "Incompatible Time Sharing", which would give
    us EMACS.

---

[^words]: A "word" in this case refers to the number of bits the hardware was optimized to process.
    You're probably reading this on a device with a native word size of 64-bits, but in the past 32-
    and 16-bit word sizes were common. In the distant past, you might see 36-bit words!

---

[^tricks]:  There are are all sorts of neat tricks that paging enables, including "copy on
    write" pages &mdash; mapping the same memory to different places in the same
    address space, and only creating copies of them when they're mutated.

---

[^third-gen]: "Third Generation Architecture" refers to the generation of
    computers designed in the 1960's using early integrated circuits; these are
    typically called "minicomputers". They were succeeded by fourth generation
    architecture in the early 1970's which began to use microprocessors.

---

[^ibm]: IBM continued to ship virtual machine monitor systems throughout this
    period. However, they were primarily focused on virtualizing earlier
    technologies, like mainframes and minicomputers, on top of newer hardware.

---

[^that-said]: Now, that said, that assumption was frequently (and spectacularly) invalidated.

---

[^gates-brain-dead]: Gates called these processors "brain dead". At the time,
    IBM and Microsoft were co-developing OS/2 for the IBM PC, and IBM wanted to
    target the 286. However, the protection modes of the 286 were "one-way" --
    once the processor entered protected mode, re-entering real mode required
    restarting the system.

---

[^small]: The benefits of a small team are made evident through this quote, which
    is a prime example of [Conway's Law][conway]:

> Where under Unix one might say
> 
>     ls >xx
> 
> to get a listing of the names of one's files in xx, on Multics the notation was
> 
>     iocall attach user_output file xx
>     list
>     iocall attach user_output syn user_i/o
> 
> Even though this very clumsy sequence was used often during the Multics days,
> and would have been utterly straightforward to integrate into the Multics
> shell, the idea did not occur to us or anyone else at the time. I speculate
> that the reason it did not was the sheer size of the Multics project: the
> implementors of the IO system were at Bell Labs in Murray Hill, while the
> shell was done at MIT. We didn't consider making changes to the shell (it was
> their program); correspondingly, the keepers of the shell may not even have
> known of the usefulness, albeit clumsiness, of iocall. [...]
>
> Because both the Unix IO system and its shell were under the
> exclusive control of Thompson, when the right idea finally surfaced, it was a
> matter of an hour or so to implement it. 
>
> ["The Evolution of the Unix Time-sharing System"][unix-history], Dennis M. Ritchie, 1996

---

[^popek]: Indeed, ARM Cortex's virtualization support is specifically marketed as
    meeting "Goldberg and Popek virtualizability requirements"!

---

[^meltdown-spectre]: This is notwithstanding the [Meltdown and Spectre][meltdown-spectre] vulnerabilities.
    Meltdown exploits a race condition between memory access and privilege checking and affects operating
    systems and hypervisors. Exploits allow processes and VMs to read memory across security boundaries,
    effectively breaking the illusion of virtual memory. Spectre exploits speculative execution &mdash;
    a property of modern superscalar processors. Speculative execution executes every code path leading
    out from a branch point, throwing away the results from the paths not taken. However, this speculative
    execution can affect caches, so the path not taken may be observed by measuring operation timings after
    the fact.

---

[^comparisons]: For an in-depth look at how containerization and virtualization
    approaches compare in terms of performance on various axes, check out ["A
    Fresh Look at the Architecture and Performance of Contemporary Isolation
    Platforms"][a-fresh-look].

---

[^and-cranelift-and-wasmtime-but]: And to develop the Cranelift, Wasmtime, and WASM Micro
    Runtime (**"WAMR"**) projects.

---

[^triple]: This is where we get the `wasm32-wasi` target triple (and why it's
    different from `wasm32-unknown-unknown`.

---

[^ba-wasix]: The Bytecode Alliance has taken a [dim view][infoworld-wasix] of WASIX.

----------------------------------------------------------------------------------------------------------------------------------------------------------------


[process-containers]: https://www.kernel.org/doc/ols/2007/ols2007v2-pages-45-58.pdf
[aws-ec2-virtualization-2017-introducing-nitro]: https://www.brendangregg.com/blog/2017-11-29/aws-ec2-virtualization-2017.html
[sw-in-1968]: https://dl.acm.org/doi/pdf/10.5555/800091.802915
[libvirt-hyper-v]: https://past.date-conference.com/proceedings-archive/2010/DATE10/PDFFILES/05.6_3.PDF
[vmware-gsx]: https://web.archive.org/web/20060827064533/http://www.vmware.com/news/releases/gsx_win_release.html
[resource-containers]: https://www.usenix.org/legacy/publications/library/proceedings/osdi99/full_papers/banga/banga.pdf
[origin-vm-370]: https://pages.cs.wisc.edu/~stjones/proj/vm_reading/ibmrd2505M.pdf
[virtual-machine-or-virtual-operating-system]: https://dl.acm.org/doi/pdf/10.1145/800122.803946
[unix-hist]: https://www.bell-labs.com/usr/dmr/www/hist.html
[unix-1st-ed]: https://www.bell-labs.com/usr/dmr/www/1stEdman.html
[programming-semantics]: https://dl.acm.org/doi/10.1145/365230.365252
[multiprocessor-system-design]: https://dl.acm.org/doi/10.1145/1463822.1463838
[segmentation-and-the-design]: https://dl.acm.org/doi/pdf/10.1145/321296.321310
[a-fresh-look]: https://dl.acm.org/doi/pdf/10.1145/3464298.3493404
[berferd]: https://www.cheswick.com/ches/papers/berferd.pdf
[unix-history]: https://www.bell-labs.com/usr/dmr/www/hist.html
[criu]: https://criu.org/Main_Page
[stevey]: https://courses.cs.washington.edu/courses/cse452/23wi/papers/yegge-platform-rant.html
[xen-announce]: https://aws.amazon.com/blogs/aws/amazon_ec2_beta/
[ben-black-ec2]: http://blog.b3k.us/2009/01/25/ec2-origins.html
[netscape-scaling]: https://www.usenix.org/legacy/publications/library/proceedings/lisa95/full_papers/mosedale.txt
[jails]: http://www.watson.org/~robert/freebsd/sane2000-jail.pdf
[global-linux-namespaces]: https://www.kernel.org/doc/ols/2006/ols2006v1-pages-101-112.pdf
[solaris-zones]: https://www.usenix.org/legacy/publications/library/proceedings/lisa04/tech/full_papers/price/price.pdf
[cpuland]: https://cpu.land/
[formal-requirements-vm]: https://dl.acm.org/doi/pdf/10.1145/361011.361073
[a-survey-of-vm-research]: https://web.eecs.umich.edu/~prabal/teaching/eecs582-w11/readings/Gol74.pdf
[vmware-patent]: https://patents.google.com/patent/US6397242B1/en
[xen]: https://www.cl.cam.ac.uk/research/srg/netos/papers/2003-xensosp.pdf
[smalltalk-history]: http://worrydream.com/EarlyHistoryOfSmalltalk/
[no-ghosts]: https://blog.sunfishcode.online/no-ghosts/
[infoworld-wasix]: https://www.infoworld.com/article/3700569/wasix-undermines-webassembly-system-interface-spec-bytecode-alliance-says.html
[fastly-compute-at-edge]: https://vimeo.com/291584445
[gregg-nitro]: https://www.brendangregg.com/blog/2017-11-29/aws-ec2-virtualization-2017.html
[history-odd]: https://www.bell-labs.com/usr/dmr/www/odd.html
[conway-fork]: https://dl.acm.org/doi/pdf/10.1145/1463822.1463838
[borg]: https://research.google/pubs/pub43438/
[ideal-real]: https://dl.acm.org/doi/fullHtml/10.1145/3365199
[part-1]: @/20230510-understanding-wasm-pt-1.md
[part-2]: @/20230630-understanding-wasm-pt-2.md
[llva]: https://llvm.org/pubs/2003-10-01-LLVA.pdf
[meltdown-spectre]: https://meltdownattack.com/
[philopp]: https://os.phil-opp.com/paging-introduction/
