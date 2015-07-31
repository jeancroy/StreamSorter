InsertSorter = require '../src/insert-sorter'

compareTo = (a, b)-> a.localeCompare(b)

mergeRef = (A, B) ->
  C = A.concat(B)
  C.sort(compareTo)
  return C

insertItem = (list, item) ->
  InsertSorter.insertItem(list, item, compareTo, -1)
  return list

describe "async callback", ->
  it "call the callback with a sorted list of all the elements so far (and can be reset)", ->

    #using done parameter to block test until we finished all async call
    refArray = []
    sortedArray = []
    nbCalls = 50

    #This one verify each intermediary step is valid
    sortedCallback = (sortedList) ->
      refArray = refArray.sort(compareTo)
      expect(sortedList).toEqual(refArray)
      sortedArray = sortedList
      nbCalls++

    sorter = new InsertSorter(onSort: sortedCallback)
    callback = sorter.insert

    #Simulate a process that output results one-per-one
    #nbItems smaller because we call onSort for each item instead once per batch
    # And onSort do sorting as well as jasmine testing
    i = -1
    nbItems = 0
    while(++i < nbItems)
      str = (Math.random() * 1e10).toString(36)
      refArray.push(str)
      callback(str)

    #Simulate a new search
    refArray.length = 0 # clean the reference array
    sorter.reset() # clean the sorter array

    i = -1
    while(++i < nbItems)
      str = (Math.random() * 1e10).toString(36)
      refArray.push(str)
      callback(str)

    refArray = refArray.sort(compareTo)
    expect(sortedArray).toEqual(refArray)


describe "inserting", ->
  it "can insert into empty set", ->
    list = []
    item = "aa"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)

  it "can insert after last element (Single element list)", ->
    list = ["bb"]
    item = "cc"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)

  it "can insert before first element (Single element list)", ->
    list = ["bb"]
    item = "aa"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)

  it "can insert between two element (Two element list)", ->
    list = ["aa", "cc"]
    item = "bb"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)

  it "can insert at the right position", ->
    list = ["aa", "bb", "cc", "ee", "ff"]

    item = "dd"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)

    item = "00"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)

    item = "gg"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)

    item = "cc"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)

  it "can insert with duplicate", ->
    list = ["aa", "bb", "cc", "cc", "ee", "ff"]

    item = "cc"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)

    item = "bb"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)

    item = "ee"
    ref = mergeRef(list, [item])
    expect(insertItem(list, item)).toEqual(ref)