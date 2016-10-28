# taken with credit from here:
# https://github.com/arthurtw/nim-examples/tree/master/conway
type
  AnsiOp* = enum
    opCursorUp = 'A',
    opCursorDown = 'B',
    opCursorForward = 'C',
    opCursorBack = 'D',
    opCursorPos = 'H',
    opClear = 'J',
    opEraseToEOL = 'K'

proc csi*(op: AnsiOp, x, y: int16 = -1) =
  stdout.write("\x1b[")
  if x >= 0: stdout.write(x)
  if y >= 0: stdout.write(';', y)
  if op == opClear: stdout.write('2')
  stdout.write(chr(ord(op)))

