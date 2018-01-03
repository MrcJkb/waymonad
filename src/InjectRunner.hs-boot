{-
waymonad A wayland compositor in the spirit of xmonad
Copyright (C) 2018  Markus Ongyerth

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
module InjectRunner
    ( InjectChan
    , Inject (..)
    )
where

import Control.Concurrent.STM.TChan (TChan)
import Foreign.Ptr (Ptr)
import System.Posix.Types (Fd)

import Graphics.Wayland.WlRoots.Box (Point)
import Graphics.Wayland.WlRoots.Output (OutputMode)

import {-# SOURCE #-} Output (Output)

data Inject
    = ChangeMode Output (Ptr OutputMode)
    | ChangeScale Output Float
    | ChangePosition Output Point


data InjectChan = InjectChan
    { injectChan  :: TChan Inject
    , injectWrite :: Fd
    , injectRead  :: Fd
    }
