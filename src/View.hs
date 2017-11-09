{-
waymonad A wayland compositor in the spirit of xmonad
Copyright (C) 2017  Markus Ongyerth

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

Reach us at https://github.com/ongy/waymonad
-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE StandaloneDeriving #-}
module View
    ( ShellSurface (..)
    , View (..)
    , getViewSize
    , getViewBox
    , createView
    , moveView
    , resizeView
    , getViewSurface
    , activateView
    , renderViewAdditional
    , getViewEventSurface
    , setViewBox
    , closeView
    , getViewClient
    , getViewInner
    )
where

import Data.IORef (IORef, readIORef, writeIORef, newIORef)
import Control.Monad.IO.Class
import Data.Typeable (Typeable, cast)
import Data.Word (Word32)
import Foreign.Ptr (Ptr)

import Graphics.Wayland.Resource (resourceGetClient)
import Graphics.Wayland.Server (Client)

import Graphics.Wayland.WlRoots.Surface (WlrSurface, getSurfaceResource)
import Graphics.Wayland.WlRoots.Box (WlrBox(..))

class Typeable a => ShellSurface a where
    getSurface :: MonadIO m => a -> m (Ptr WlrSurface)
    getSize :: MonadIO m => a -> m (Double, Double)
    resize :: MonadIO m => a -> Word32 -> Word32 -> m ()
    activate :: MonadIO m => a -> Bool -> m ()
    close :: MonadIO m => a -> m ()
    renderAdditional :: MonadIO m => (Ptr WlrSurface -> Int -> Int -> m ()) -> a -> Int -> Int -> m ()
    renderAdditional _ _ _ _ = pure ()
    getEventSurface :: MonadIO m => a -> Double -> Double -> m (Maybe (Ptr WlrSurface, Double, Double))
    setPosition :: MonadIO m => a -> Double -> Double -> m ()
    setPosition _ _ _ = pure ()
    getID :: a -> Int

data View = forall a. ShellSurface a => View
    { viewX :: IORef Double
    , viewY :: IORef Double
    , viewSurface :: a
    }

instance Ord View where
    compare (View _ _ left) (View _ _ right) = compare (getID left) (getID right)

instance Eq View where
    (View _ _ left) == (View _ _ right) =
        getID left == getID right

getViewSize :: MonadIO m => View -> m (Double, Double)
getViewSize (View _ _ surf) = getSize surf

getViewBox :: MonadIO m => View -> m WlrBox
getViewBox (View xref yref surf) = do
    (width, height) <- getSize surf
    x <- liftIO $ readIORef xref
    y <- liftIO $ readIORef yref
    pure WlrBox
        { boxX = floor x
        , boxY = floor y
        , boxWidth  = floor width
        , boxHeight = floor height
        }

setViewBox :: MonadIO m => View -> WlrBox -> m ()
setViewBox v box = do
    moveView v (fromIntegral $ boxX box) (fromIntegral $ boxY box)
    resizeView v (fromIntegral $ boxWidth box) (fromIntegral $ boxHeight box)

createView :: (ShellSurface a, MonadIO m) => a -> m View
createView surf = do
    xref <- liftIO $ newIORef 0
    yref <- liftIO $ newIORef 0
    pure View
        { viewX = xref
        , viewY = yref
        , viewSurface = surf
        }

closeView :: MonadIO m => View -> m ()
closeView (View _ _ surf) = close surf

moveView :: MonadIO m => View -> Double -> Double -> m ()
moveView (View xref yref surf) x y = do
    liftIO $ writeIORef xref x
    liftIO $ writeIORef yref y
    setPosition surf x y


resizeView :: MonadIO m => View -> Double -> Double -> m ()
resizeView (View _ _ surf) width height = resize surf (floor width) (floor height)


getViewSurface :: MonadIO m => View -> m (Ptr WlrSurface)
getViewSurface (View _ _ surf) = getSurface surf


activateView :: MonadIO m => View -> Bool -> m ()
activateView (View _ _ surf) active = activate surf active


renderViewAdditional :: MonadIO m => (Ptr WlrSurface -> Int -> Int -> m ()) -> View -> m ()
renderViewAdditional fun (View xref yref surf) = do
    x <- liftIO $ readIORef xref
    y <- liftIO $ readIORef yref
    renderAdditional fun surf (floor x) (floor y)


getViewEventSurface :: MonadIO m => View -> Double -> Double -> m (Maybe (Ptr WlrSurface, Double, Double))
getViewEventSurface (View xref yref surf) x y = do
    ownX <- liftIO $ readIORef xref
    ownY <- liftIO $ readIORef yref
    getEventSurface surf (x - ownX) (y - ownY)

getViewClient :: MonadIO m => View -> m (Maybe Client)
getViewClient (View _ _ surf) = do
    res <- liftIO . getSurfaceResource =<< getSurface surf
    Just <$> liftIO (resourceGetClient res)

getViewInner :: Typeable a => View -> Maybe a
getViewInner (View _ _ surf) = cast surf
