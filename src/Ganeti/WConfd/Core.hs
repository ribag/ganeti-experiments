{-# LANGUAGE TemplateHaskell #-}

{-| The Ganeti WConfd core functions.

As TemplateHaskell require that splices be defined in a separate
module, we combine all the TemplateHaskell functionality that HTools
needs in this module (except the one for unittests).

-}

{-

Copyright (C) 2013 Google Inc.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301, USA.

-}

module Ganeti.WConfd.Core where

import Control.Monad (liftM)
import qualified Data.Map as M
import qualified Data.Set as S
import Language.Haskell.TH (Name)

import Ganeti.BasicTypes (toErrorStr)
import qualified Ganeti.Locking.Allocation as L
import Ganeti.Locking.Locks (GanetiLocks)
import Ganeti.Types (JobId)
import Ganeti.WConfd.Language
import Ganeti.WConfd.Monad
import Ganeti.WConfd.ConfigWriter

-- * Functions available to the RPC module

-- Just a test function
echo :: String -> WConfdMonad String
echo = return

-- ** Configuration related functions

-- ** Locking related functions

-- | List the locks of a given owner (i.e., a job-id lockfile pair).
listLocks :: JobId -> FilePath -> WConfdMonad [(GanetiLocks, L.OwnerState)]
listLocks jid fpath =
  liftM (M.toList . L.listLocks (jid, fpath)) readLockAllocation

-- | Try to update the locks of a given owner (i.e., a job-id lockfile pair).
-- This function always returns immediately. If the lock update was possible,
-- the empty list is returned; otherwise, the lock status is left completly
-- unchanged, and the return value is the list of jobs which need to release
-- some locks before this request can succeed.
tryUpdateLocks :: JobId -> FilePath -> GanetiLockRequest -> WConfdMonad [JobId]
tryUpdateLocks jid fpath req =
  liftM (S.toList . S.map fst)
  . (>>= toErrorStr)
  $ modifyLockAllocation (L.updateLocks (jid, fpath)
                                        (fromGanetiLockRequest req))

-- * The list of all functions exported to RPC.

exportedFunctions :: [Name]
exportedFunctions = [ 'echo
                    , 'readConfig
                    , 'writeConfig
                    , 'listLocks
                    , 'tryUpdateLocks
                    ]