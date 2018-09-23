module Main where

import Data.List

main :: IO ()
main = undefined

data Cell = Black | White | Empty
  deriving (Show, Eq)

-- data Cell = B | W 
--  deriving (Show, Eq)

-- type Cell = Maybe Disc

type Row = [Cell]

type Board = [Row]

type LocX = Int 
type LocY = Int

type Location = (LocX, LocY)

startingBoard :: Board
startingBoard = [[Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty],
                 [Empty, Empty, Empty, Empty, Empty, Empty, Empty, White],
                 [Empty, Empty, Empty, Empty, Empty, Black, Empty, Empty],
                 [Empty, Empty, Empty, White, Black, Empty, Empty, Empty],
                 [Empty, Empty, Empty, Black, White, Empty, Empty, Empty],
                 [Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty],
                 [Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty],
                 [Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty]]

-- Might create type Column = [Cell]??
-- Might need Maybe
columnToRow :: LocX -> Board -> Row
columnToRow locX []     = []
columnToRow locX board  = undefined --take 1 $ dropWhile (\(key, column) -> not (key == locX)) columnMap
                       where
                        columns = transpose board
                        columnMap = mapList columns

displayBoard :: Board -> IO ()
displayBoard = putStr . (++) "\n---------------------------------\n" . boardString 

-- Creates a string representation of a board.
boardString :: Board -> String
boardString []     = "ERR: INVALID BOARD"
boardString [x]    = rowString x
boardString (x:xs) = rowString x ++ boardString xs 

-- Creates a string representation of a row.
rowString :: Row -> String
rowString []     = "ERR: INVALID ROW"
rowString [x]    = cellString x ++ "|\n---------------------------------\n"
rowString (x:xs) = cellString x ++ rowString xs

-- Creates a string representation of a cell.
cellString :: Cell -> String
cellString Empty = "|   "
cellString Black = "| B "
cellString White = "| W "

-- For changing a cell on the board.
changeCell :: Cell -> Location -> Board -> Board
changeCell cell (locX, locY) board = [if key == locY then (changeCellRow cell locX row) else row | (key, row) <- (mapList board)]

-- For changing a cell in a row. 
changeCellRow :: Cell -> LocX -> Row -> Row
changeCellRow _ _ []           = []
changeCellRow newCell locX row = [if key == locX then newCell else cell | (key, cell) <- (mapList row)] 

-- Maps each item in the list to an Int.
mapList :: [a] -> [(Int, a)]
mapList = (zip [0..])

-- Check if board cell is empty
isEmptyCell :: (LocX, Cell) -> Bool
isEmptyCell (_, Empty) = True
isEmptyCell _          = False

isBlackDisc :: Cell -> Bool
isBlackDisc Black = True
isBlackDisc _     = False

isWhiteDisc :: Cell -> Bool
isWhiteDisc White = True
isWhiteDisc _     = False

{--
  Thee following functions are helper functions for checking a valid play on the board.
--}

{--
This is only work in one direction. Changing it up so that it creates a pair rows. One row consisting of cells 
before the play cell, and one consisting of cells coming after it. 
  shaveRow :: LocX -> Row -> Row
  shaveRow locX = drop $ locX + 1  
--}

playHorizontal :: Cell -> LocX -> Row -> Row
playHorizontal Empty _ row   = row
playHorizontal disc locX row = if checkLocX locX row then (if canPlay then newLeft ++ [disc] ++ newRight else row) else row
                              where  
                                left          =  reverse $ fst $ shaveRow locX row
                                right         =  snd $ shaveRow locX row
                                leftDivided   =  divideRow disc left
                                rightDivided  =  divideRow disc right
                                newLeft       = reverse $ flipCaptured leftDivided
                                newRight      = flipCaptured rightDivided
                                canPlay       = (checkRowPair leftDivided) || (checkRowPair rightDivided)

-- Helper function for playHorizontal that checks if LocX is an Empty cell
checkLocX :: LocX -> Row -> Bool
checkLocX locX row = (length emptyCellAndMatch) > 0
                  where 
                    cellMap = mapList row
                    emptyCellMap = filter isEmptyCell cellMap
                    emptyCellAndMatch = filter (\(fst, snd) -> fst == locX) emptyCellMap 



-- Not really shaving, but I don't have a better name. This splits the row into two rows. First step.
-- Reverse the row that is on the left of the play cell so that it can be checked properly.
shaveRow :: LocX -> Row -> (Row, Row)
shaveRow locX row = ((take locX row), (drop (locX + 1) row))  

-- Then, divide the shaved row into two rows according to color of disc that is being played.
divideRow :: Cell -> Row -> (Row, Row)
divideRow measure row = ((takeWhile (isOppositeCell measure) row), (dropWhile (isOppositeCell measure) row))

-- do something after checkRowPair to flip cells in row pair. Last step.
flipCaptured :: (Row, Row) -> Row 
flipCaptured ([], [])         = []
flipCaptured ([], tail)       = tail
flipCaptured (captured, [])   = captured
flipCaptured (captured@(c:cs), tail@(t:ts)) = if isOppositeCell c t then (flipRow captured) ++ tail else captured ++ tail 
--flipCaptured (captured, tail) = (flipRow captured) ++ tail 

-- Flip all cells in a row
flipRow :: Row -> Row
flipRow = (map flipCell)
 
-- FLips a disc to the opposite color
flipCell :: Cell -> Cell
flipCell Empty = Empty
flipCell Black = White
flipCell White = Black

-- Then based on the pair of rows, decide if play is valid or not.
-- Might not need?
checkRowPair :: (Row, Row) -> Bool
checkRowPair ([], [])         = False
checkRowPair ([], tail)       = False
checkRowPair (captured, [])   = False
checkRowPair ((c:cs), (t:ts)) = isOppositeCell c t

isOppositeCell :: Cell -> Cell -> Bool
isOppositeCell Black White = True
isOppositeCell White Black = True
isOppositeCell _ _         = False

isSameCell :: Cell -> Cell -> Bool 
isSameCell = (==) 

isSameCellMap :: Cell -> Row -> [Bool]
isSameCellMap measure = map (isSameCell measure) 

-- Will check to the right of the disk for a valid move
{--
checkRight :: Cell -> LocX -> Row -> Cell
checkRight disc locX row = rightOfLocX
  where rightOfLocX = drop locX row
--}


