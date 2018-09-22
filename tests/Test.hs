module Test where

import Main

main :: IO ()
main = undefined

testChangeCellRow = (changeCellRow Black 3 [Empty, Empty, Empty, White, Black, Empty, Empty, Empty]) == [Empty, Empty, Empty, Black, Black, Empty, Empty, Empty]

testDisplayBoard = displayBoard startingBoard

testChangeCell =  displayBoard $ changeCell White (5,6) startingBoard

testIsSameCellMap = (isSameCellMap White [Black, White, White, Empty, Empty, Black, White]) == [False, True, True, False, False, False, True]

