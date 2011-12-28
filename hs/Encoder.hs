module Encoder (createCipher, enCipher) where

import Data.Char (toLower, toUpper)
import Data.List ((\\), sort, nub)
import Data.Map (Map)
import qualified Data.Map as Map
import System.Random
import Test.QuickCheck

alphabet :: [Char]
alphabet = ['a' .. 'z']

alphabetUL = ['A' .. 'Z'] ++ alphabet 

-- | Given a list of characters and a random number generator,
-- generates a map representing a cipher of those characters.
createCipher :: [Char] -> StdGen -> Map Char Char
createCipher chars gen = case aux (nub (map toLower chars)) Map.empty gen of
  -- The cipher is created on lower case letters. To map upper case
  -- in the same way we have to duplicate the map on upper case.
  (Just m, _)     -> Map.union m upperM where
    upperM = Map.map toUpper (Map.mapKeys toUpper m)
  (Nothing, gen2) -> createCipher chars gen2  -- try again

aux :: [Char] -> Map Char Char -> StdGen -> (Maybe (Map Char Char), StdGen)
aux [] m  g = (Just m, g)
aux (c:cs) m g = if null avail 
                   then (Nothing, g)
                   else aux cs (Map.insert c newChar m) g2 where
                     avail = filter (/= c) $ alphabet \\ Map.elems m
                     newChar = avail !! rand
                     (rand, g2) = randomR (0, length(avail) - 1) g

genCipher :: [Char] -> Gen (Map Char Char)
genCipher chars = do
  i <- arbitrarySizedIntegral
  return (createCipher chars (mkStdGen i))
   
genAlphaCipher :: Gen (Map Char Char)
genAlphaCipher = genCipher alphabet

propComplete :: Property
propComplete = forAll genAlphaCipher isComplete where
  isComplete m = c1 && c2 where
    c1 = sort (Map.keys m)  == alphabetUL
    c2 = sort (Map.elems m) == alphabetUL

propNoSame :: Property
propNoSame = forAll genAlphaCipher noSame where
  noSame m = Map.empty == fst (Map.partitionWithKey (\k a -> k == a) m)

-- | Encodes the given string according to the given cipher.
enCipher :: Map Char Char -> String -> String
enCipher m str = map toCipher str where
  toCipher c = case Map.lookup c m of
    Just c' -> c'
    Nothing -> c

test :: IO ()
test = do
  quickCheck propComplete
  quickCheck propNoSame