BatchSorter = require '../src/batch-sorter.coffee'
InsertSorter = require '../src/insert-sorter.coffee'
StatTimer = require './stat.coffee'

benchmark = (data) ->
  sortArrayStat = new StatTimer("Sorting (Array.sort)")
  sortBatchStat = new StatTimer("Sorting (Batch)")
  sortInsertStat = new StatTimer("Sorting (Insert)")

  bSorter = new BatchSorter({timeout: 0})
  iSorter = new InsertSorter()

  localeCompare = if Intl? then (new Intl.Collator()).compare else (a, b) -> a.localeCompare(b)

  aSorted = []
  bSorted = []
  iSorted = []

  nbRuns = 5
  nbRepeat = 10

  k = -1
  while(++k <= nbRepeat)

    # Do one extra untimed warm-up run
    # By un-timed we mean time but discard.
    if(k == 1)
      sortArrayStat.reset()
      sortBatchStat.reset()
      sortInsertStat.reset()


    #Array.sort()
    i = nbRuns
    while i--
      aSorted = []
      sortArrayStat.start()
      aSorted.push(item) for item in data
      aSorted.sort(localeCompare)
      elapsed = sortArrayStat.stop().toFixed(3)
      console.log("Array.sort(), run #{sortArrayStat.run()}, sorting #{aSorted.length} items took #{elapsed}")


    #Batch Sorter()
    i = nbRuns
    while i--
      bSorter.reset()
      sortBatchStat.start()
      bSorter.insert(item) for item in data
      bSorted = bSorter.getSorted()
      elapsed = sortBatchStat.stop().toFixed(3)
      console.log("Batch sort, run #{sortBatchStat.run()}, sorting #{bSorted.length} items took #{elapsed}")


    #Insert Sorter()
    i = nbRuns
    while i--
      iSorter.reset()
      sortInsertStat.start()
      iSorter.insert(item) for item in data
      iSorted = iSorter.getSorted()
      elapsed = sortInsertStat.stop().toFixed(3)
      console.log("Insert sort, run #{sortInsertStat.run()}, sorting #{iSorted.length} items took #{elapsed}")


  validate("Batch method", aSorted, bSorted)
  validate("Insert method", aSorted, iSorted)

  sortArrayStat.log()
  sortBatchStat.log()
  sortInsertStat.log()


validate = (what, a, b)->
  if(b.length != a.length)
    console.warn("\x1b\[1mValidation for #{what} Missed Some items !\x1b\[22m",
      "Expected #{b.length} to be #{a.length}")

    return

  if(b.length != a.length)
    i = -1
    n = a.length
    while ++i < n
      if(a[i] != b[i])
        console.warn("\x1b\[1mValidation for #{what} Wrong Sort Order !\x1b\[22m, Difference at item #{i}: #{b[i]}")
        return

  console.log("\x1b\[1mValidation for #{what}: Result Validate !\x1b\[22m")


fs = require('fs')
zlib = require('zlib')
path = require('path')

fs.readFile path.resolve(__dirname, 'benchmark.dat'), (file_err, file_data) ->
  zlib.unzip file_data, (unzip_err, unzip_data) ->
    data = unzip_data.toString("utf-8").split("\n")
    benchmark(data)







