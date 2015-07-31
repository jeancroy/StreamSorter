
#Batch sorter behavior:

##A) Collect Natural runs.

 Natural runs occurs because path traversal mechanism is naturally sorted.
 Some things however break the natural sort such as
   - Breadth-first search like behavior (we queue the sibling to be processed before the childs)
   - Multi thread consumption of the queue.

 Natural run is fast, 1 compare + 1 push.
 Run continue until a result break the consecutive set OR they achieve a specified size.
 (See processing list -> `batchSize`)

##B) Build a processing list.

 Inserting element in the middle/start of a list is slow.
 For example inserting a single element at 2nd position of a 10000
 item list need to move 9998 item by one position.

 The processing list need to be:
   - small enough to insert run without too much move-by-one.
   - big enough to make it worthwhile to modify all-results list.

  The parameter `batchSize` control that and default to 100.

  Should the search end before we reach `batchSize` OR
  Should the search be in a expensive region where no more positive result are produced
  => the parameter `timeout` will merge even if less than `batchSize`

  The parameter `batchSize` also force a natural run to be merged-in
  Even if we could push more consecutive.

##C) Merge to main list.
  Mostly similar to merging run into a working list
  Except we do a callback at the end.

##D) Flush main list
   When making a new search & want to discard old results
   sorter.reset()