{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- Program to assign Christmas gifts in a set of person
-- where each person gives exactly one present to another person

module Lib where

import Control.Exception
import Data.List
import Debug.Trace
import System.Random
import Control.Monad.Random.Lazy
import qualified Data.Set as S

-- State encoding that a list of person must give a gift to another person
-- A person cannot give a gift to itself and two persons should not receive a gift
-- from the same person
data PapaState a = PapaState
  { notGiving :: S.Set a
  , presentLess :: [a]
  , previous :: S.Set (a, a)
  , assignment :: [(a, a)]
  }

instance Show a => Show (PapaState a) where
  show PapaState{assignment} =
    unlines [show giver ++ "->" ++ show receiver | (giver, receiver) <- assignment]

assign0 :: (Ord a, Show a, MonadRandom m) => PapaState a -> m (PapaState a)
assign0 state@PapaState{notGiving, presentLess=receiver:receivers, previous, assignment} = do
  giver <- uniform (S.filter neverGaveToReceiver notGiving)
  return $ state
    { notGiving = S.delete giver notGiving
    , presentLess = receivers
    , assignment = (giver, receiver) : assignment
    }
 where
  neverGaveToReceiver giver = S.notMember (giver, receiver) previous

assign :: (Ord a, Show a, MonadRandom m) => PapaState a -> m (PapaState a)
assign state
  | null (presentLess state) = return state
  | otherwise = assign0 state >>= assign

data Where = Commercy | George

getPreviousAssignments :: Where -> S.Set (String, String)
getPreviousAssignments location =
  let
    result = past location
    lengths :: [Int] = map length result -- the lengths of past assignments, should all be the same
    nbLengths = length lengths
  in
    assert (nbLengths <= 1) (S.fromList $ concat result)
  where
    past :: Where -> [[(String, String)]]
    past Commercy = [
      [("Clement", "Thomas"), -- 2019
       ("Henry", " Marianne"),
       ("Elise", "Pascale"),
       ("Laura", " Henry"),
       ("Marianne", "Romain"),
       ("Pascale", " Laura"),
       ("Romain", "Clement"),
       ("Thomas", " Elise")
      ]]
    past George = []

getPersons :: Where -> [String]
getPersons Commercy = ["Elise", "Clement", "Henry", "Pascale", "Marianne",
                       "Thomas", "Romain", "Laura"]
getPersons George = []

main0 :: MonadRandom m => Where -> m (PapaState String)
main0 location =
  assign $ PapaState
    { notGiving = S.fromList people
    , presentLess = people
    , previous = getPreviousAssignments location
    , assignment = []
    }
 where
  people = getPersons location

entrypoint :: IO ()
entrypoint =
  print =<< main0 Commercy
