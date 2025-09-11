---
layout: post
title: "Latency simulation"
date: 2025-09-11
categories: rails
mermaid: true
excerpt: "A little script to simulate network latency when developing locally"
---

Sometimes we need to simulate, locally, how our app behaves under network latency.
I don't really like "Slow Network" simulation in Browser or including a fake "sleep" in my Rack Middleware, so I wrote a little script
that simulates the Network Latency on a specific port on your Mac.

[Here you find the gist](https://gist.github.com/coorasse/aaae0fad63e27bda2344cf22090924ed)

Here is how to use it:

```bash
# Enable latency simulation (120±30ms jitter on port 3000)
./bin/simulate_latency enable

# Enable custom latency simulation (150±30ms jitter on port 3000)
./bin/simulate_latency enable 150

# Enable custom latency and jitter (200±50ms jitter on port 3000)
./bin/simulate_latency enable 200/50

# Enable latency simulation on custom port (120±30ms jitter on port 8080)
./bin/simulate_latency enable -p 8080

# Enable custom latency and jitter on custom port (150±50ms jitter on port 8080)
./bin/simulate_latency enable 150/50 -p 8080

# Test the latency
./bin/simulate_latency test

# Check current status
./bin/simulate_latency status

# Disable and clean up
./bin/simulate_latency disable
```

