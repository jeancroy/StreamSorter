{binarySearch} = require './batch-sorter'

#
# Insert an item into a sorted list using binary search.
#
# Main difference vs batch is that onSort will be call on every item insert
# Except once per chunk. Second argument of onSort is the last item instead of
# the last batch.
#
# Everything that serve to manage batch is not present either
# (update, timeout, batchsize)
#
# For process that tend to spit item very fast we believe batch behavior is usefull.
#

localeCompare = if Intl? then (new Intl.Collator()).compare else (a, b) -> a.localeCompare(b)

module.exports =
  class InsertSorter

    constructor: ({@onSort, @onSortContext, @compareFn, key} = {})->
      @onSort ?= null #If not using callback, one can use instance.getSorted()
      @onSortContext ?= this
      # If compareFn is provided, use it
      # Else build one using key and localeCompare
      unless @compareFn?

        if key? and key.length
          @compareFn = (a, b) ->
            localeCompare(a[key], b[key])
        else
          @compareFn = localeCompare

      sortedList = []
      insertPoint = -1

      @insert = (item) =>
        insertPoint = InsertSorter.insertItem(sortedList, item, @compareFn, insertPoint)
        @onSort?.call(@onSortContext, sortedList, item)

      @update = =>
        #Nothing to update but stay compatible with batch api
        @onSort?.call(@onSortContext, sortedList, null)

      @finish = =>
        @update()
        @reset()

      @reset = =>
        sortedList = []
        insertPoint = -1
        @onSort?.call(@onSortContext, sortedList, null)

      @getSorted = ->
        return sortedList


    #
    # Insert item in list - In place
    # hint is hte first pivot, set to -1 if you don't know.
    # Return position
    #

    @insertItem = (list, item, compareFn, hint) ->
      n = list.length
      unless n
        list.push(item)
        return 0

      #Optimistic insert ( globally sorted)
      if compareFn(item, list[n - 1]) >= 0
        list.push(item)
        return n

      if hint > -1 and compareFn(item, list[hint]) >= 0
        insertPoint = binarySearch(item, list, -1, hint, compareFn)
      else
        insertPoint = binarySearch(item, list, hint, n, compareFn)

      list.splice(insertPoint, 0, item)
      return insertPoint