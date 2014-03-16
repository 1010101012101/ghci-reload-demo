-- | Development version to be run inside GHCi.

module DevelMain where

import Foundation
import Yesod

import Control.Concurrent
import Data.IORef
import Foreign.Store
import Network.Wai.Handler.Warp
import Yesod
import Yesod.Static

-- | Launches the new development server and returns a foreign store
-- to the IORef with the application in it, for later update.
main :: IO (Store (IORef Application))
main =
  do app <- toWaiApp Piggies
     ref <- newIORef app
     tid <- forkIO
              (runSettings
                defaultSettings { settingsPort = 1990 }
                (\req -> do handler <- readIORef ref
                            handler req))
     newStore ref

-- | Update the server, start it if not running.
update :: IO (Store (IORef Application))
update =
  do m <- lookupStore 0
     case m of
       Nothing -> main
       Just store ->
         do ref <- readStore store
            app <- toWaiApp Piggies
            writeIORef ref app
            return store
