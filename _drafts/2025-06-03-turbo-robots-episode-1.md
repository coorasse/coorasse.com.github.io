---
layout: post
title: "Turbo Robots - Episode 1"
date: 2025-06-03
categories: rails
excerpt: "What is Turbo Robots and how I started building it..."
---

## CS Robots

I got my degree in Computer Science back in 2006 [in Bologna](https://www.unibo.it/en/homepage).
Among all the exams I took, we implemented an interesting game called CS Robots, for the exam of "Programmiong
Languages".

In 2016, 10 years after that exam, I wrote to my [professor](https://upsilon.cc/~zack/), because I was looking for the
specs of that project but I could not find them online anymore.

Luckily, [he still had them](/assets/csrobots.pdf) (in italian)!

CSRobots is a multiplayer game inspired by a previous year edition
of [The ICFP Programming Contest](http://icfpc.eecs.northwestern.edu/spec.html).

The rules are simple: a set of robots compete on a 2D map to grab as many packages as possible and bring them to
destination.
The game is turn-based, and each robot, on each turn, can choose one action:

* move in a cardinal direction
* pick a package
* drop a package

If a robot "pushes" another robot, the packages are dropped on the ground.

There are also walls and water on the ground and some more rules, but I don't want to go too much into the details of
the rules yet.

## Re-implement CS Robots

The Exam was about implementing both the game server and also an AI for the robots, so that we could challenge other
students.

In 2017 I decided to re-implement the game engine in ruby following the same specification.

The game server is started with a map description and a list of items, and then waits for players to connect via a TCP.

When all players are connected, the game starts, and on each turn it waits for the commands from the players, and
updates the game status.

```
# this is a simple map with two home bases, some water and walls
 
@.....
.@~...
.####.
.~~~..
.~~...
......
```

```
# and this is a list of items and players

robot 1 200 100 @ (0,2)
robot 2 200 100 @ (2,0)
package 0 10 (0,0) @ (0,2)
package 1 20 (1,1) @ (2,0)
package 2 40 (1,1) @ (2,0)
package 3 40 (1,1) @ (2,0)
```

and here is the game running!

<iframe width="560" height="315" src="https://www.youtube.com/embed/Iu2ox7X_0c4" title="CS Robots demo" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## The next steps

After implementing the game engine, I started thinking: "How can I re-invent the game, by using the technologies I like?
What else can I do which would be funny?"

The plan was simple: bring it to the web! Make it possible to create a room, and let people join the game and challenge
each other.

But has it happens with many thing in life, it was not really on my priority list, and I never really got to it.
Nothing has happened until 2025.
