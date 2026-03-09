---
title: "Code that isn't yours"
date: 2026-03-09T13:33:00+02:00
author: miniluz
# aliases: ["first"]
# showToc: true
draft: false
math: false
svg: false
---

A group project at my university has me in a group of 18 people, and quite a few
of my classmates are using AI for code generation. A lot. The constant review
and correction of what they generate are endless tasks for those of us who
supervise the project's code.

I've also learnt to use AIs to generate code, and I work with them quite a bit
now. However, the "product owners" of the project notice a clear difference
between the code and the work I do and theirs.

A big part of it is just that I know more, mostly because I've been programming
for longer. I understand a bit more about Spring Boot and how web frameworks
work than they do, and therefore I know how to better direct the LLM's plans and
identify its mistakes. Many of my classmates are less familiar with Spring Boot,
particularly how it works under the hood, so they don't have as clear a mental
model. They see some things as "magic": If you follow the right rites, things
simply work.

Lately I think a big part of a programmer's job is to carry the cognitive weight
of the project, to have a mental model of the entire system. This model is the
inevitable result of writing the code yourself, built on every error you run
into that you don't quite understand. A thousand moments that lead you to dig
deeper into how things work. Slowly you dispel the magic that frameworks
provide, until your mental model includes their internal workings (or at least
their contract and invariants). When you generate code with AI, you end up with
a much more superficial mental model. I try to avoid this by reviewing the code
AI generates line by line. But I'm not sure it's enough. My mental model of the
code is considerably weaker than it would be had I just written it myself.

Obviously I don't know as much about Spring Boot as other programmers, not by a
long shot. There are many parts of Spring Boot that are magic to me (Spring
Security, etc.). And I worry about not learning them. Since the AI does
something that just works, I don't have to wrestle with it. And this generates a
certain anxiety in me. I know what I choose not to learn, but I don't know what
exactly I'm missing out on learning.

One solution would be to go into the code and plan a change with almost
line-by-line precision, and to tell the AI to generate it. But if I'm doing
that, why not simply write it myself?

Regardless, what some of my classmates do is definitely not enough. The AI
generates the code, they check it with the tests the AI makes, and not even
those are reviewed in detail. They submit the code, but they don't carry the
cognitive load of understanding it in depth, of understanding the flow of the
data. They submit the code, but they don't do their job as programmers. They
aren't responsible for it. They don't carry that cognitive load. The ones who
end up responsible are the reviewers, if that.

---

In contrast, there's a project over which I have a complete mental model, and
over which I carry all the cognitive load: my thesis. I'm using Embassy, a very
non-magical framework for embedded platforms. All the code, the synchronization
between tasks, the control flow, I write myself. I'm able to picture in my mind
everything that happens in the system, in full detail.

This is a project where I start from things that exist and generate the code
that fulfills the purpose. It's a program built "bottom-up." Recently, I've seen
case studies about [SQLite](https://www.youtube.com/watch?v=ZP7ef4eVnac) and
[LiChess](https://www.youtube.com/watch?v=7VSVfQcaxFY), and other projects where
the developers build what they need by integrating libraries as they're needed.
The case studies conclude that what's vital to their success is that the
developers have the complete mental model in their heads, because they built the
code "bottom-up."

In that group project, I use what Spring Boot includes by default: JPA,
Liquibase, Spring Security, etc. The project feels very different from my
thesis, partly because there are parts of the code I rely on I don't understand.
And it's not only because it's code others have written. It's because I feel the
"magic" of Spring Boot. We use its organization, its systems, its dependency
injection... It includes everything, and from there we extract what we need,
"top-down."

But to a certain extent this is an advantage for a project with a large team:
there's only one "correct" way to do things, according to the framework's
philosophy. There are fewer ways to take something and whittle it to the product
you want, "top-down," than to generate it from scratch, "bottom-up." If my
thesis were a project of 18 people, it would be unmanageable to create it
writing code "bottom-up." Unless I manually decided and documented how to
organize the files, the logic, the philosophy, the API documentation. All in a
manner appropriate for embedded development. And even doing that, every
developer would have to learn it.

For this reason I don't consider the case studies to be right, or not entirely.
Many projects are of such size, both of the code and the team, that it's
impossible for any single person to have the entirety of the code in their head.
That's why it's important to make useful APIs, explicit contracts, explicit
assumptions and invariants. And "top-down" frameworks provide a common ground
for these. Their APIs, contracts, assumptions, and invariants are shared across
applications, teams, and companies.

---

But even working with small and focused teams, Spring Boot feels alien, even
compared to other backends with similar structure that I've set up from scratch.
A large part of this feeling is that I don't understand Spring Boot as well as I
understand the system I built in NestJS. If I did, I suspect I'd like it more.
But there's also something deeper.

The thing is, for me, it's really not about whether it's "bottom-up" or
"top-down." It's about control. Both AI and Spring Boot take that feeling away
from me. It's what they have in common: SQLite, LiChess, and my TFG are
relatively small projects by small groups. They're projects where it's possible
for everyone to have a complete mental model. For everyone to have control.

In large projects, this is impossible. Maybe it's not even necessary. But I
can't help feeling that it is. And I don't know if I'm right, or if my brain
simply doesn't want to give up the comfort that control provides.

It's promised that AI code generation is the future of programming. I've learned
to use the tools, and they've multiplied the speed at which I program. But I
can't help wondering if I'm actually doing my job. Is the job of a programmer
really to carry the cognitive load, or is that what I tell myself in order to
cling to control, to the feeling that led me to love programming? Am I feeling
what I feel because of AI, or because of working in a large project where I
can't control everything?

Maybe it's not necessary for everyone to carry the cognitive load. But I believe
that control and responsibility will always be in demand, even in large
projects. I believe there will always be a need for people who know enough to
build a complete mental model. To see systems for what they are, and not for
their magic. Or, in any case, at least that's what I want for myself.
