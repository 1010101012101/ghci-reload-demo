-- | Development version to be run inside GHCi.

module DevelMain where

import Foundation
import Yesod

import Control.Concurrent
import Data.IORef
import Foreign.Store
import Network.Wai.Handler.Warp
-- import Yesod
-- import Yesod.Static

-- | Launches the new development server and makes a foreign store
-- to the IORef with the application in it, for later update.
main :: IO ()
main =
  do c <- newChan
     app <- toWaiApp (Piggies c)
     ref <- newIORef app
     _tid <- forkIO
              (runSettings
                (setPort 1990 defaultSettings)
                (\req -> do handler <- readIORef ref
                            handler req))
     _ <- newStore c
     _ <- newStore ref
     return ()

-- | Update the server, start it if not running.
update :: IO ()
update =
  do m <- lookupStore 1
     case m of
       Nothing -> main
       Just store ->
         do ref <- readStore store
            c <- readStore (Store 0)
            app <- toWaiApp (Piggies c)
            writeIORef ref app
            writeChan c ()
