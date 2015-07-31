#
# BatchSorter:
#
#    - Accumulate and sort all results
#    - Callback is called after processing a batch
#
#    - Batch end at first of two condition:
#        - `batchSize` new results have been added since last call
#        - `timeout` ms elapsed since start of new batch (first unprocessed result)
#

# For speed MDN recommend using Intl.Collator.compare() over string.localeCompare()
localeCompare = if Intl? then (new Intl.Collator()).compare else (a, b) -> a.localeCompare(b)

module.exports =
  class BatchSorter

    constructor: ({@onSort, @onSortContext, @compareFn, @batchSize, @timeout, key} = {}) ->
      @onSort ?= null #If not using callback, one can use instance.getSorted()
      @onSortContext ?= this
      @batchSize ?= 100
      @timeout ?= 50 #Max number of time we are willing to wait to collect `batchSize` items

      # If compareFn is provided, use it
      # Else build one using key and localeCompare
      unless @compareFn?

        if key? and key.length
          @compareFn = (a, b) ->
            localeCompare(a[key], b[key])
        else
          @compareFn = localeCompare

      # Keep private internal state in closure
      sortedList = []
      workList = []
      run = []

      mergeTimeout = null
      dirty = false #is there result waiting to be merged in ?

      #
      # CALLBACKS
      #

      #
      # Update:
      # Merge all pending result to main list and call onSort
      #

      @update = =>
        if mergeTimeout
          clearTimeout(mergeTimeout)
          mergeTimeout = null

        return unless dirty

        if(run.length)
          workList = BatchSorter.mergeLists(workList, run, @compareFn)
          run = []

        sortedList = BatchSorter.mergeLists(sortedList, workList, @compareFn)
        dirty = false

        @onSort?.call(@onSortContext, sortedList, workList)
        workList = []

      #
      # Insert:
      # Append last item to current run
      # Manage update as needed
      #

      @insert = (item) =>
        return unless item?

        unless dirty
          dirty = true
          mergeTimeout = setTimeout(@update, @timeout) if @timeout > 0

        n = run.length
        if n is 0 or @compareFn(item, run[n - 1]) >= 0
          #follow the running sequence
          run.push(item)

        else if n > 8

          # the new item break the consecutive sequence
          # merge what we currently have into workList and start a new run
          workList = BatchSorter.mergeLists(workList, run, @compareFn)
          run = [item]

        else

          # break the consecutive sequence BUT the list is small
          # standard practice in that case is insertion sort
          i = n - 2
          while i >= 0 and @compareFn(item, run[i]) < 0  then i--
          run.splice(i + 1, 0, item)


        if(workList.length + run.length >= @batchSize)
          @update()

      #
      # Reset:
      # Clear sorted result, pending and timeout
      #

      @reset = =>
        clearTimeout(mergeTimeout)
        mergeTimeout = null
        sortedList = []
        workList = []
        run = []
        dirty = false
        @onSort?.call(@onSortContext, sortedList, workList)

      @finish = =>
        @update() #this will trigger onSort
        @reset()

      @isDirty = ->
        return dirty

      @getSorted = ->
        @update() #this will trigger onSort
        return sortedList

    ###

      mergeLists: Merge two sorted list

      When merge task looks like inserting a few record into a large list
      the task is said to be sparse and algorithm behave like
      a binary insertion sort.

      When both list are about the same order of magnitude,
      the algorithm behave like a merge sort.

    ###

    @mergeLists: (A, B, compareFn) ->
      m = A.length
      n = B.length

      #One of the sequence is empty ?
      return B.slice() unless m
      return A.slice() unless n

      #Possible to simply concat ?
      if compareFn(B[0], A[m - 1]) >= 0
        return A.concat(B)

      if compareFn(A[0], B[n - 1]) >= 0
        return B.concat(A)


      #Hold merged results
      results = new Array(m + n)

      #Index for A, B, Result
      i = 0
      j = 0
      k = -1

      #
      # Merge using Binary search
      # Repeat until Both sequence are about the same size
      #

      # To narrow the search region, find position of last element of B in A.
      # (Only do it if we can amortize the cost of doing so. m>>n, n not so small)
      endPoint = if m < 2 * n then m else @binarySearch(B[n - 1], A, i - 1, m, compareFn)

      while j < n and (endPoint - i) > (n - j)

        Bj = B[j++]

        #Search the position Bj would have in A using binarySearch
        insertPoint = @binarySearch(Bj, A, i - 1, endPoint, compareFn)

        #Insert from A until we reach insertPoint
        while i < insertPoint
          results[++k] = A[i++]

        #Insert Bj and forward j
        results[++k] = Bj

        #Try to insert a chunk from B
        if i < m and j < n
          Ai = A[i]
          Bj = B[j]

          while compareFn(Ai, Bj) >= 0
            results[++k] = Bj
            break if ++j is n
            Bj = B[j]


      #
      # Finish merge using sequential read
      # Continue until one sequence is consumed
      #

      if i < m and j < n

        Ai = A[i]
        Bj = B[j]

        loop

          if compareFn(Ai, Bj) >= 0
            results[++k] = Bj # Bj is before Ai
            break if ++j is n # Move to next B or stop if last one
            Bj = B[j]
          else
            results[++k] = Ai # Ai is before Bj
            break if ++i is m # Move to next A or stop if last one
            Ai = A[i]

      # Append remaining sequence to result
      # (Only one of the two loop should execute)

      while i < m
        results[++k] = A[i++]

      while j < n
        results[++k] = B[j++]


      return results


    @binarySearch: (ref, A, start, stop, compareFn) ->

      #
      # Initial condition:
      #  - start is before first char of the string (-1)
      #  - stop is after last char of the string (str.length)
      #
      # End condition :
      #  - stop is a suitable insert point:
      #     - A[stop] is first element of A > to ref
      #     - A[stop] == ref (compareTo == 0)
      return start unless stop - start > 1

      pivot = Math.floor(0.5 * (start + stop))
      Apv = A[pivot]
      cmp = -1

      while start < pivot and cmp isnt 0

        # Half the range start..stop depending on how ref compare to pivot value
        cmp = compareFn(ref, Apv)
        if( cmp <= 0 ) then stop = pivot # Ref is in the first half of start..stop
        else start = pivot # Ref is in the second half of start..stop

        # Get next pivot position and it's value
        # Because of floor it'll collapse with start when there's
        # no element between start and stop.
        pivot = Math.floor(0.5 * (start + stop))
        Apv = A[pivot]


      return stop