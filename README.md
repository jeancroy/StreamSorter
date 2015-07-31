#StreamSorter

Sort data that we receive item per item. (Online sorting)
Ready to use in a event-based environment. (API organised as callback with closure to instance)

## Usage

````coffeescript
  #Setup your callback
  onSortedResults = (sortedList, lastResults) ->
       # Hi. I'm a callback and I like my result sorted
       # `sortedList` contain all the results so far & sorted

  # Setup sorter object with your callback
  # (here we add an optional key: (o) -> o.path)
  BatchSorter = require("BatchSorter")
  sorter = new BatchSorter(onSort: onSortedResults, key: "path")

  # Register the sorter with the data provider
  searcher.on 'results-found', sorter.insert
  
  searcher.search()
````

## Two main algorithm

###Batch sorter

 - Best for speed / power usage
 - Best if the data producer spit a lot of item very fast, so you can afford to be informed of the process once in a while.
 - Best if the process produce data that are locally sorted in chunk
 - Similar in principles to [Timsort](https://en.wikipedia.org/wiki/Timsort) 
    - (Mix merge sort, binary search and insertion sort)
    
Items are inserted into a local batch which is then merged into the main sorted list.
Similar to building a groceries list, then going to store once for all those items.
This is more efficient that going to the store for a single item each time you realise you need something

````coffeescript
  #Setup your callback
  onSortedResults = (sortedList, lastResults) ->
  # For BatchSorter `lastResults` is an array that contain all the elements added since last callback
````

###Insert sorter

 - Best for simplicity
 - Best if you need the sorted list for every single data produced
 - Use binary insertion sort.

````coffeescript
  #Setup your callback
  onSortedResults = (sortedList, lastResult) ->
  # For InsertSorter `lastResult` is the last item added
````


### End of batch ( apply to BatchSorter )

Batch end when 
- they reach a certain size or 
- a timeout delay elapsed since the batch start

This mean, in the following example we'll receive onSortedResults once after 100 items. Then the timeout of 50ms expire, and we receive the all 105 items sorted.

````coffeescript
  # Default option for batch size
  BatchSorter = require("BatchSorter")
  sorter = new BatchSorter(batchSize:100, timeout: 50, onSort: onSortedResults)
  
  #Process that insert 105 items
  sorter.insert(i) for i in [0..105]
````



#### Manual end of batch


##### sorter.update()
Update now, no need to wait for timeout
````coffeescript
  #Process that insert 105 items
  sorter.insert(i) for i in [0..105]
  
  #Don't want to wait, will call onSort
  sorter.update()
````

`sorter.isDirty()` can tell you if there's any pending results that would need update()

##### sorter.finish()

Like update, but will also reset data.

````coffeescript
  # Process that insert 105 items
  sorter.insert(i) for i in [0..105]
  
  # Will call onSort then clean internal sortedList
  sorter.finish()
  
  # Process that insert new items
  sorter.insert(i) for i in [106..200]
  
  # Will call onSort but leave array values to add more items
  sorter.update()
  
  # Process that insert new items
  sorter.insert(i) for i in [201..200]
  
````


### get Data

sorter.getData() will return an array with all result sorted.
This make the usage of the callback optional (for example the benchmark don't use callbacks). For batch sorter there will be an implicit call to update()

## Test

 Jasmine is used to test spec of both sorter. Multiple level of test is included.
 - Basic spec test with synthetic data.
 - Overall behavior test with random strings and verify each callback.
 - Real data test (Benchmark will validate sort order against array.sort() )

## Benchmark

We provide benchmark that show how the two StreamSorter compare against a single array.sort() at the end. Real life scenario is a bit different because we have to update the callback with sorted progress as we go. So in general we don't expect to beat a single sort after the fact.

But BatchSort is optimised for process that produces almost sorted data, and this is what we see in benchmark. Atom scandal is one of such process that produce item in sorted chunk, but chunk arrive out of order (also we only receive item one-per-one so we don't have the a priori notion of a chunk )

### Benchmark.coffee

Main benchmark will test sort order on a recorded atom/scandal output.
This is done to ensure repeatability and because file system provide alot of variability (hard to isolate only the effect of sort)

### Benchmark-live.coffee

Live benchmark will use Atom Scandal to sort this folder. For this you need to install scandal. You can also install a bunch of other stuff to make more file in the benchmark.

### Benchmark-record.coffee

Record benchmark will produce the data file for main benchmark.

### Stats.coffee

Also in the benchmark folder, an interesting statistic / timing class. It was needed to figure out number of test needed to beat file system variability.









