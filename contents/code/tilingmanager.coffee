###
Class which manages all layouts, connects the various signals and handlers
and implements all keyboard shortcuts.
@class
###
TilingManager = ->
  
  ###
  Default layout type which is selected for new layouts.
  ###
  @defaultLayout = SpiralLayout
  
  ###
  List of all available layout types.
  ###
  @availableLayouts = [SpiralLayout] #,
#        ZigZagLayout,
#        ColumnLayout,
#        RowLayout,
#        GridLayout,
#        MaximizedLayout,
#        FloatingLayout

  for i in [0...@availableLayouts.length]
    @availableLayouts[i].index = i
  
  ###
  Number of desktops in the system.
  ###
  @desktopCount = workspace.desktopGridWidth * workspace.desktopGridHeight
  
  ###
  Number of screens in the system.
  ###
  @screenCount = workspace.numScreens
  
  ###
  Array containing a list of layouts for every desktop. Each of the lists
  has one element per screen.
  ###
  @layouts = []
  
  ###
  List of all tiles in the system.
  ###
  @tiles = new TileList()
  
  ###
  Current screen, needed to be able to track screen changes.
  ###
  @_currentScreen = workspace.activeScreen
  
  ###
  Current desktop, needed to be able to track screen changes.
  ###
  @_currentDesktop = workspace.currentDesktop - 1
  
  ###
  True if a user moving operation is in progress.
  ###
  @_moving = false
  
  ###
  The screen where the current window move operation started.
  ###
  @_movingStartScreen = 0
  
  # Read the script settings
  # TODO (this is currently not supported by kwin)
  # Create the various layouts, one for every desktop
  for i in [0...@desktopCount]
    @_createDefaultLayouts i
  @layouts[@_currentDesktop][@_currentScreen].activate()
  
  # Connect the tile list signals so that new tiles are added to the layouts
  @tiles.tileAdded.connect (tile) =>
    @_onTileAdded tile

  @tiles.tileRemoved.connect (tile) =>
    @_onTileRemoved tile

  
  # We need to reset custom client properties first because this might not be
  # the first execution of the script
  existingClients = workspace.clientList()
  existingClients.forEach (client) ->
    client.tiling_tileIndex = null
    client.tiling_floating = null

  
  # Create the initial list of tiles
  existingClients.forEach (client) =>
    @tiles.addClient client

  
  # Activate the visible layouts
  @layouts[workspace.currentDesktop - 1].forEach (layout) ->
    layout.activate()

  
  # Register global callbacks
  workspace.numberDesktopsChanged.connect =>
    @_onNumberDesktopsChanged()

  workspace.numberScreensChanged.connect =>
    @_onNumberScreensChanged()

  workspace.currentDesktopChanged.connect =>
    @_onCurrentDesktopChanged()

  
  # Register keyboard shortcuts
  registerShortcut "Next Tiling Layout", "Next Tiling Layout", "Meta+PgDown", =>
    currentLayout = @_getCurrentLayoutType()
    nextIndex = (currentLayout.index + 1) % @availableLayouts.length
    @_switchLayout workspace.currentDesktop - 1, workspace.activeScreen, nextIndex

  registerShortcut "Previous Tiling Layout", "Previous Tiling Layout", "Meta+PgUp", =>
    currentLayout = @_getCurrentLayoutType()
    nextIndex = currentLayout.index - 1
    nextIndex += @availableLayouts.length  if nextIndex < 0
    @_switchLayout workspace.currentDesktop - 1, workspace.activeScreen, nextIndex

  registerShortcut "Toggle Floating", "Toggle Floating", "Meta+F", =>
    return  unless workspace.activeClient
    tile = tiles.getTile(workspace.activeClient)
    return  unless tile?
    @toggleFloating tile

  registerShortcut "Switch Focus Left", "Switch Focus Left", "Meta+H", =>
    @_switchFocus Direction.Left

  registerShortcut "Switch Focus Right", "Switch Focus Right", "Meta+L", =>
    @_switchFocus Direction.Right

  registerShortcut "Switch Focus Up", "Switch Focus Up", "Meta+K", =>
    @_switchFocus Direction.Up

  registerShortcut "Switch Focus Down", "Switch Focus Down", "Meta+J", =>
    @_switchFocus Direction.Down

  registerShortcut "Move Window Left", "Move Window Left", "Meta+Shift+H", =>
    @_moveTile Direction.Left

  registerShortcut "Move Window Right", "Move Window Right", "Meta+Shift+L", =>
    @_moveTile Direction.Right

  registerShortcut "Move Window Up", "Move Window Up", "Meta+Shift+K", =>
    @_moveTile Direction.Up

  registerShortcut "Move Window Down", "Move Window Down", "Meta+Shift+J", =>
    @_moveTile Direction.Down

