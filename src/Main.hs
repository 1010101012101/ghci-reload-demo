-- | Production entry point to web app.

module Main where

import Foundation
import Yesod

-- | Normal production main.
main = warpEnv Piggies
