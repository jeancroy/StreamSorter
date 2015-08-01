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
      return (-3335.8067091423522 + p * (23643.0955865774 + p * (-43286.12456833472 + 22904.14729923425 * p)) + n * (1636.8084654821425 + (2635.560841017351 - 4232.493186202444 * p) * p + n * (-93.6758233644279 + p * (-10233.108898740347 + (17588.580248152506 - 7291.954638062817 * p) * p) + n * (-0.4935062149687636 + p * p * (-11.785544394349214 + 11.651732476612649 * p))))) / (-0.00003121798283734385 + p * (-1668.9539756752508 + p * (18.591279770624233 + 1607.1046862937417 * p)) + n * (12261.914867073949 + p * (-20130.388956094033 + 7908.056711577546 * p) + n * (-8655.848901646224 + p * (15430.56388099079 + (-6310.420547545677 - 472.861080740064 * p) * p) + n * (-3.676084178370719 + p * p * (2.470864314346661 + p)))))