Qt.include "signal.js"
Qt.include "tile.js"
Qt.include "tilelist.js"
Qt.include "layout.js"
Qt.include "spirallayout.js"
Qt.include "tiling.js"
Qt.include "tests.js"

###
Utility function which returns the area on the selected screen/desktop which
is filled by the layout for that screen.

@param desktop Desktop for which the area shall be returned.
@param screen Screen for which the area shall be returned.
@return Rectangle which contains the area which shall be used by layouts.
###
TilingManager.getTilingArea = (desktop, screen) ->
  
  # TODO: Should this function be moved to Layout?
  workspace.clientArea KWin.MaximizeArea, screen, desktop

TilingManager::_createDefaultLayouts = (desktop) ->
  screenLayouts = []
  for i in [0...@screenCount]
    area = TilingManager.getTilingArea(desktop, j)
    screenLayouts[j] = new Tiling(area, @defaultLayout)
  @layouts[desktop] = screenLayouts

TilingManager::_getCurrentLayoutType = ->
  currentLayout = @layouts[@_currentDesktop][@_currentScreen]
  currentLayout.layoutType

TilingManager::_onTileAdded = (tile) ->
  
  # Add tile callbacks which are needed to move the tile between different
  # screens/desktops
  tile.screenChanged.connect (oldScreen, newScreen) =>
    @_onTileScreenChanged tile, oldScreen, newScreen

  tile.desktopChanged.connect (oldDesktop, newDesktop) =>
    @_onTileDesktopChanged tile, oldDesktop, newDesktop

  tile.movingStarted.connect =>
    @_onTileMovingStarted tile

  tile.movingEnded.connect =>
    @_onTileMovingEnded tile

  tile.movingStep.connect =>
    @_onTileMovingStep tile

  
  # Add the tile to the layouts
  client = tile.clients[0]
  tileLayouts = @_getLayouts(client.desktop, client.screen)
  tileLayouts.forEach (layout) ->
    layout.addTile tile


TilingManager::_onTileRemoved = (tile) ->
  client = tile.clients[0]
  tileLayouts = @_getLayouts(client.desktop, client.screen)
  tileLayouts.forEach (layout) ->
    layout.removeTile tile


TilingManager::_onNumberDesktopsChanged = ->
  newDesktopCount = workspace.desktopGridWidth * workspace.desktopGridHeight
  onAllDesktops = tiles.tiles.filter((tile) ->
    tile.desktop is -1
  )
  
  # Remove tiles from desktops which do not exist any more (we only have to
  # care about tiles shown on all desktops as all others have been moved away
  # from the desktops by kwin before)
  for i in [newDesktopCount...@desktopCount]
    onAllDesktops.forEach (tile) ->
      @layouts[i][tile.screen].removeTile tile
  
  # Add new desktops
  for i in [@desktopCount...newDesktopCount]
    @_createDefaultLayouts i
    onAllDesktops.forEach (tile) ->
      @layouts[i][tile.screen].addTile tile
  
  # Remove deleted desktops
  layouts.length = newDesktopCount  if @desktopCount > newDesktopCount
  @desktopCount = newDesktopCount

TilingManager::_onNumberScreensChanged = ->
  
  # Add new screens
  if @screenCount < workspace.numScreens
    for i in [0...@desktopCount]
      for j in [@screenCount...workspace.numScreens]
        area = TilingManager.getTilingArea(i, j)
        @layouts[i][j] = new Tiling(area, @defaultLayout)
        
        # Activate the new layout if necessary
        @layouts[i][j].activate()  if i is workspace.currentDesktop - 1
  
  # Remove deleted screens
  if @screenCount > workspace.numScreens
    for i in [0...@desktopCount]
      @layouts[i].length = workspace.numScreens
  @screenCount = workspace.numScreens

TilingManager::_onTileScreenChanged = (tile, oldScreen, newScreen) ->
  
  # If a tile is moved by the user, screen changes are handled in the move
  # callbacks below
  return  if @_moving
  client = tile.clients[0]
  oldLayouts = @_getLayouts(client.desktop, oldScreen)
  newLayouts = @_getLayouts(client.desktop, newScreen)
  @_changeTileLayouts tile, oldLayouts, newLayouts

