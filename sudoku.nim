import random
from strutils import parseInt, toLowerAscii, toUpperAscii

from ansi import AnsiOp, csi

type
  CellValue = 0..9
  ColRange = 'A'..'I'
  RowRange = 1..9
  Row = array[RowRange, CellValue]
  Board = array[ColRange, Row]

proc `$`(val: CellValue): string =
  if val == 0:
    result = " "
  else:
    result = $val.int

proc toSet[T](a: openarray[T]): set[T] =
  result = {}
  for el in a:
    result.incl(el)

proc toSeq[T](s: set[T]): seq[T] =
  result = @[]
  for el in s:
    result.add(el)

proc random[T](s: set[T]): T =
  result = random(s.toSeq)

proc getInput(prompt: string): string =
  echo prompt
  stdout.write "> "
  result = stdin.readLine.toLowerAscii

proc valuesInCol(b: Board; col: ColRange): Row =
  for row in RowRange.low..RowRange.high:
    result[row] = b[col][row]

proc valuesInRow(b: Board; row: RowRange): Row =
  for col in ColRange.low..ColRange.high:
    result[col.ord - 64] = b[col][row]

proc valuesInField(b: Board; col: ColRange; row: RowRange): Row =
  var fieldLeft, fieldRight: ColRange
  var fieldTop, fieldBottom: RowRange
  # find the 3x3 block to which the cell belongs
  case col
    of 'A'..'C':
      fieldLeft = 'A'
      fieldRight = 'C'
    of 'D'..'F':
      fieldLeft = 'D'
      fieldRight = 'F'
    of 'G'..'I':
      fieldLeft = 'G'
      fieldRight = 'I'
  case row
    of 1..3:
      fieldTop = 1
      fieldBottom = 3
    of 4..6:
      fieldTop = 4
      fieldBottom = 6
    of 7..9:
      fieldTop = 7
      fieldBottom = 9
  var ctr = 0
  for fCol in fieldLeft..fieldRight:
    for fRow in fieldTop..fieldBottom:
      ctr += 1
      result[ctr] = b[fCol][fRow]

proc clear(b: var Board) =
  for col in ColRange.low..ColRange.high:
    for row in RowRange.low..RowRange.high:
      b[col][row] = 0.CellValue

proc fill(b: var Board): int =
  const
    cellValues: set[CellValue] = {1.CellValue .. 9}
  var
    attempts = 0
    success = false
  while not success:
    block while_loop:
      attempts += 1
      b.clear
      for col in ColRange.low..ColRange.high:
        for row in RowRange.low..RowRange.high:
          var
            val: CellValue
            blockedValues, possibleValues: set[CellValue]
          blockedValues = (valuesInRow(b, row).toSet +
                          valuesInCol(b, col).toSet +
                          valuesInField(b, col, row).toSet)
          blockedValues.excl(0.CellValue)
          possibleValues = cellValues - blockedValues
          if possibleValues.card > 0:
            val = random(possibleValues)
            b[col][row] = val
          else:
            break while_loop
      success = true
  return attempts

proc isFinished(b: Board): bool =
  for col in ColRange.low..ColRange.high:
    for row in RowRange.low..RowRange.high:
      if b[col][row] == 0.CellValue:
        return false
  result = true

proc show(b: Board; msg: string = "") =
  csi(opClear)
  csi(opCursorPos, 1, 1)
  echo  "\n      ** S U D O K U **\n"
  echo "     A B C   D E F   G H I"
  echo "   +-------+-------+-------+"
  for row in 1..9:
    var output = "  " & $row & "|"
    for col in 'A'..'I':
      output = output & " " & $b[col][row]
      if col == 'C' or col == 'F':
        output = output & " |"
    output = output & " |" & $row
    echo output
    if row == 3 or row == 6:
      echo "   |-------+-------+-------|"
  echo "   +-------+-------+-------+"
  echo "     A B C   D E F   G H I"
  echo "  " & msg

proc processMove(input: string; solution: Board; playable: var Board): string =
  result = ""
  var
    col: ColRange
    row: RowRange
    val: CellValue
  try:
    col = input[0].toUpperAscii.ColRange
    row = ($input[1]).parseInt.RowRange
    val = ($input[3]).parseInt.CellValue
  except:
    result = "unparseable input."
    return result
  if solution[col][row] == val:
    playable[col][row] = val
  else:
    result = "wrong move."
    return result

proc copyBoard(b: Board, percent: int): Board =
  for col in ColRange.low..ColRange.high:
    for row in RowRange.low..RowRange.high:
      if random(101) <= percent:
        result[col][row] = b[col][row]

proc playBoard(solution: Board) =
  var
    finished = false
    msg: string = ""
    playable: Board

  while true:  # get game difficulty
    let input = getInput("  Play board. Enter difficulty: 1-easy .. 3-hard")
    case input
      of "1":
        playable = copyBoard(solution, 75)
        break
      of "2":
        playable = copyBoard(solution, 55)
        break
      of "3":
        playable = copyBoard(solution, 33)
        break
      else:
        discard

  while not finished:
    show(playable, msg)
    let input = getInput("\n  move: (e.g.: a2 8), (q)uit")
    case input
      of "q":
        return
      else:
        if input.len == 4:
          msg = processMove(input, solution, playable)
          finished = playable.isFinished
        else:
          msg = "unknown command."
  show(playable)
  echo "  Congratulations!"


var
  b: Board

randomize()
csi(opClear)
csi(opCursorPos, 1, 1)
echo  "\n      ** S U D O K U **\n"
while true:
  let input = getInput("  (n)ew game, (q)uit")
  case input
    of "n":  # generate a new board and play it
      echo "  Generating board..."
      let attempts = b.fill
      echo "  It took ", attempts, " attempts to fill the board."
      playBoard(b)
    of "q":
      quit("  Goodbye.")
    else:
      discard
show b
