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
      # Approximate Excel TINV(0.05, x) using a rational polynomial
      x = n - 1
      return (0.6813385285594412 + x * (1.2378905903200863 + x * (0.7579613851685434 + 1.9599638724577304 * x))) / ( x * (0.18860237272648464 + x * (-0.8236504085001869 + x)))

    @conf = (n, p) ->
      # Same as conf95 but one can set % of confidence, for example p=0.95
      # Approximate Excel TINV(1-p, n-1)
      return NaN if n < 2
      return (-0.09885109619420941 + p * (-29.01691938497005 + (59.64240920576879 - 30.516540354035055 * p) * p) + n * (1.2921673205541255 + p * (33.1881110965942 + p * (-72.0118109535133 + 37.50625520711292 * p)) + n * (-0.5166429166502322 + p * (3.6375638432756454 + (-3.8163215564453967 + 0.7073335964596834 * p) * p) + n * (-0.05505801919740953 + p * (-6.945097686211525 + (13.100805904515038 - 6.1048872053246965 * p) * p))))) / (-31.58809384501511 + p * (63.97249061287353 + (-33.240833726203036 + 0.8675463202201616 * p) * p) + n * (37.9403952167396 + p * (-92.56554351181734 + (69.93234776527507 - 15.322767828943942 * p) * p) + n * (0.5319400879402869 + p * (5.625121349959861 + p * (-11.374536569750553 + 5.224851280849287 * p)) + n * (-6.115387527035168 + p * (12.842873029222933 + p * (-7.728670155768397 + p))))))