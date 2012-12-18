###
Class which manages the windows in one tile and handles resize/move and
property change events.
@class
###
Tile = (firstClient, tileIndex) ->
  
  ###
  Signal which is triggered whenever the user starts to move the tile.
  ###
  @movingStarted = new Signal()
  
  ###
  Signal which is triggered whenever the user stops moving the tile.
  ###
  @movingEnded = new Signal()
  
  ###
  Signal which is triggered whenever the geometry changes between
  movingStarted and movingEnded.
  ###
  @movingStep = new Signal()
  
  ###
  Signal which is triggered whenever the user starts to resize the tile.
  ###
  @resizingStarted = new Signal()
  
  ###
  Signal which is triggered whenever the user stops resizing the tile.
  ###
  @resizingEnded = new Signal()
  
  ###
  Signal which is triggered whenever the geometry changes between
  resizingStarted and resizingEnded.
  ###
  @resizingStep = new Signal()
  
  ###
  Signal which is triggered when the geometry of the tile changes because
  of something different to a user move or resize action.
  ###
  @geometryChanged = new Signal()
  
  ###
  Signal which is triggered whenever the tile forced floating state
  changes. Two parameters are passed to the handlers, the old and the new
  forced floating state.
  ###
  @forcedFloatingChanged = new Signal()
  
  ###
  Signal which is triggered whenever the tile is moved to a different
  screen. Two parameters are passed to the handlers, the old and the new
  screen.
  ###
  @screenChanged = new Signal()
  
  ###
  Signal which is triggered whenever the tile is moved to a different
  desktop. Two parameters are passed to the handlers, the old and the new
  desktop.
  ###
  @desktopChanged = new Signal()
  
  ###
  List of the clients in this tile.
  ###
  @clients = [firstClient]
  
  ###
  Index of this tile in the TileList to which the tile belongs.
  ###
  @tileIndex = tileIndex
  
  ###
  True if this tile has been marked as floating by the user.
  ###
  @floating = false
  
  ###
  True if this tile has to be floating because of client properties.
  ###
  @forcedFloating = @_computeForcedFloating()
  
  ###
  True if this tile is currently moved by the user.
  ###
  @_moving = false
  
  ###
  True if this tile is currently moved by the user.
  ###
  @_resizing = false
  
  ###
  Stores the current screen of the tile in order to be able to detect
  movement between screens.
  ###
  @_currentScreen = firstClient.screen
  
  ###
  Stores the current desktop as this is needed as a desktopChanged
  parameter.
  ###
  @_currentDesktop = firstClient.desktop
  @syncCustomProperties()

###
Sets the geometry of the tile. geometryChanged events caused by this function
are suppressed.

@param geometry New tile geometry.
###
Tile::setGeometry = (geometry) ->
  @clients[0].geometry = geometry


# TODO: Inhibit geometryChanged events?

###
Saves the current geometry so that it can later be restored using
restoreGeometry().
###
Tile::saveGeometry = ->
  @_savedGeometry = @clients[0].geometry  if @_savedGeometry?


# TODO: Inhibit geometryChanged events?

###
Restores the previously saved geometry.
###
Tile::restoreGeometry = ->
  @clients[0].geometry = @_savedGeometry


# TODO: Inhibit geometryChanged events?

###
Returns the currently active client in the tile.
###
Tile::getActiveClient = ->
  active = undefined
  @clients.forEach (client) ->
    active = client  if client.isCurrentTab

  active


###
Synchronizes all custom properties (tileIndex, floating between all clients
in the tile).
###
Tile::syncCustomProperties = ->
  @clients[0].tiling_tileIndex = @tileIndex
  @clients[0].tiling_floating = @floating
  @clients[0].syncTabGroupFor "tiling_tileIndex", true
  @clients[0].syncTabGroupFor "tiling_floating", true

Tile::_computeForcedFloating = ->
  forcedFloating = false
  @clients.forEach (client) ->
    forcedFloating = true  if client.shade or client.minimized or client.keepAbove or client.fullScreen or not client.resizeable

  forcedFloating

Tile::_updateForcedFloating = ->
  forcedFloating = @_computeForcedFloating()
  return  if forcedFloating is @forcedFloating
  @forcedFloating = forcedFloating
  @forcedFloatingChanged.emit not forcedFloating, forcedFloating

Tile::onClientShadeChanged = (client) ->
  @_recomputeForcedFloating()

Tile::onClientGeometryChanged = (client) ->
  return  unless client.isCurrentTab
  
  # If the screen has changed, send an event and reset the saved geometry
  unless client.screen is @_currentScreen
    @_currentScreen = client.screen
    @_savedGeometry = null
    @screenChanged.emit()
  return  if @_moving or @resizing
  
  # TODO: Check whether we caused the geometry change
  @geometryChanged.emit()

Tile::onClientKeepAboveChanged = (client) ->
  @_recomputeForcedFloating()

Tile::onClientKeepBelowChanged = (client) ->


# TODO: Only floating clients are not below all others
Tile::onClientFullScreenChanged = (client) ->
  @_recomputeForcedFloating()

Tile::onClientMinimizedChanged = (client) ->
  @_recomputeForcedFloating()

Tile::onClientMaximizedStateChanged = (client) ->


# TODO: Make tiles floating as soon as the user maximizes them
Tile::onClientDesktopChanged = (client) ->
  return  unless client.isCurrentTab
  oldDesktop = @_currentDesktop
  @_currentDesktop = client.desktop
  @desktopChanged.emit oldDesktop, @_currentDesktop

Tile::onClientStartUserMovedResized = (client) ->
  
  # We want to distinguish between moving and resizing, so we have to wait
  # for the first geometry change
  @_lastGeometry = client.geometry

Tile::onClientStepUserMovedResized = (client) ->
  newGeometry = client.geometry
  if newGeometry.width isnt @_lastGeometry.width or newGeometry.height isnt @_lastGeometry.height
    if @_moving
      @movingEnded.emit()
      @_moving = false
    if @_resizing
      @resizingStep.emit()
    else
      @_resizing = true
      @resizingStarted.emit()
  if newGeometry.x isnt @_lastGeometry.x or newGeometry.y isnt @_lastGeometry.y
    if @_resizing
      @resizingEnded.emit()
      @_resizing = false
    if @_moving
      @movingStep.emit()
    else
      @_moving = true
      @movingStarted.emit()
  @_lastGeometry = newGeometry

Tile::onClientFinishUserMovedResized = (client) ->
  if @_moving
    @movingEnded.emit()
    @_moving = false
  else if @_resizing
    @resizingEnded.emit()
    @_resizing = false
  @_lastGeometry = null
