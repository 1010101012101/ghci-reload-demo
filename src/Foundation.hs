{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE QuasiQuotes #-}

-- | My web app.

module Foundation where

import Yesod
import Control.Concurrent.Chan.Lifted

data Piggies = Piggies { appReload :: !(Chan ()) }

instance Yesod Piggies

mkYesod "Piggies" [parseRoutes|
  / HomeR GET
  /reload ReloadR GET
|]

getHomeR :: Handler Html
getHomeR = defaultLayout [whamlet|
  Welcome to the Pigsty!
  <script src="http://code.jquery.com/jquery-1.11.0.min.js">
  <script>
    \$.get('/reload',function(){
        window.location.reload();
    });
|]

getReloadR :: Handler ()
getReloadR =
  do reload <- fmap appReload getYesod
     dupChan reload >>= readChan
