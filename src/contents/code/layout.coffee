###
Base class for all tiling layouts.
@class
###
Layout = (screenRectangle) ->
  
###
  Screen area which is used by the layout.
###
  @screenRectangle = screenRectangle
  
###
  Geometry of the different tiles. This array stays empty in the case of
  floating layouts.
###
  @tiles = []
Direction =
  Up: 0
  Down: 1
  Left: 2
  Right: 3


# TODO
Layout::setLayoutArea = (area) ->
  oldArea = @screenRectangle
  @screenRectangle = area
  @onLayoutAreaChange oldArea, area
