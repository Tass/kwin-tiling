###
Class which manages connections to a signal and allows for signal/slot event
handling.

@class
###
Signal = ->
  @connected = []

###
Method which connects another handler to the signal.

@param f Function which shall be added to the signal.
###
Signal::connect = (f) ->
  @connected.push f


###
Method which disconnects a function from the signal which as previously been
registered with connect().

@param f Function which shall be removed from the signal.
###
Signal::disconnect = (f) ->
  index = @connected.indexOf(f)
  return if index is -1
  @connected.splice index, 1


###
Calls all functions attached to this signals with all parameters passed to
this function.
###
Signal::emit = ->
  signalArguments = arguments_
  @connected.forEach (f) ->
    f.apply null, signalArguments
