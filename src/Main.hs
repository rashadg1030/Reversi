module Main where

import Data.List
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import Data.Maybe
import Data.Functor
import Control.Monad
import System.Exit (exitSuccess)
import System.Random (randomRIO)
import Types  

main :: IO ()
main = do
  let startingState = (State Black startingBoard)
  runGame startingState 

runGame :: State -> IO ()
runGame state@(State disc board) = forever $ do
  gameEnd state
  putBoard board   
  if (possibleMoves disc board == []) then
    do
      putStr "#PASS#\n"
      (return (State (flipDisc disc) board)) >>= runGame
  else
    do
      print disc
      loc <- genLoc state
      putStr "Move: "
      print loc
      (return (State (flipDisc disc) (makeMove disc loc board))) >>= runGame

flipDisc :: Disc -> Disc
flipDisc Black = White
flipDisc White = Black

genLoc :: State -> IO (Int, Int)
genLoc state@(State disc board) = do
                                   x <- randomRIO (0,7)
                                   y <- randomRIO (0,7)
                                   if elem (x, y) possible then
                                    return (x,y)
                                   else genLoc state
                                where 
                                  possible = possibleMoves disc board

gameEnd :: State -> IO ()
gameEnd state@(State disc board) = 
  if noMoves state then
    do putBoard board
       if (isWinner Black board) then
        putStrLn "Black won! White lost!"
       else putStrLn "White won! Black lost!"
       putStrLn "Better luck next time!"
       exitSuccess
  else return () 

noMoves :: State -> Bool
noMoves state@(State disc board) = ((length $ possibleMoves disc board) == 0) && ((length $ possibleMoves (flipDisc disc) board) == 0)

isWinner :: Disc -> Board -> Bool
isWinner disc board = answer
                    where
                      step1 = Map.toList board 
                      step2 = map snd step1
                      step31 = filter (\d1 -> d1 == disc) step2
                      step32 = filter (\d2 -> d2 == (flipDisc disc)) step2
                      answer = (length step31) > (length step32) 

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
cellMapToString (((x, y), c):tail) = (if x == 7 then 
                                        (cellToString c) ++ line 
                                      else cellToString c) ++ cellMapToString tail
                                   where 
                                    line = "|\n---------------------------------\n"

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

placeDisc :: Location -> Disc -> Board -> Board 
placeDisc = Map.insert

-- Test boards for testing different game states
startingBoard :: Board 
startingBoard = makeBoard [((3,3), White), ((4,3), Black), ((3,4), Black), ((4,4), White)]

testBoard1 :: Board 
testBoard1 = makeBoard [((3,3), White), ((4,3), White), ((5,3), White), ((3,4), Black), ((4,4), White)]

testBoard2 :: Board 
testBoard2 = makeBoard [((3,3), White), ((4,3), White), ((3,4), Black), ((4,4), Black), ((5,4), Black), ((4,5), White), ((4,6), White)]

testBoard3 :: Board
testBoard3 = makeBoard [((2,4), White)
                      , ((1,4), White)
                      , ((0,4), Black)
                      , ((4,4), White)
                      , ((5,4), White)
                      , ((6,4), White)
                      , ((7,4), Black)
                      , ((3,3), White)
                      , ((3,2), White)
                      , ((3,1), White)
                      , ((3,0), Black)
                      , ((3,5), White)
                      , ((3,6), White)
                      , ((3,7), Black)
                      , ((4,3), White)
                      , ((5,2), White)
                      , ((6,1), White)
                      , ((7,0), Black)
                      , ((2,5), White)
                      , ((1,6), White)
                      , ((0,7), Black)
                      , ((2,3), White)
                      , ((1,2), White)
                      , ((0,1), Black)
                      , ((4,5), White)
                      , ((5,6), White)
                      , ((6,7), Black)] 

testBoard4 :: Board 
testBoard4 = makeBoard [((3,3), White), ((4,4), Black), ((5,5), Black), ((6,6), Black)]

testBoard5 :: Board 
testBoard5 = makeBoard [((0,7), White), ((1,6), Black), ((2,5), Black), ((3,4), Black), ((4,3), Black)]

makeBoard :: [(Location, Disc)] -> Board
makeBoard = Map.fromList

