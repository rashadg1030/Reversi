module Main where

import Data.List
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import Data.Functor

main :: IO ()
main = undefined

-- Data

data Disc = Black | White
    deriving (Show, Eq)
  
type Cell = Maybe Disc

type Location = (Int, Int)

type Board = Map Location Disc

-- Functions

-- For displaying boards
putBoard :: Board -> IO ()
putBoard board = putStr step4
                   where 
                    step1 = boardToCells board
                    step2 = mapCells step1
                    step3 = cellMapToString step2
                    step4 = capBoard step3

capBoard :: String -> String 
capBoard x = "---------------------------------\n" ++ x

cellMapToString :: [(Location, Cell)] -> String
cellMapToString [] = ""
cellMapToString (((x, y), c):tail) = (if x == 7 then (cellToString c) ++ "|\n---------------------------------\n" else cellToString c) ++ cellMapToString tail

cellToString :: Cell -> String
cellToString (Nothing)    = "|   " 
cellToString (Just Black) = "| B "
cellToString (Just White) = "| W " 

mapCells :: [Cell] -> [(Location, Cell)]
mapCells = (zip genKeys)

boardToCells :: Board -> [Cell]
boardToCells board = map (lookup' board) genKeys

lookup' :: Ord k => Map k a -> k -> Maybe a
lookup' = flip Map.lookup

-- Test boards for testing different game states
startingBoard :: Board 
startingBoard = makeBoard [((3,3), White), ((4,3), Black), ((3,4), Black), ((4,4), White)]

testBoard1 :: Board 
testBoard1 = makeBoard [((3,3), White), ((4,3), White), ((5,3), White), ((3,4), Black), ((4,4), White)]

testBoard2 :: Board 
testBoard2 = makeBoard [((3,3), White), ((4,3), White), ((3,4), Black), ((4,4), Black), ((5,4), Black), ((4,5), White), ((4,6), White)]

makeBoard :: [(Location, Disc)] -> Board
makeBoard = Map.fromList

genKeys :: [Location]
genKeys = [(x, y) | y <- [0..7], x <- [0..7]]



-- Functions for creating a list of all possible moves for a given color of disc
possibleMoves :: Disc -> Board -> [Location]
possibleMoves disc board = answer 
                         where
                          sieve = (flip (checkMove disc)) board
                          answer = filter sieve genKeys

checkMove :: Disc -> Location -> Board -> Bool
checkMove disc loc board = or [(checkMoveOrtho disc loc board), (checkMoveDiago disc loc board)]

checkMoveDiago :: Disc -> Location -> Board -> Bool
checkMoveDiago disc loc board = or [(isValidMoveMajor disc loc board), (isValidMoveMinor disc loc board)]

isValidMoveMinor :: Disc -> Location -> Board -> Bool 
isValidMoveMinor disc loc@(x, y) board = if isValidLoc loc board then answer else False 
                                       where
                                        answer = condition1 || condition2
                                        preceding = reverse $ precedingCellsMinor loc board
                                        following = followingCellsMinor loc board
                                        precedingCaptured = getCaptured (Just disc) preceding
                                        followingCaptured = getCaptured (Just disc) following
                                        condition1 = validateCaptured precedingCaptured
                                        condition2 = validateCaptured followingCaptured

isValidMoveMajor :: Disc -> Location -> Board -> Bool 
isValidMoveMajor disc loc@(x, y) board = if isValidLoc loc board then answer else False
                                     where 
                                      answer = condition1 || condition2
                                      preceding = reverse $ precedingCellsMajor loc board
                                      following = followingCellsMajor loc board 
                                      precedingCaptured = getCaptured (Just disc) preceding
                                      followingCaptured = getCaptured (Just disc) following
                                      condition1 = validateCaptured precedingCaptured
                                      condition2 = validateCaptured followingCaptured

checkMoveOrtho :: Disc -> Location -> Board -> Bool 
checkMoveOrtho disc loc board = or [(isValidMoveRow disc loc board), (isValidMoveCol disc loc board)]

isValidMoveCol :: Disc -> Location -> Board -> Bool
isValidMoveCol disc loc@(x, y) board = if isValidLoc loc board then answer else False 
                                       where 
                                        answer = condition1 || condition2
                                        preceding = reverse $ precedingCellsCol loc board
                                        following = followingCellsCol loc board
                                        precedingCaptured = getCaptured (Just disc) preceding
                                        followingCaptured = getCaptured (Just disc) following
                                        condition1 = validateCaptured precedingCaptured
                                        condition2 = validateCaptured followingCaptured   

isValidMoveRow :: Disc -> Location -> Board -> Bool
isValidMoveRow disc loc@(x, y) board = if isValidLoc loc board then answer else False
                                     where 
                                      answer            = condition1 || condition2
                                      preceding         = reverse $ precedingCellsRow loc board
                                      following         = followingCellsRow loc board
                                      precedingCaptured = getCaptured (Just disc) preceding
                                      followingCaptured = getCaptured (Just disc) following
                                      condition1        = validateCaptured precedingCaptured 
                                      condition2        = validateCaptured followingCaptured

validateCaptured :: ([Cell], [Cell]) -> Bool                                       
validateCaptured ([], _)        = False
validateCaptured (captured, []) = False
validateCaptured ((c:cs), (t:ts)) = isOppositeCell c t

getCaptured :: Cell -> [Cell] -> ([Cell], [Cell])
getCaptured measure cells = ((takeWhile (isOppositeCell measure) cells), (dropWhile (isOppositeCell measure) cells)) 

isOppositeCell :: Cell -> Cell -> Bool
isOppositeCell Nothing _    = False
isOppositeCell _ Nothing    = False
isOppositeCell x y          = not (x == y)

followingCellsMinor :: Location -> Board -> [Cell]
followingCellsMinor location board = map (lookup' board) (followingKeysMinor location)

followingKeysMinor :: Location -> [Location]
followingKeysMinor loc@(x, y) = answer
                              where
                                endLoc = findEndMinor loc
                                endX = fst endLoc 
                                endY = snd endLoc 
                                listX = [(x+1)..endX]
                                listY = reverse $ [endY..(y-1)]
                                answer = zip listX listY      

findEndMinor :: Location -> Location
findEndMinor loc@(x, y) = if isEdge loc then loc else findEndMinor (x+1, y-1)

followingCellsMajor :: Location -> Board -> [Cell]
followingCellsMajor location board = map (lookup' board) (followingKeysMajor location)

followingKeysMajor :: Location -> [Location]
followingKeysMajor loc@(x, y) = answer 
                              where
                                endLoc = findEndMajor loc 
                                endX   = fst endLoc 
                                endY   = snd endLoc 
                                listX  = [(x+1)..endX]
                                listY  = [(y+1)..endY]
                                answer = zip listX listY

findEndMajor :: Location -> Location 
findEndMajor loc@(x, y) = if isEdge loc then loc else findEndMajor (x+1, y+1)

followingCellsCol :: Location -> Board -> [Cell]
followingCellsCol location board = map (lookup' board) (followingKeysCol location)
                                 where 
                                  followingKeysCol :: Location -> [Location]
                                  followingKeysCol (x, y) = zip (repeat x) [(y+1)..7]                                     

followingCellsRow :: Location -> Board -> [Cell]
followingCellsRow location board = map (lookup' board) (followingKeysRow location)
                                 where
                                  followingKeysRow :: Location -> [Location]
                                  followingKeysRow (x, y) = zip [(x+1)..7] (repeat y) 

-- Must be flipped like every other preceding function
precedingCellsMinor :: Location -> Board -> [Cell]
precedingCellsMinor location board = map (lookup' board) (precedingKeysMinor location)

precedingKeysMinor :: Location -> [Location]
precedingKeysMinor loc@(x, y) = answer
                              where 
                                startLoc = findStartMinor loc
                                startX = fst startLoc
                                startY = snd startLoc
                                listX = [startX..(x-1)]
                                listY = reverse $ [(y+1)..startY]
                                answer = zip listX listY

findStartMinor :: Location -> Location
findStartMinor loc@(x, y) = if isEdge loc then loc else findStartMinor (x-1, y+1) 

precedingCellsMajor :: Location -> Board -> [Cell]
precedingCellsMajor location board = map (lookup' board) (precedingKeysMajor location)
                                   --where
precedingKeysMajor :: Location -> [Location]
precedingKeysMajor loc@(x, y) = answer
                          where
                            startLoc  = findStartMajor loc 
                            startX = fst startLoc
                            startY = snd startLoc 
                            listX  = [startX..(x-1)]
                            listY  = [startY..(y-1)]
                            answer = zip listX listY 

findStartMajor :: Location -> Location
findStartMajor loc@(x, y) = if isEdge loc then loc else findStartMajor (x-1, y-1)

isEdge :: Location -> Bool
isEdge (x, y) = or [(x == 0 || y == 0), (x == 7 || y == 7)] 

precedingCellsCol :: Location -> Board -> [Cell] 
precedingCellsCol location board = map (lookup' board) (precedingKeysCol location)
                                 where
                                   precedingKeysCol :: Location -> [Location]
                                   precedingKeysCol (x, y) = zip (repeat x) [0..(y-1)] 
                            
precedingCellsRow :: Location -> Board -> [Cell]
precedingCellsRow location board = map (lookup' board) (precedingKeysRow location)
                                 where
                                   precedingKeysRow :: Location -> [Location]
                                   precedingKeysRow (x, y) = zip [0..(x-1)] (repeat y)
                                      
getRow :: Int -> Board -> Board
getRow locY board = Map.filterWithKey (\(x, y) _ -> y == locY) board

isValidLoc :: Location -> Board -> Bool
isValidLoc loc@(x, y) board = and [(isOpenLoc loc board), (isInside loc)]

isInside :: Location -> Bool
isInside (x, y) = x >= 0 && x < 8 && y >= 0 && y < 8

isOpenLoc :: Location -> Board -> Bool
isOpenLoc loc board = isEmptyCell $ getCell loc board

getCell :: Location -> Board -> Cell
getCell = Map.lookup 
                                            
isEmptyCell :: Cell -> Bool
isEmptyCell Nothing = True
isEmptyCell _       = False

getColumn :: Int -> Board -> Board 
getColumn locX board = Map.filterWithKey (\(x, y) _ -> x == locX) board

{--
-- Make play vertically and horizontally
playXY :: Cell -> Location -> Board -> Board
playXY Empty _ board = board
playXY _ _ [] = []
playXY disc loc@(x, y) board = if isEmpty then ((changeCell disc loc) . (playCol disc loc) . (changeCell Empty loc) . (playRow disc loc)) board else board 
                            where
                              isEmpty = checkLocX x $ head $ snd <$> (dropWhile (\(key, _) -> (key < y)) $ mapList board)

-- playRow works fine 
playRow :: Cell -> Location -> Board -> Board
playRow Empty _ board = board 
playRow disc (x, y) board = before ++ newRow ++ after
                where
                  before = snd <$> (takeWhile (\(key, _) -> (key < y)) $ mapList board)
                  after  = snd <$> (dropWhile (\(key, _) -> (key <= y)) $ mapList board)
                  newRow = (playHorizontal disc x) <$> (snd <$> (filter (\(key, _) -> (key == y)) $ mapList board))

playCol :: Cell -> Location -> Board -> Board  
playCol disc (x, y) = transpose . (playRow disc (y, x)) . transpose

-- Helper function for playHorizontal that checks if LocX is an Empty cell
checkLocX :: LocX -> Row -> Bool
checkLocX locX row = (length emptyCellAndMatch) > 0
                  where 
                    cellMap = mapList row
                    emptyCellMap = filter isEmptyCell cellMap
                    emptyCellAndMatch = filter (\(fst, snd) -> fst == locX) emptyCellMap 

-- Takes a locX and board and returns a column for processing
{--
getCol :: LocX -> Board -> Board 
getCol locX board = playHorizontal <$> snd <$> filter f columnMap
                     where 
                      columnMap = mapList $ transpose board
                      f = (\(key, _) -> (key == locX))
--}

locFits :: Location -> Bool
locFits (locX, locY) = validLocX && validLocY 
                          where 
                            validLocX = (locX >= 0) || (locX <= 7)
                            validLocY = (locY >= 0) || (locY <= 7)

-- Might create type Column = [Cell]??
-- Might need Maybe
columnsToRows :: Board -> Board
columnsToRows = transpose 

{--
columnToRow locX []     = []
columnToRow locX board  = undefined --take 1 $ dropWhile (\(key, column) -> not (key == locX)) columnMap
                      where
                        columns = transpose board
                        columnMap = mapList columns
--}
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

playHorizontal :: Cell -> LocX -> Row -> Row
playHorizontal Empty _ row   = row
playHorizontal disc locX row = if canPlay then newLeft ++ [disc] ++ newRight else row
                              where  
                                left          =  reverse $ fst $ shaveRow locX row
                                right         =  snd $ shaveRow locX row
                                leftDivided   =  divideRow disc left
                                rightDivided  =  divideRow disc right
                                newLeft       = reverse $ flipCaptured leftDivided
                                newRight      = flipCaptured rightDivided
                                canPlay       = (checkRowPair leftDivided) || (checkRowPair rightDivided)

{--
  Thee following functions are helper functions for checking a valid play on the board.
--}

{--
This is only work in one direction. Changing it up so that it creates a pair rows. One row consisting of cells 
before the play cell, and one consisting of cells coming after it. 
  shaveRow :: LocX -> Row -> Row
  shaveRow locX = drop $ locX + 1  
--}

{--
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
--}
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
--}

