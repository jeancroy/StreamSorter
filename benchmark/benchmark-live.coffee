{PathScanner} = require 'scandal'
BatchSorter = require '../src/batch-sorter.coffee'
InsertSorter = require '../src/insert-sorter.coffee'
StatTimer = require './stat.coffee'

class Benchmark

  constructor: ->
    options = {
      excludeVcsIgnores: false,
      inclusions: "*",
      exclusions: "",
      includeHidden: false
    }

    # Call benchmark with an folder to scan, else scan in project root.
    target = if process.argv.length > 2 then process.argv[2] else '../'

    results = [] #sorted result normal sort
    results2 = [] #sorted result stream sort

    queue = []
    localeCompare = if Intl? then (new Intl.Collator()).compare else (a, b) -> a.localeCompare(b)

    warmupStat = new StatTimer("Warm Up")
    scanningStat = new StatTimer("Scanning (Scandal)")

    scanSortArrayStat = new StatTimer("Scanning Then Sorting (Array.sort)")
    scanSortBatchStat = new StatTimer("Scanning + Sorting (Batch)")
    scanSortInsertStat = new StatTimer("Scanning + Sorting (Insert)")


    @next = =>
      if(queue.length)
        queue.shift().apply(@)

    @run = =>
      warmUp = 5
      nbRuns = 10

      #
      # Warm UP
      # Let the compiler optimise hot loop
      # Then discard timing
      #

      i = warmUp
      while(i--)
        queue.push(step1)

      queue.push(step1Close)

      i = warmUp
      while(i--)
        queue.push(step2)

      queue.push(step2Close)

      i = warmUp
      while(i--)
        queue.push(step3)

      queue.push(step3Close)


      # END of Warmup
      queue.push(resetStat)

      #
      # Timed Run 1
      #

      i = nbRuns
      while(i--)
        queue.push(step1)

      queue.push(step1Close)

      i = nbRuns
      while(i--)
        queue.push(scan_time)

      i = nbRuns
      while(i--)
        queue.push(step2)

      queue.push(step2Close)

      i = nbRuns
      while(i--)
        queue.push(scan_time)

      i = nbRuns
      while(i--)
        queue.push(step3)

      queue.push(step3Close)

      i = nbRuns
      while(i--)
        queue.push(scan_time)

      #
      # END of benchmark, show stat
      #

      queue.push(showStat)


      # Start queue now

      @next()

    scan_time = ->
      scanner = new PathScanner(target, options)

      scanner.on 'path-found', (path) -> results.push(path)

      scanner.on 'finished-scanning', =>
        elapsed = scanningStat.stop().toFixed(3)
        console.log("Scan Only (Run #{scanningStat.run()}), took #{elapsed} ms ")
        @next()

      scanningStat.start()
      results.length = 0
      scanner.scan()


    step1 = ->
      scanner = new PathScanner(target, options)

      scanner.on 'path-found', (path) -> results.push(path)

      scanner.on 'finished-scanning', =>
        results.sort(localeCompare)
        elapsed = scanSortArrayStat.stop().toFixed(3)
        console.log("\x1b\[1m== Scan Then Array.sort() (Run #{scanSortArrayStat.run()}) ==\x1b\[22m")
        console.log("Scan Then Array.sort(), took #{elapsed} ms")

        @next()

      scanSortArrayStat.start()
      results.length = 0
      scanner.scan()

    step1Close = ->
      console.log("\n ======= \n")
      @next()


    step2 = ->
      scanner = new PathScanner(target, options)
      sorter = new BatchSorter({timeout: 0})

      scanner.on 'path-found', sorter.insert

      scanner.on 'finished-scanning', =>
        results2 = sorter.getSorted()
        elapsed = scanSortBatchStat.stop().toFixed(3)
        console.log("\x1b\[1m== Scan + Sort (Batch) (Run #{scanSortBatchStat.run()}) ==\x1b\[22m")
        console.log("Scanned + Sorted #{results2.length} items (Batch Method), took #{elapsed} ms")

        @next()

      scanSortBatchStat.start()
      scanner.scan()


    step2Close = ->
      validate()
      console.log("\n ======= \n")
      @next()


    step3 = ->
      scanner = new PathScanner(target, options)
      sorter = new InsertSorter()

      scanner.on 'path-found', sorter.insert

      scanner.on 'finished-scanning', =>
        results2 = sorter.getSorted()
        elapsed = scanSortInsertStat.stop().toFixed(3)
        console.log("\x1b\[1m== Scan + Sort (Insert) (Run #{scanSortInsertStat.run()}) ==\x1b\[22m")
        console.log("Scanned + Sorted #{results2.length} items (Insert Method), took #{elapsed} ms")

        @next()

      scanSortInsertStat.start()
      scanner.scan()

    step3Close = ->
      validate()
      console.log("\n ======= \n")
      @next()

    resetStat = ->
      scanningStat.reset()
      scanSortArrayStat.reset()
      scanSortBatchStat.reset()
      scanSortInsertStat.reset()
      @next()

    showStat = ->
      console.log("\n\x1b\[1mScan + Sort\x1b\[22m")
      console.log("===========")
      scanSortArrayStat.log()
      scanSortBatchStat.log()
      scanSortInsertStat.log()

      console.log("\n\x1b\[1mScanning Only\x1b\[22m")
      console.log("=============")
      scanningStat.log()

      console.log("\n\x1b\[1mSort Only (estimate)\x1b\[22m")
      console.log("====================")
      scan_time = scanningStat.avg()

      console.log("Array.sort():  #{(scanSortArrayStat.avg() - scan_time).toFixed(3)} ms +- #{(1.96 * StatTimer.addErrors(scanningStat,
        scanSortArrayStat)).toFixed(3)}")
      console.log("Batch sort:  #{(scanSortBatchStat.avg() - scan_time).toFixed(3)} ms +- #{(1.96 * StatTimer.addErrors(scanningStat,
        scanSortBatchStat)).toFixed(3)}")
      console.log("Insert sort:  #{(scanSortInsertStat.avg() - scan_time).toFixed(3)} ms +- #{(1.96 * StatTimer.addErrors(scanningStat,
        scanSortInsertStat)).toFixed(3)}")


    validate = ->
      if(results2.length != results.length)
        console.warn("\x1b\[1m== Missed Some items ! ==\x1b\[22m",
          "Expected #{results2.length} to be #{results.length}")

        return

      if(results2.length != results.length)
        i = -1
        n = results.length
        while ++i < n
          if(results[i] != results2[i])
            console.warn("\x1b\[1m== Wrong Sort Order ! ==\x1b\[22m, Difference at item #{i}: #{results2[i]}")
            return

      console.log("\x1b\[1m== Result Validate ! ==\x1b\[22m")


(new Benchmark()).run()