-- For generating a list of all board locations
genKeys :: [Location]
genKeys = [(x, y) | y <- [0..7], x <- [0..7]]

-- Functions for creating a list of all possible moves for a given color of Disc
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
findEndMinor loc@(x, y) = if or [x == 7, y == 0] then loc else findEndMinor (x+1, y-1)

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
findEndMajor loc@(x, y) = if or [x == 7, y == 7] then loc else findEndMajor (x+1, y+1)

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
findStartMinor loc@(x, y) = if or [x == 0, y == 7] then loc else findStartMinor (x-1, y+1) 

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
findStartMajor loc@(x, y) = if or [x == 0, y == 0] then loc else findStartMajor $ backMajor loc

backMajor :: Location -> Location
backMajor (x, y) = (x - 1, y - 1)

sameLoc :: Location -> Location -> Bool
sameLoc loc1 loc2 = loc1 == loc2
 
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

isValidLoc :: Location -> Board -> Bool
isValidLoc loc@(x, y) board = and [(isOpenLoc loc board), (isInside loc)]

isInside :: Location -> Bool
isInside (x, y) = x >= 0 && x < 8 && y >= 0 && y < 8

isOpenLoc :: Location -> Board -> Bool
isOpenLoc loc board = isEmptyCell $ getCell loc board

isEmptyCell :: Cell -> Bool
isEmptyCell Nothing = True
isEmptyCell _       = False

getCell :: Location -> Board -> Cell
getCell = Map.lookup 

-- Functions for making a move and changing the board state to a new one if the move is valid.
makeMove :: Disc -> Location -> Board -> Board 
makeMove disc loc board = if condition then ((placeDisc loc disc) . (makeMoveDiago disc loc) . (makeMoveOrtho disc loc)) board else board 
                  where
                    condition = elem loc (possibleMoves disc board) --Check if location is in list of possibleMoves

makeMoveDiago :: Disc -> Location -> Board -> Board
makeMoveDiago disc loc = (makeMoveMinor disc loc) . (makeMoveMajor disc loc) 

makeMoveMinor :: Disc -> Location -> Board -> Board
makeMoveMinor disc loc@(x, y) board = if isValidLoc loc board then answer else board
                                    where 
                                      preceding         = reverse $ precedingCellsMinor loc board
                                      following         = followingCellsMinor loc board
                                      precedingCaptured = getCaptured (Just disc) preceding
                                      followingCaptured = getCaptured (Just disc) following 
                                      precedingFlipped  = reverse $ flipCaptured precedingCaptured
                                      followingFlipped  = flipCaptured followingCaptured
                                      newCells1         = precedingFlipped ++ [Nothing] ++ followingFlipped 
                                      newCellMap2       = zip (getMinorKeys loc) newCells1
                                      newCellMap3       = filter (\x -> not ((snd x) == Nothing)) newCellMap2
                                      newMinorKeys      = map fst newCellMap3
                                      newCells2         = map snd newCellMap3
                                      newDiscs          = map fromJust newCells2
                                      newMinor          = makeBoard (zip newMinorKeys newDiscs)
                                      answer            = Map.union newMinor board 

makeMoveMajor :: Disc -> Location -> Board -> Board
makeMoveMajor disc loc@(x, y) board = if isValidLoc loc board then answer else board
                                    where
                                      preceding         = reverse $ precedingCellsMajor loc board
                                      following         = followingCellsMajor loc board
                                      precedingCaptured = getCaptured (Just disc) preceding
                                      followingCaptured = getCaptured (Just disc) following
                                      precedingFlipped  = reverse $ flipCaptured precedingCaptured
                                      followingFlipped  = flipCaptured followingCaptured
                                      newCells1         = precedingFlipped ++ [Nothing] ++ followingFlipped
                                      newCellMap2       = zip (getMajorKeys loc) newCells1 
                                      newCellMap3       = filter (\x -> not ((snd x) == Nothing)) newCellMap2
                                      newMajorKeys      = map fst newCellMap3
                                      newCells2         = map snd newCellMap3
                                      newDiscs          = map fromJust newCells2 
                                      newMajor          = makeBoard (zip newMajorKeys newDiscs)
                                      answer            = Map.union newMajor board 

makeMoveOrtho :: Disc -> Location -> Board -> Board
makeMoveOrtho disc loc = (makeMoveCol disc loc) . (makeMoveRow disc loc) 

