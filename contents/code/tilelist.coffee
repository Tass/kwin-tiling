###
Class which keeps track of all tiles in the system. The class automatically
puts tab groups in one single tile. Tracking of new and removed clients is
done here as well.
@class
###
TileList = ->
  
  ###
  List of currently existing tiles.
  ###
  @tiles = []
  
  ###
  Signal which is triggered whenever a new tile is added to the list.
  ###
  @tileAdded = new Signal()
  
  ###
  Signal which is triggered whenever a tile is removed from the list.
  ###
  @tileRemoved = new Signal()
  
  # We connect to the global workspace callbacks which are triggered when
  # clients are added/removed in order to be able to keep track of the
  # new/deleted tiles
  workspace.clientAdded.connect (client) =>
    @_onClientAdded client

  workspace.clientRemoved.connect (client) =>
    @_onClientRemoved client


###
Adds another client to the tile list. When this is called, the tile list also
adds callback functions to the relevant client signals to trigger tile change
events when necessary. This function might trigger a tileAdded event.

@param client Client which is added to the tile list.
###
TileList::addClient = (client) ->
  return  if TileList._isIgnored(client)
  client.tabGroupChanged.connect =>
    @_onClientTabGroupChanged client

  
  # We also have to connect other client signals here instead of in Tile
  # because the tile of a client might change over time
  getTile = (client) =>
    @tiles[client.tiling_tileIndex]

  client.shadeChanged.connect ->
    getTile(client).onClientShadeChanged client

  client.geometryChanged.connect ->
    getTile(client).onClientGeometryChanged client

  client.keepAboveChanged.connect ->
    getTile(client).onClientKeepAboveChanged client

  client.keepBelowChanged.connect ->
    getTile(client).onClientKeepBelowChanged client

  client.fullScreenChanged.connect ->
    getTile(client).onClientFullScreenChanged client

  client.minimizedChanged.connect ->
    getTile(client).onClientMinimizedChanged client

  client.clientStartUserMovedResized.connect ->
    getTile(client).onClientStartUserMovedResized client

  client.clientStepUserMovedResized.connect ->
    getTile(client).onClientStepUserMovedResized client

  client.clientFinishUserMovedResized.connect ->
    getTile(client).onClientFinishUserMovedResized client

  client["clientMaximizedStateChanged(KWin::Client*,bool,bool)"].connect (client, h, v) ->
    getTile(client).onClientMaximizedStateChanged client, h, v

  client.desktopChanged.connect ->
    getTile(client).onClientDesktopChanged client

  
  # Check whether the client is part of an existing tile
  tileIndex = client.tiling_tileIndex
  if tileIndex >= 0 and tileIndex < tiles.length
    @tiles[tileIndex].clients.push client
  else
    
    # If not, create a new tile
    @_addTile client


###
Returns the tile in which a certain client is located.

@param client Client for which the tile shall be returned.
@return Tile in which the client is located.
###
TileList::getTile = (client) ->
  tileIndex = client.tiling_tileIndex
  if tileIndex >= 0 and tileIndex < @tiles.length
    @tiles[tileIndex]
  else
    null

TileList::_onClientAdded = (client) ->
  @_identifyNewTiles()
  @addClient client

TileList::_onClientRemoved = (client) ->
  tileIndex = client.tiling_tileIndex
  return  unless tileIndex >= 0 and tileIndex < @tiles.length
  
  # Remove the client from its tile
  tile = @tiles[tileIndex]
  if tile.clients.length is 1
    
    # Remove the tile if this was the last client in it
    @_removeTile tileIndex
  else
    
    # Remove the client from its tile
    tile.clients.splice tile.clients.indexOf(client), 1

TileList::_onClientTabGroupChanged = (client) ->
  tileIndex = client.tiling_tileIndex
  tile = @tiles[tileIndex]
  if tile.clients.length is 1
    
    # If this is the only client in the tile, the tile either does not
    # change or is destroyed
    @tiles.forEach (otherTile) ->
      otherTile.syncCustomProperties()  unless otherTile is tile

    unless client.tiling_tileIndex is tileIndex
      @_removeTile tileIndex
      @tiles[client.tiling_tileIndex].clients.push client
  else
    tile.clients.splice tile.clients.indexOf(client), 1
    client.tiling_tileIndex = @tiles.length
    
    # Check whether the client has been added to an existing tile
    @_identifyNewTiles()
    unless client.tiling_tileIndex is @tiles.length
      @tiles[client.tiling_tileIndex].clients.push client
    else
      @_addTile client

TileList::_addTile = (client) ->
  newTile = new Tile(client, @tiles.length)
  @tiles.push newTile
  @tileAdded.emit newTile

TileList::_removeTile = (tileIndex) ->
  
  # Remove the tile if this was the last client in it
  @tileRemoved.emit @tiles[tileIndex]
  @tiles[tileIndex] = @tiles[@tiles.length - 1]
  @tiles.length--
  @tiles[tileIndex].tileIndex = tileIndex
  @tiles[tileIndex].syncCustomProperties()


###
Updates the tile index on all clients in all existing tiles by synchronizing
the tiling_tileIndex property of the group. Clients which do not belong to
any existing tile will have this property set to null afterwards, while
clients which belong to a tile have the correct tile index.

This can only detect clients which are not in any tile, it does not detect
client tab group changes! These shall be handled by removing the client from
any tile in _onClientTabGroupChanged() first.
###
TileList::_identifyNewTiles = ->
  @tiles.forEach (tile) ->
    tile.syncCustomProperties()



###
Returns false for clients which shall not be handled by the tiling script at
all, e.g. the panel.
###
TileList._isIgnored = (client) ->
  
  # NOTE: Application workarounds should be put here
  client.specialWindow
