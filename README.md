ghci-reload-demo
=====

A demo of using GHCi as a persistent development environment. This
example code uses a Yesod/Warp web server as a demo because it's
simple to setup but a very common real-world use-case.

The idea is that you have two main modules: `Main` and
`DevelMain`. The former for production, the latter for
development. `DevelMain` starts your server and manages updates to the
running code.

## GHCi's role

GHCi's job here is to run the warp process in a separate thread and
using the [foreign-store](https://github.com/chrisdone/foreign-store)
library, to retain a reference to the `IORef` containing the
`Application` (i.e. the web handler).

``` haskell
main =
  do c <- newChan
     app <- toWaiApp (Piggies c)
     ref <- newIORef app
     tid <- forkIO
              (runSettings
                defaultSettings { settingsPort = 1990 }
                (\req -> do handler <- readIORef ref
                            handler req))
     _ <- newStore c
     _ <- newStore ref
     return ()
```

## Warp's role

When the user updates the `IORef Application`, Warp will now server
the new code by virtue of the fact it reads from the IORef every time:

``` haskell
forkIO
  (runSettings
    defaultSettings { settingsPort = 1990 }
    (\req -> do handler <- readIORef ref
                handler req))
```

## IDE's role

Emacs, or your-editor-of-choice, can have some keybinding for "update
code". This will run the following in the GHCi process:

    :l DevelMain.hs

If that results in an "OK" and not a compile error, it can then
proceed to run

    DevelMain.update

Which will auto-start the server, or, if already running, update the
existing code running live. That update code is like this:

``` haskell
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
```

Emacs's haskell-mode
[already supports this](https://github.com/haskell/haskell-mode/blob/5a3a9966bc810da2b5988ac819b8f734b6ae9aa9/haskell-process.el#L1307),
so you just need to run `M-x haskell-process-reload-devel-main`, or,
for example, as a keybinding:

``` lisp
(define-key haskell-mode-map (kbd "f12") 'haskell-process-reload-devel-main)
```

## Browser's role

An optional role for the browser is to auto-refresh the page, which is
particularly handy if you are working on some visual aspect of the
site and can't be bothered to switch to your browser, hit refresh and
switch back. That is done by a trivial restart script:

``` javascript
$.get('/reload',function(){
    window.location.reload();
});
```

And the route is:

``` haskell
getReloadR =
  do reload <- fmap appReload getYesod
     dupChan reload >>= readChan
```

This simply clones the channel and then waits for a new event. As soon
as a new event comes in the web handler returns and the script will
refresh the page. Remember that earlier we read the channel from the
foreign store and then write unit onto it:

``` haskell
c <- readStore (Store 0)
app <- toWaiApp (Piggies c)
writeIORef ref app
writeChan c ()
```
