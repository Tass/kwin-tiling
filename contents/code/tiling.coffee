###
Class which implements tiling for a single screen.
@class
###
Tiling = (screenRectangle, layoutType) ->
  
###
  Tiles which have been added to the layout
###
  @tiles = []
  
###
  Layout type which provided the current layout.
###
  @layoutType = layoutType
  
###
  Layout which specifies window sizes/positions.
###
  @layout = new layoutType(screenRectangle)
  
###
  True if the layout is active.
###
  @active = false

# TODO
Tiling::setLayoutType = (layoutType) ->


# TODO
Tiling::setLayoutArea = (area) ->
  @layout.setLayoutArea area
  @_updateAllTiles()

Tiling::addTile = (tile, x, y) ->
  @layout.addTile()
  
  # If a position was specified, we insert the tile at the specified position
  if x? and y?
    index = @_getTileIndex(x, y)
    if index is -1
      @tiles.push tile
    else
      @tiles.splice index, 0, tile
  else
    @tiles.push tile
  
  # TODO: Set "below all" state
  @_updateAllTiles()  if @active


# TODO: Register tile callbacks
Tiling::removeTile = (tile) ->
  tileIndex = @tiles.indexOf(tile)
  @tiles.splice tileIndex, 1
  @layout.removeTile tileIndex
  
  # TODO: Unregister tile callbacks
  @_updateAllTiles() if @active

Tiling::swapTiles = (tile1, tile2) ->
  unless tile1 is tile2
    index1 = @tiles.indexOf(tile1)
    index2 = @tiles.indexOf(tile2)
    @tiles[index1] = tile2
    @tiles[index2] = tile1
  @_updateAllTiles()

Tiling::activate = ->
  @active = true
  
  # Resize the tiles like specified by the layout
  @_updateAllTiles()


# If no tile geometry was specified, just restore the saved geometry
# TODO
# Register callbacks for all tiles
# TODO
Tiling::deactivate = ->
  @active = false


# Unregister callbacks for all tiles
# TODO

###
Resets tile sizes to their initial size (in case they were resized by the
user).
###
Tiling::resetTileSizes = ->
  @layout.resetTileSizes()
  @_updateAllTiles()

Tiling::getTile = (x, y) ->
  index = @_getTileIndex(x, y)
  unless index is -1
    @tiles[index]
  else
    null

Tiling::getTileGeometry = (x, y) ->
  index = @_getTileIndex(x, y)
  unless index is -1
    @layout.tiles[index]
  else
    null

Tiling::_getTileIndex = (x, y) ->
  i = 0

  for i in [0...@layout.tiles.length]
    tile = @layout.tiles[i]
    if tile.rectangle.x <= x and tile.rectangle.y <= y and tile.rectangle.x + tile.rectangle.width > x and tile.rectangle.y + tile.rectangle.height > y
      return i
  -1

Tiling::getTiles = ->


# TODO
Tiling::getAdjacentTile = (from, direction, directOnly) ->
  if from.floating or from.forcedFloating
    
    # TODO
    print "TODO: getAdjacentTile() (floating tile)"
  else
    index = @tiles.indexOf(from)
    geometry = @layout.tiles[index]
    nextIndex = geometry.neighbours[direction]
    if not geometry.hasDirectNeighbour and not directOnly
      
      # This is not a direct neighbour (wrap-around situation), so cycle
      # through the floating windows first
      # TODO
      print "TODO: getAdjacentTile(): Not a direct neighbour!"
    else
      @tiles[nextIndex]

Tiling::_updateAllTiles = ->
  
  # Set the position/size of all tiles
  i = 0

  for i in [0...@layout.tiles.length]
    currentRect = @tiles[i].clients[0].geometry
    newRect = @layout.tiles[i].rectangle
    if currentRect.x isnt newRect.x or currentRect.y isnt newRect.y or currentRect.width isnt newRect.width or currentRect.height isnt newRect.height
      @tiles[i].setGeometry newRect  
