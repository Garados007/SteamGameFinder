module Event exposing (..)

import Data.Session exposing (Preference)
import Data.Steam exposing (SteamId, AppId)

type Event
    = AddUser SteamId
    | SetCurrentUser SteamId
    | SetPreference SteamId AppId Preference
    | SetBroke SteamId Bool
