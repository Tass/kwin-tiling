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
