{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE InstanceSigs #-}

module Main where
  
import qualified Data.Map.Strict as Map
import Control.Monad.IO.Class
import System.Random (randomRIO)
import Text.Read
import Actions
import Board
import Types



newtype GameM a = GameM (IO a)
  deriving (Functor, Applicative, Monad, MonadIO)

class Monad m => Logger m where
  writeMoveMessage :: Disc -> Location -> m ()
  writePassMessage :: Disc -> m ()
  writeFailMessage :: Disc -> m ()
  writePrompt :: Disc -> m ()
  writeFinalMessage :: Final -> m ()
  writePossibleMoves :: Disc -> Board -> m ()
  writeBoard :: Board -> m ()

class Monad m => Control m where
  getInput :: m Location

class Monad m => Generator m where 
  randomLoc :: m Location

instance Logger GameM where
  writeMoveMessage :: Disc -> Location -> GameM ()
  writeMoveMessage disc loc = liftIO . putStrLn $ (show disc) ++ " disc placed at " ++ (show loc) ++ "."

  writePassMessage :: Disc -> GameM ()
  writePassMessage disc = liftIO . putStrLn . ((show disc) ++) $ " passes..."

  writeFailMessage :: Disc -> GameM ()
  writeFailMessage d = liftIO . putStrLn $ (show d) ++ " made an invalid move."

  writePrompt :: Disc -> GameM ()
  writePrompt disc = liftIO . putStrLn . ((show disc) ++) $ "'s move. Enter a location in the format (x,y). Ctrl + C to quit."

  writeFinalMessage :: Final -> GameM ()
  writeFinalMessage (Win disc) = liftIO . putStrLn $ (show disc) ++ " won! " ++ (show . flipDisc $ disc) ++ " lost!"
  writeFinalMessage Tie        = liftIO . putStrLn $ "It's a tie!" 

  writePossibleMoves :: Disc -> Board -> GameM ()
  writePossibleMoves d = (liftIO . putStrLn . ("Possible Moves: "++) . show . possibleMoves d)

  writeBoard :: Board -> GameM ()
  writeBoard = liftIO . putBoard

instance Control GameM where
  getInput :: GameM Location
  getInput = do
    input <- liftIO $ getLine
    case (readMaybe input) :: Maybe Location of 
      (Just loc) -> return loc
      Nothing    -> return (9, 9)
                
instance Generator GameM where
  randomLoc :: GameM Location
  randomLoc = do
    x <- liftIO $ randomRIO (0,7)
    y <- liftIO $ randomRIO (0,7)
    return (x, y)

main :: IO ()
main = runGameM play

runGameM :: GameM a -> IO a
runGameM (GameM io) = io 

play :: (Logger m, Control m) => m ()
play = stepGame startingState

stepGame :: (Logger m, Control m) => State -> m ()
stepGame state@(State disc board) = do
  gameEnd state
  writeBoard board

  case possibleMoves disc board of
    [] -> do
      writePassMessage disc
      stepGame (State (flipDisc disc) board)
    moves -> do
      writePrompt disc
      writePossibleMoves disc board
      loc <- getInput
      if elem loc moves then 
        do
          writeMoveMessage disc loc
          stepGame (State (flipDisc disc) (makeMove disc loc board))
      else 
        do
          writeFailMessage disc
          stepGame state 

gameEnd :: Logger m => State -> m ()
gameEnd state@(State _ board) = 
  if noMoves state then
    do 
      writeBoard board
      let final = getFinal board
      writeFinalMessage final
  else return ()

-- Helper functions --
startingState :: State
startingState = (State Black startingBoard)

noMoves :: State -> Bool
noMoves (State disc board) = ((length $ possibleMoves disc board) == 0) && ((length $ possibleMoves (flipDisc disc) board) == 0)

getFinal :: Board -> Final
getFinal board = if step31 == step32 then Tie else Win greater
  where
    step1   = Map.toList board 
    step2   = map snd step1
    step31  = length $ filter (\d1 -> d1 == White) step2
    step32  = length $ filter (\d2 -> d2 == Black) step2
    greater = if step31 > step32 then White else Black

-- Generate Random Game --
randomGame :: (Logger m, Generator m) => m ()
randomGame = do 
  genRandomGame (State Black startingBoard)
    
genRandomGame :: (Logger m, Generator m) => State -> m ()
genRandomGame state@(State disc board) = do
  gameEnd state
  writeBoard board   
  case possibleMoves disc board of
    [] -> do
      writePassMessage disc
      let newState = (State (flipDisc disc) board)
      genRandomGame newState 
    _  -> do
      loc <- genLoc state
      writeMoveMessage disc loc 
      let newState = (State (flipDisc disc) (makeMove disc loc board))
      genRandomGame newState  
                   
genLoc :: Generator m => State -> m (Int, Int)
genLoc state@(State disc board) = do
  let possible = possibleMoves disc board
  loc <- randomLoc
  if elem loc possible then return loc else genLoc state         