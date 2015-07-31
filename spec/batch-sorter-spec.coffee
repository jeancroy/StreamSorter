BatchSorter = require '../src/batch-sorter'

compareTo = (a, b)-> a.localeCompare(b)

mergeRef = (A, B) ->
  C = A.concat(B)
  C.sort(compareTo)
  return C

mergeLists = (A, B) ->
  BatchSorter.mergeLists(A, B, compareTo)

describe "async callback", ->
  it "call the callback with a sorted list of all the elements so far", (done) ->

    #using done parameter to block test until we finished all async call
    refArray = []
    sortedArray = []
    nbCalls = 0

    #This one verify each intermediary step is valid
    sortedCallback = (sortedList) ->
      refArray = refArray.sort(compareTo)
      expect(sortedList).toEqual(refArray)
      sortedArray = sortedList
      nbCalls++

    sorter = new BatchSorter(onSort: sortedCallback)
    callback = sorter.insert

    #Simulate a process that output results one-per-one
    # 1005 is chosen so we don't fit exactly with chunk size
    i = -1
    nbItems = 1005
    while(++i < nbItems)
      str = (Math.random() * 1e10).toString(36)
      refArray.push(str)
      callback(str)

    #compare to nbCalls
    expectedCalls = Math.ceil(nbItems / sorter.batchSize)

    #This one verify that we have consumed all elements after the fact
    # Using (timeout)
    FinalCallback = ->
      refArray = refArray.sort(compareTo)
      expect(sortedArray).toEqual(refArray)
      expect(nbCalls).toEqual(expectedCalls)
      done()

    setTimeout(FinalCallback, 2 * sorter.timeout)

  it "is able to cancel a search to process another one", ->

    #using done parameter to block test until we finished all async call
    refArray = []
    sortedArray = []
    nbCalls = 0

    #This one verify each intermediary step is valid
    sortedCallback = (sortedList) ->
      refArray = refArray.sort(compareTo)
      expect(sortedList).toEqual(refArray)
      sortedArray = sortedList
      nbCalls++

    sorter = new BatchSorter(onSort: sortedCallback)
    callback = sorter.insert

    #Simulate a process that output results one-per-one
    # 1005 is chosen so we don't fit exactly with chunk size
    i = -1
    nbItems = 210
    while(++i < nbItems)
      str = (Math.random() * 1e10).toString(36)
      refArray.push(str)
      callback(str)


    #Simulate a new search
    sorter.update() # process last batch
    refArray.length = 0 # clean the reference array
    sorter.reset() # clean the sorter array

    i = -1
    while(++i < nbItems)
      str = (Math.random() * 1e10).toString(36)
      refArray.push(str)
      callback(str)

    #compare to nbCalls
    expectedCalls = 2 * Math.ceil(nbItems / sorter.batchSize) + 1

    #this time instead of Timeout, we are going to force the end to be processed.
    sorter.update()

    #This one verify that we have consumed all elements after the fact
    refArray = refArray.sort(compareTo)
    expect(sortedArray).toEqual(refArray)
    expect(nbCalls).toEqual(expectedCalls)


describe "merging", ->
  it "can merge with empty set", ->
    A = []
    B = ["aa", "BB", "cc"]
    C = mergeRef(A, B)

    expect(mergeLists(A, B)).toEqual(C)
    expect(mergeLists(B, A)).toEqual(C)

  it "can merge alternating results", ->
    A = ["aa", "cc", "ee"]
    B = ["bb", "dd", "ff"]
    C = mergeRef(A, B)

    expect(mergeLists(A, B)).toEqual(C)
    expect(mergeLists(B, A)).toEqual(C)

  it "can merge results with duplicate", ->
    A = ["aa", "cc", "ee"]
    B = ["aa", "dd", "dd"]
    C = mergeRef(A, B)

    expect(mergeLists(A, B)).toEqual(C)
    expect(mergeLists(B, A)).toEqual(C)

  it "can merge alternating results with consecutive", ->
    A = ["aa", "bb", "ee", "ee"]
    B = ["cc", "dd", "ff", "ff"]
    C = mergeRef(A, B)

    expect(mergeLists(A, B)).toEqual(C)
    expect(mergeLists(B, A)).toEqual(C)

  it "can merge alternating results with tail", ->
    A = ["aa", "cc", "ee"]
    B = ["bb", "dd", "ff", "gg", "hh"]
    C = mergeRef(A, B)

    expect(mergeLists(A, B)).toEqual(C)
    expect(mergeLists(B, A)).toEqual(C)


  it "can merge results in insertion mode", ->
    A = ["aa", "bb", "cc", "dd", "ee", "gg", "hh", "ii", "jj", "ll", "mm", "nn", "pp", "qq", "rr"]
    B = ["ff", "kk", "oo"]
    C = mergeRef(A, B)

    expect(mergeLists(A, B)).toEqual(C)
    expect(mergeLists(B, A)).toEqual(C)

  it "can transition from insertion mode to merge", ->
    A = ["aa", "bb", "cc", "dd", "ee", "gg", "hh", "ii", "jj", "ll", "mm", "nn", "pp", "qq", "rr", "za", "zc", "ze",
         "zh"]
    B = ["ff", "kk", "oo", "zb", "zd", "zf", "zg", "zi"]
    C = mergeRef(A, B)

    expect(mergeLists(A, B)).toEqual(C)
    expect(mergeLists(B, A)).toEqual(C)

