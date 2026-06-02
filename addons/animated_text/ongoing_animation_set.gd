## OngoingAnimationSet — a reusable, saveable bundle of ongoing animations.
##
## Build a set of ongoing effects once, save it as a .tres, and drop the same
## resource on as many AnimatedRichLabel nodes as you like (assign it to the
## node's `ongoing_set` property). Edit the .tres once and every node using it
## updates.
##
## Tip: in the FileSystem dock, right-click a .tres → Duplicate to make a
## variant, or enable "Local to Scene" on the resource if you want a node to
## have its own independent copy.
##
## The node merges `ongoing_set.animations` with its own inline
## `ongoing_animations` array, so you can share a base set and still add
## per-node extras.
@tool
class_name OngoingAnimationSet
extends Resource

## The ongoing animations in this set (each is itself a reusable resource).
@export var animations: Array[OngoingAnimation] = []