TilingManager::_onTileDesktopChanged = (tile, oldDesktop, newDesktop) ->
  client = tile.clients[0]
  oldLayouts = @_getLayouts(oldDesktop, client.screen)
  newLayouts = @_getLayouts(newDesktop, client.screen)
  @_changeTileLayouts tile, oldLayouts, newLayouts

TilingManager::_onTileMovingStarted = (tile) ->
  
  # NOTE: This supports only one moving window, breaks with multitouch input
  @_moving = true
  @_movingStartScreen = tile.clients[0].screen

TilingManager::_onTileMovingEnded = (tile) ->
  client = tile.clients[0]
  @_moving = false
  movingEndScreen = client.screen
  windowRect = client.geometry
  unless @_movingStartScreen is movingEndScreen
    
    # Transfer the tile from one layout to another layout
    startLayout = @layouts[@_currentDesktop][@_movingStartScreen]
    endLayout = @layouts[@_currentDesktop][client.screen]
    startLayout.removeTile tile
    endLayout.addTile tile, windowRect.x + windowRect.width / 2, windowRect.y + windowRect.height / 2
  else
    
    # Transfer the tile to a different location in the same layout
    layout = @layouts[@_currentDesktop][client.screen]
    targetTile = layout.getTile(windowRect.x + windowRect.width / 2, windowRect.y + windowRect.height / 2)
    
    # swapTiles() works correctly even if tile == targetTile
    layout.swapTiles tile, targetTile
  workspace.hideOutline()

TilingManager::_onTileMovingStep = (tile) ->
  client = tile.clients[0]
  
  # Calculate the rectangle in which the window is placed if it is dropped
  layout = @layouts[@_currentDesktop][client.screen]
  windowRect = client.geometry
  target = layout.getTileGeometry(windowRect.x + windowRect.width / 2, windowRect.y + windowRect.height / 2)
  targetArea = null
  if target?
    targetArea = target.rectangle
  else
    targetArea = layout.layout.screenRectangle
  
  # Show an outline where the window would be placed
  # TODO: This is not working yet, the window movement code already disables
  # any active outline
  workspace.showOutline targetArea

TilingManager::_changeTileLayouts = (tile, oldLayouts, newLayouts) ->
  oldLayouts.forEach (layout) ->
    layout.removeTile tile  if newLayouts.indexOf(layout) is -1

  newLayouts.forEach (layout) ->
    layout.addTile tile  if oldLayouts.indexOf(layout) is -1


TilingManager::_onCurrentDesktopChanged = ->
  
  # TODO: This is wrong, we need to activate *all* visible layouts
  @layouts[@_currentDesktop][@_currentScreen].deactivate()
  @_currentDesktop = workspace.currentDesktop - 1
  @layouts[@_currentDesktop][@_currentScreen].activate()

TilingManager::_switchLayout = (desktop, screen, layoutIndex) ->
  
  # TODO: Show the layout switcher dialog
  layoutType = @availableLayouts[layoutIndex]
  @layouts[desktop][screen].setLayoutType layoutType

TilingManager::_toggleFloating = (tile) ->
  print "TODO: toggleFloating."


# TODO
TilingManager::_switchFocus = (direction) ->
  client = workspace.activeClient
  return  unless client?
  activeTile = @tiles.getTile(client)
  return  unless activeTile?
  layout = @layouts[client.desktop - 1][@_currentScreen]
  nextTile = layout.getAdjacentTile(activeTile, direction, false)
  workspace.activeClient = nextTile.getActiveClient()  if nextTile? and nextTile isnt activeTile

TilingManager::_moveTile = (direction) ->
  client = workspace.activeClient
  return  unless client?
  activeTile = @tiles.getTile(client)
  return  if not activeTile? or activeTile.floating or activeTile.forcedFloating
  layout = @layouts[client.desktop - 1][@_currentScreen]
  nextTile = layout.getAdjacentTile(activeTile, direction, true)
  layout.swapTiles activeTile, nextTile  if nextTile? and nextTile isnt activeTile

TilingManager::_getLayouts = (desktop, screen) ->
  if desktop > 0
    [@layouts[desktop - 1][screen]]
  else if desktop is 0
    []
  else if desktop is -1
    for i in [0...@desktopCount]
      @layouts[i][screen]
