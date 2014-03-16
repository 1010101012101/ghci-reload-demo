-- | Production entry point to web app.

module Main where

import Control.Concurrent
import Foundation
import Yesod

-- | Normal production main.
main :: IO ()
main = do c <- newChan
          warpEnv (Piggies c)
