+++
title = "Colophon"
+++

# Colophon

I'm dividing this post into **two** parts: the prosaic "how" and
the maybe-more-interesting "why".

## How

This blog is delivered to you by the [Cloudflare] Content
Delivery Network (or [CDN]) via their free plan, which enables
[SSL], asset minification, and 1-2 page rules. The page rules
are how `http://neversaw.us` ("**h**o**t** **p**o**t**ato") redirects to
`https://neversaw.us` ("**h**o**t** **p**o**t**atoe**s**"), and and
`https://neversaw.us` redirects to `https://www.neversaw.us/`.)

The CDN is configured to read HTML, CSS, and JavaScript (and, yanno,
[whatever] else [I upload]) from an Amazon AWS [S3 Bucket], configured
in website mode.

Of course, I'm not writing HTML right now; we'll cover how what
I'm typing in my editor gets to you shortly though. First, let's
review how I set these things up!

I provision all of my infrastructure resources with [Terraform],
and [you can see how it's configured here][ref-conf]. My personal
infrastructure repo uses [direnv] to automatically install all of
the tools I need. You can see that configuration [here][ref-direnv].
I use [1Password] to store my credentials, and load them into my
shell on demand by [sourcing] this [file]. The file uses the 1Password
CLI to access a well-known key in my vault, containing my AWS credentials
in the form of Bash environment variables.

Now, as for my editing interface: I'm writing this in a folder on my mac laptop
using [NeoVim]. The folder is actually symlinked from `~/blog` to
`~/Dropbox/Apps/neversawus-blog`. Whenever I edit files in this blog directory
the development [Dropbox] application [webhook] sends a request to a URL I've
configured, backed by an AWS [API Gateway] endpoint. This calls an AWS [Lambda]
that sends [GitHub repository dispatch events] to my
[`chrisdickinson/neversaw.us`] repository.

(The Lambda and Gateway setup are in my Terraform configuration, but they're pretty
much taken from [this excellent Hashicorp guide].)

When `chrisdickinson/neversaw.us` receives a dispatch event, it runs a [GitHub
Action]. The action [generates this site] by downloading the current state from
Dropbox, then running it through [Zola], a static site generator written in [Rust].
(The Rust part isn't actually important except that I really enjoy Rust and want more
people to try it out. It's part of the reason I selected Zola, but I'm happy to
report I'm very happy with all of Zola's features thus far!)

Finally, the action takes the rendered HTML, CSS, and JavaScript, and uploads it
to the aforementioned S3 Bucket.

There's a potential for race conditions, but thus far I haven't really run into
any -- and in any case, I'm one "Save file" action away from fixing the problem.

And that's how you're seeing what you're seeing right now.

![Flowchart depicting the flow](/img/blog-flow.png?foo)

---

## Why

Programmers rebuild their blogs often. I, personally, have rebuilt this blog
about five or six times. Each prior time, I focused on the _technical_ features
I wanted and lost sight of the experience & content I wanted to create. This is
nearly a trope for programmers.

When building a documentation generator for [Boltzmann], I found that Zola had
all the technical features I had always wanted, which got me thinking: I had always
(re)built my blog from the perspective of these features, and I rarely blogged in
it after the fact. The writing is the point of the blog, and for whatever reason
I had always stopped short.

A few things were floating around my head at this point.

I had lunch with a friend a few months back. Over a gigantic breakfast burrito, he
mentioned that he was moving off of Twitter because it was taking up too much of
his writing attention.

Later, I saw [this tweet]:

> git is just dropbox where you have to write a tweet before it syncs, don't judge me

And it clicked for me. I wasn't writing in my blog because I was focusing my attention
elsewhere, namely Twitter and Slack. Twitter's innovation was in reducing the friction
between having a thought and communicating that thought to the world, no matter how
ill-advised it might be.

On the other hand, writing a blog post was a _ceremony_ for me. I'd write it, edit it,
make sure the CSS and JS were perfect, then I'd commit it to Git and push it up. In the
process I'd get so distracted by the framing of the content that I'd usually forget to
_keep writing content_.

**It has to be easier for me to write in my blog than to write a tweet.**

Which leads us to here -- I write in a text file, save it, it gets rendered and
uploaded, and now you're reading it. The framing is not great, BUT. The other
brainwave I had was this: I kept redesigning my blog before I had any content
in it. I was trying to create a design system ex nihilo; no wonder it had never
felt right! I am forcing myself to feel discomfort about it until I have enough
content to warrant framing it differently.

In [Gall's words]:

> A complex system that works is invariably found to have evolved from a simple
> system that worked. A complex system designed from scratch never works and
> cannot be patched up to make it work. You have to start over with a working
> simple system.

I am starting a simple system of creating content. I will improve the styling
and framing of that content slowly as I build more content. All of my prior
attempts were focused on features and styling for content that wasn't there
yet. I'm only four days into this experiment, but I'm (foolishly) optimistic.

Being able to type in my favorite editor like this and reach you on a platform
I control -- that I'm not renting from Twitter, where I'm not taking space from
other people who need it more -- that feels like a sea change to me.

[SSL]: https://en.wikipedia.org/wiki/Transport_Layer_Security
[CDN]: https://en.wikipedia.org/wiki/Content_delivery_network
[Cloudflare]: https://www.cloudflare.com/
[whatever]: https://www.neversaw.us/scratch/terrain/
[I upload]: https://www.neversaw.us/scratch/interFACE/
[S3 Bucket]: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html
[Terraform]: https://www.terraform.io/
[ref-conf]: https://github.com/chrisdickinson/infrastructure/blob/2d12ff5cb04cb2d9c20b486297ab80660cfdde61/terraform/project/neversawus.tf
[direnv]: https://direnv.net/
[ref-direnv]: https://github.com/chrisdickinson/infrastructure/blob/2d12ff5cb04cb2d9c20b486297ab80660cfdde61/.envrc
[1Password]: https://1password.com/
[sourcing]: https://linuxize.com/post/bash-source-command/
[file]: https://github.com/chrisdickinson/infrastructure/blob/2d12ff5cb04cb2d9c20b486297ab80660cfdde61/bin/activate-credentials
[GitHub repository dispatch events]: https://help.github.com/en/actions/reference/events-that-trigger-workflows#external-events-repository_dispatch
[Lambda]: https://aws.amazon.com/lambda/
[NeoVim]: https://neovim.io/
[Dropbox]: https://www.dropbox.com/
[webhook]: https://www.dropbox.com/developers/reference/webhooks
[API Gateway]: https://aws.amazon.com/api-gateway/
[`chrisdickinson/neversaw.us`]: https://github.com/chrisdickinson/neversaw.us
[this excellent Hashicorp guide]: https://learn.hashicorp.com/terraform/aws/lambda-api-gateway
[GitHub Action]: https://github.com/features/actions
[generates this site]: https://github.com/chrisdickinson/neversaw.us/blob/latest/.github/workflows/dropbox.yml
[Zola]: https://www.getzola.org/
[Rust]: https://www.rust-lang.org/
[Boltzmann]: https://github.com/entropic-dev/boltzmann/
[this tweet]: https://twitter.com/joonturbo/status/1269962891928702976
[Gall's words]: https://en.wikipedia.org/wiki/John_Gall_(author)#Gall.27s_law
