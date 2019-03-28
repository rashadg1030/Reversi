{-# LANGUAGE InstanceSigs #-}

module GameTree where

import Types
import Board
import qualified Data.Map as Map
import Actions
import Heuristic (evalBoard)

data RoseTree a = Node a [RoseTree a] 
    deriving (Show, Eq)

instance Functor RoseTree where
    fmap :: (a -> b) -> RoseTree a -> RoseTree b
    fmap f (Node x [])    = (Node (f x) [])
    fmap f (Node x roses) = (Node (f x) (map (fmap f) roses))

-- instance Applicative RoseTree where
--     pure :: a -> RoseTree a
--     pure x = Node x []
    -- Maybe No Applicative??
    -- (<*>) :: RoseTree (a -> b) -> RoseTree a -> RoseTree b
    -- (<*>) (Node f []) (Node x _)  = Node (f x) []
    -- (<*>) (Node f _) (Node x [])  = Node (f x) []
    -- (<*>) (Node f fs) (Node x xs) = Node (f x) (listApply ((<*>) fs) xs)
    -- fs :: [RoseTree (a -> b)]
    -- xs :: [RoseTree a]
    --     where 
    --         answer :: RoseTree b
    --         answer = (List.<*>) (fs <*>) xs    
            
-- How to return [a] if emptyList of functions is passed in
-- listApply :: [(a -> b)] -> [a] -> [b]
-- listApply [] _  = []
-- listApply _  [] = []
-- listApply fs xs = [ f x | f <- fs, x <- xs] 

gameStateToNode :: GameState -> RoseTree GameState
gameStateToNode gs = Node gs []

playAll :: GameState -> [GameState]
playAll gs = fmap (flip play $ gs) moveList -- Change this is confusing
    where 
        moveList = plausibleMoves gs

genGameTree :: Int -> RoseTree GameState -> RoseTree GameState
genGameTree depth rt@(Node gs _)
    | depth <= 0 = rt 
    | otherwise  = genGameTree (depth - 1) (Node gs (gameStateToNode <$> playAll gs))
                    --case seed of
                     --Node gs [] -> genGameTree (depth - 1) (Node gs (gameStateToNode <$> playAll gs)) 
                     --Node gs children -> Node gs (map (genGameTree (depth-1)) children)
                    -- children :: [RoseTree GameState]
                    -- gs :: GameState
                    -- d-1 one on either path works??

seed :: RoseTree GameState
seed = gameStateToNode startingState

-- findBestMove :: Disc -> RoseTree GameState -> Location
-- findBestMove d t = case t of
--                     Node a [] -> getLoc 


-- What about when a player passed?
-- prevMove :: GameState -> Location
-- prevMove gs
--     | 
--     | size difference == 1 = head toList difference
--     | 
--     where 
--         difference = Map.difference (getBoard gs) (getBoard $ rewind gs) == 1
