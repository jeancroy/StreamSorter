module.exports =
  class StatTimer

    constructor: (@name = "")->
      n = 0
      avg = 0
      M2 = 0
      min = 0
      max = 0

      clock = StatTimer.getClock()
      startTime = clock()

      @reset = ->
        n = 0

      @start = ->
        startTime = clock()

      @stop = ->
        x = clock() - startTime

        if(n is 0)
          n = 1
          avg = x
          M2 = 0
          min = x
          max = x

        else
          #Knuth average & variance algorithm
          n++
          delta = (x - avg)
          avg += delta / n
          M2 += delta * (x - avg)
          #Get min/max
          min = x if x < min
          max = x if x > max

        return x

      @run = ->
        return n

      @avg = ->
        return avg

      @standardDeviation = ->
        return NaN if n < 2
        return Math.sqrt(M2 / (n - 1))

      @variance = ->
        return NaN if n < 2
        return M2 / (n - 1)

      @standardError = ->
        return NaN if n < 2
        return Math.sqrt(M2 / ((n - 1) * n))

      @standardErrorSquared = ->
        return NaN if n < 2
        return M2 / ((n - 1) * n)

      @min = ->
        return min

      @max = ->
        return max

      @log = ->
        if @name && @name.length
          console.log("\x1b\[1mStats for #{@name}\x1b\[22m")

        if n < 2
          console.log("Please do at least 2 runs to get statistics.")
          return

        c95 = StatTimer.conf95(n)
        conf_mean = c95 * @standardError()
        conf_process = c95 * @standardDeviation()

        console.log("After #{n} runs, average: [ #{avg.toFixed(3)} +- #{conf_mean.toFixed(3)} ] ms, min: [ #{min.toFixed(3)} ] ms, max: [ #{max.toFixed(3)} ] ms, 95% confidence: [ #{(avg - conf_process).toFixed(3)}, #{(avg + conf_process).toFixed(3)} ] ms")

    # Best available clock
    @_clockDate = -> # Old browser
      return Date.now()

    @_clockPerf = -> # Modern browser
      return Performance.now()

    @_clockProcess = -> # Node.js
      hrtime = process.hrtime() #high resolution time [second,nanosecond]
      return 1e3 * hrtime[0] + 1e-6 * hrtime[1]


    # Clock chooser
    @getClock = ->
      if(process and process.hrtime)
        return StatTimer._clockProcess
      if(Performance and Performance.now)
        return StatTimer._clockPerf

      return StatTimer._clockDate

    @addErrors = (a, b) ->

      # When adding or subtracting measured time, one can simply add or subtract their mean.
      # To get the error of the addition/subtraction one must compute the square root of the sum of square
      # This method do it for you.
      if(a instanceof StatTimer and b instanceof StatTimer)
        return Math.sqrt(a.standardErrorSquared() + b.standardErrorSquared())

      if not isNaN(a) and not isNaN(b)
        return Math.sqrt(a * a + b * b)

      return NaN

    @conf95 = (n) ->
      return NaN if n < 2
      # How many standard deviation away from the mean to get 95% confidence interval.
      # Based on Student-T distribution with x degree of freedom, x = n-1
      # Interpolate Excel TINV(0.05, x) using a rational polynomial
      x = n - 1
      return (x * (0.9226655151301209 + x * (0.14283238369660015 + 1.9600079352240465 * x))) / (x * (0.3732618923900799 + x * (-1.1351494180472101 + x)))


  