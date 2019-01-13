{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE InstanceSigs #-}

module Main where
  
import qualified Data.Map.Strict as Map
import Control.Monad
import Control.Monad.IO.Class
import System.Exit (exitSuccess)
import System.Random (randomRIO)
import Data.Maybe
import Text.Read
import Actions
import Board
import Types 

newtype GameM a = GameM (IO a)
  deriving (Functor, Applicative, Monad, MonadIO)

{-
Abstract the print-like functions with a monadic type class named Logger. Give GameM an instance of logger with the liftIO definitions
The idea is to abstract over IO functions
-}

class Monad m => Logger m where
  writeMoveMessage :: Disc -> Location -> m ()
  writePassMessage :: Disc -> m ()
  writePrompt :: Disc -> m ()
  writeFinalMessage :: Final -> m ()
  writeFailMessage :: m ()
  writeBoard :: Board -> m ()

class Monad m => Control m where
  getInput :: m (Int, Int)

instance Logger (GameM) where
  writeMoveMessage :: Disc -> Location -> GameM ()
  writeMoveMessage disc loc = liftIO . putStrLn $ (show disc) ++ " disc placed at " ++ (show loc) ++ "."

  writePassMessage :: Disc -> GameM ()
  writePassMessage disc = liftIO . putStrLn . ((show disc) ++) $ " passes..."

  writePrompt :: Disc -> GameM ()
  writePrompt disc = liftIO . putStrLn . ((show disc) ++) $ "'s move. Enter a location in the format (x,y). Ctrl + C to quit."

  writeFinalMessage :: Final -> GameM ()
  writeFinalMessage (Win disc) = liftIO . putStrLn $ (show disc) ++ " won! " ++ (show . flipDisc $ disc) ++ " lost!"
  writeFinalMessage Tie        = liftIO . putStrLn $ "It's a tie!" 

  writeFailMessage :: GameM ()
  writeFailMessage = liftIO . putStrLn $ "Invalid move."

  writeBoard :: Board -> GameM ()
  writeBoard = liftIO . putBoard

instance Control (GameM) where
  getInput :: GameM (Int, Int)
  getInput = do
              input <- liftIO $ getLine
              case (readMaybe input) :: Maybe (Int, Int) of 
                (Just loc) -> return loc
                Nothing    -> return (9, 9) 

main :: IO ()
main = runGameM play

runGameM :: GameM a -> IO a
runGameM (GameM io) = io 

play :: GameM ()
play = stepGame startingState

stepGame :: State -> GameM ()
stepGame state@(State disc board) = do
  gameEnd state
  writeBoard board

  case possibleMoves disc board of
    []     -> do
                writePassMessage disc
                stepGame (State (flipDisc disc) board)
    moves  -> do
                writePrompt disc
                loc <- getInput

                if elem loc moves then 
                  do
                    writeMoveMessage disc loc
                    stepGame (State (flipDisc disc) (makeMove disc loc board))
                else 
                  do
                    writeFailMessage
                    stepGame state 

randomGame :: GameM ()
randomGame = do 
  genRandomGame (State Black startingBoard)

genRandomGame :: State -> GameM ()
genRandomGame state@(State disc board) = do
  gameEnd state
  writeBoard board   
  case possibleMoves disc board of
    []     -> do
                writePassMessage disc
                let newState = (State (flipDisc disc) board)
                genRandomGame newState 
    moves  -> do
                loc <- genLoc state
                writeMoveMessage disc loc 
                let newState = (State (flipDisc disc) (makeMove disc loc board))
                genRandomGame newState  

genLoc :: State -> GameM (Int, Int)
genLoc state@(State disc board) = do
  let possible = possibleMoves disc board
  x <- liftIO $ randomRIO (0,7) 
  y <- liftIO $ randomRIO (0,7) 
  if elem (x, y) possible then return (x,y) else genLoc state         
                
gameEnd :: State -> GameM ()
gameEnd state@(State disc board) = 
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
