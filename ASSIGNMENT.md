# Pick a coordinator (example assignment)

Several peers, all of which can talk to each other, and exactly one of them
should be coordinating at any moment. Peers stop answering without warning.

Your problem is `Election.java`, and two methods in it.

## What to do

1. **`coordinator()`** — the id of the peer that should coordinate right now.
2. **`lost(peer)`** — called when a peer stops answering.

## What you are marked on

Whether you can defend the design in a viva — including a scheme you did not
build.