makeMoveCol :: Disc -> Location -> Board -> Board 
makeMoveCol disc loc@(x, y) board = if isValidLoc loc board then answer else board
                                  where
                                    preceding = reverse $ precedingCellsCol loc board
                                    following = followingCellsCol loc board
                                    precedingCaptured = getCaptured (Just disc) preceding
                                    followingCaptured = getCaptured (Just disc) following
                                    precedingFlipped  = reverse $ flipCaptured precedingCaptured
                                    followingFlipped  = flipCaptured followingCaptured
                                    newCells1         = precedingFlipped ++ [Nothing] ++ followingFlipped
                                    newCellMap2       = zip (getColKeys loc) newCells1
                                    newCellMap3       = filter (\x -> not ((snd x) == Nothing)) newCellMap2
                                    newColKeys        = map fst newCellMap3
                                    newCells2         = map snd newCellMap3
                                    newDiscs          = map fromJust newCells2
                                    newCol            = makeBoard (zip newColKeys newDiscs)
                                    answer            = Map.union newCol board

makeMoveRow :: Disc -> Location -> Board -> Board
makeMoveRow disc loc@(x, y) board = if isValidLoc loc board then answer else board
                                  where 
                                    preceding         = reverse $ precedingCellsRow loc board 
                                    following         = followingCellsRow loc board
                                    precedingCaptured = getCaptured (Just disc) preceding
                                    followingCaptured = getCaptured (Just disc) following
                                    precedingFlipped  = reverse $ flipCaptured precedingCaptured
                                    followingFlipped  = flipCaptured followingCaptured
                                    newCells1         = precedingFlipped ++ [Nothing] ++ followingFlipped
                                    newCellMap2       = zip (getRowKeys loc) newCells1 
                                    newCellMap3       = filter (\x -> not ((snd x) == Nothing)) newCellMap2 -- remove Nothing elements
                                    newRowKeys        = map fst newCellMap3      -- Get the keys of the Just _ Cells 
                                    newCells2         = map snd newCellMap3      -- Get Just _ Cells
                                    newDiscs          = map fromJust newCells2   -- take every cell and make it a disc (unbox from Just "context") -- fromJust can throw an err :(
                                    newRow            = makeBoard (zip newRowKeys newDiscs) -- make newRow from newRowKeys and newDiscs zipped together
                                    answer            = Map.union newRow board  -- insert newRow into board using union
                                      --insert :: Ord k => k -> a -> Map k a -> Map k a
                                      --union :: Ord k => Map k a -> Map k a -> Map k a
getMinorKeys :: Location -> [Location] 
getMinorKeys loc@(x, y) = zip [ a | a <- [startX..endX]] $ reverse $ [ b | b <- [endY..startY]]
                        where
                          startX = fst $ findStartMinor loc
                          endX   = fst $ findEndMinor loc
                          startY = snd $ findStartMinor loc
                          endY   = snd $ findEndMinor loc

getMajorKeys :: Location -> [Location]
getMajorKeys loc@(x, y) = zip [ a | a <- [startX..endX]] [ b | b <- [startY..endY]]
                        where 
                          startX = fst $ findStartMajor loc
                          endX   = fst $ findEndMajor loc 
                          startY = snd $ findStartMajor loc
                          endY   = snd $ findEndMajor loc                                   

getColKeys :: Location -> [Location]
getColKeys (x, y) = [(x, b) | b <- [0..7]]                                      

getRowKeys :: Location -> [Location]
getRowKeys (x, y) = [(a, y) | a <- [0..7]]

flipCaptured :: ([Cell], [Cell]) -> [Cell]
flipCaptured ([], [])                       = []
flipCaptured ([], tail)                     = tail
flipCaptured (captured, [])                 = captured
flipCaptured (captured@(c:cs), tail@(t:ts)) = if isOppositeCell c t then (map flipCell captured) ++ tail else captured ++ tail

flipCell :: Cell -> Cell
flipCell Nothing      = Nothing
flipCell (Just Black) = Just White
flipCell (Just White) = Just Black

getCaptured :: Cell -> [Cell] -> ([Cell], [Cell])
getCaptured measure cells = ((takeWhile (isOppositeCell measure) cells), (dropWhile (isOppositeCell measure) cells)) 