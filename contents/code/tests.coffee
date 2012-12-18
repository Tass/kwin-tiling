# Signal tests
testSignal = new Signal()
success1 = false
success2 = false
testSignal.connect (a, b, c) ->
  success1 = a is 1 and b is 2 and c is "test"

testSlot2 = (a, b, c) ->
  success2 = a is 1 and b is 2 and c is "test"

testSignal.connect testSlot2
testSignal.emit 1, 2, "test"
print "Signal test 1: " + ((if success1 and success2 then "SUCCESS" else "FAILURE"))
success1 = false
success2 = false
testSignal.disconnect testSlot2
testSignal.emit 1, 2, "test"
print "Signal test 2: " + ((if success1 and not success2 then "SUCCESS" else "FAILURE"))
