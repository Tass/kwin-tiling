###
KWin - the KDE window manager
This file is part of the KDE project.

Copyright (C) 2012 Mathias Gottschlag <mgottschlag@gmail.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

###
Class which arranges the windows in a spiral with the largest window filling
the left half of the screen.
###
SpiralLayout = (screenRectangle) ->
  Layout.call this, screenRectangle

# TODO
SpiralLayout.name = "Spiral"

# TODO: Add an image for the layout switcher
SpiralLayout.image = null
SpiralLayout:: = new Layout()
SpiralLayout::constructor = SpiralLayout
SpiralLayout::onLayoutAreaChange = (oldArea, newArea) ->


# TODO: Scale all tiles
SpiralLayout::resetTileSizes = ->
  
  # Simply erase all tiles and recreate them to recompute the initial sizes
  tileCount = @tiles.length
  @tiles.length = 0
  i = 0

  while i < tileCount
    addTile()
    i++

SpiralLayout::addTile = ->
  print "SpiralLayout: addTile"
  if @tiles.length is 0
    
    # The first tile fills the whole screen
    rect = Qt.rect(@screenRectangle.x, @screenRectangle.y, @screenRectangle.width, @screenRectangle.height)
    @_createTile rect
  else
    
    # Divide the last tile into two halves
    lastRect = @tiles[@tiles.length - 1].rectangle
    newRect = Qt.rect(lastRect.x, lastRect.y, lastRect.width, lastRect.height)
    direction = @tiles.length % 4
    splitX = Math.floor(lastRect.width / 2)
    splitY = Math.floor(lastRect.height / 2)
    switch direction
      when 0
        lastRect.y = lastRect.y + splitY
        lastRect.height = lastRect.height - splitY
        newRect.height = splitY
      when 1
        lastRect.width = splitX
        newRect.x = newRect.x + splitX
        newRect.width = newRect.width - splitX
      when 2
        lastRect.height = splitY
        newRect.y = newRect.y + splitY
        newRect.height = newRect.height - splitY
      when 3
        lastRect.x = lastRect.x + splitX
        lastRect.width = lastRect.width - splitX
        newRect.width = splitX
    @_createTile newRect
  lastRect = @tiles[@tiles.length - 1].rectangle

SpiralLayout::removeTile = (tileIndex) ->
  
  # Increase the size of the last tile
  if @tiles.length > 1
    tileCount = @tiles.length - 1
    rects = [@tiles[tileCount - 1].rectangle, @tiles[tileCount].rectangle]
    left = Math.min(rects[0].x, rects[1].x)
    top = Math.min(rects[0].y, rects[1].y)
    right = Math.max(rects[0].x + rects[0].width, rects[1].x + rects[1].width)
    bottom = Math.max(rects[0].y + rects[0].height, rects[1].y + rects[1].height)
    lastRect = Qt.rect(left, top, right - left, bottom - top)
    @tiles[tileCount - 1].rectangle = lastRect
  
  # Remove the last array entry
  @tiles.length--
  
  # Fix the neighbour information
  if @tiles.length > 0
    @tiles[0].neighbours[Direction.Up] = @tiles.length - 1
    lastTile = @tiles[@tiles.length - 1]
    lastTile.neighbours[Direction.Down] = 0
    lastTile.hasDirectNeighbour[Direction.Down] = false

SpiralLayout::resizeTile = (tileIndex, rectangle) ->


# TODO
SpiralLayout::_createTile = (rect) ->
  
  # Update the last tile in the list
  unless @tiles.length is 0
    lastTile = @tiles[@tiles.length - 1]
    lastTile.neighbours[Direction.Down] = @tiles.length
    lastTile.hasDirectNeighbour[Direction.Down] = true
  
  # Create a new tile and add it to the list
  tile = {}
  tile.rectangle = rect
  tile.neighbours = []
  tile.hasDirectNeighbour = []
  tile.neighbours[Direction.Left] = @tiles.length
  tile.hasDirectNeighbour[Direction.Left] = false
  tile.neighbours[Direction.Right] = @tiles.length
  tile.hasDirectNeighbour[Direction.Right] = false
  tile.neighbours[Direction.Up] = @tiles.length - 1
  tile.hasDirectNeighbour[Direction.Up] = true
  tile.neighbours[Direction.Down] = 0
  tile.hasDirectNeighbour[Direction.Down] = false
  @tiles.push tile
  
  # Update the first tile
  @tiles[0].neighbours[Direction.Up] = @tiles.length - 1
  @tiles[0].hasDirectNeighbour[Direction.Up] = false
