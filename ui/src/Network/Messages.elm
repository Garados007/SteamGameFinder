module Network.Messages exposing (..)

import Data.Session exposing (Session, Preference)
import Data.Steam exposing (SteamId, AppId)
import Json.Decode as JD exposing (Decoder, Value)
import Json.Encode as JE

type SendMessage
    = ChangeUser (List SteamId)
    | SetPreference SteamId AppId Preference
    | SetBroke SteamId Bool

encodeSendMessage : SendMessage -> Value
encodeSendMessage message =
    let
        enc : String -> List (String, Value) -> Value
        enc type_ items =
            JE.object
                <| (::) ("$type", JE.string type_)
                <| items
    in case message of
        ChangeUser ids -> 
            enc "ChangeUser"
            [ ("steamids", JE.list JE.string ids) ]
        SetPreference user game pref ->
            enc "SetPreference"
            [ ("user", JE.string user)
            , ("game", JE.int game)
            , ("preference", Data.Session.encodePreference pref)
            ]
        SetBroke user broke ->
            enc "SetBroke"
            [ ("user", JE.string user)
            , ("broke", JE.bool broke)
            ]

type ReceiveMessage
    = SendInfo Session
    | UpdatedUser (List SteamId)
    | UpdatePreference SteamId AppId Preference
    | UpdateBroke SteamId Bool

decodeReceiveMessage : Decoder ReceiveMessage
decodeReceiveMessage =
    JD.andThen
        (\type_ ->
            case type_ of
                "SendInfo" -> 
                    JD.map SendInfo Data.Session.decodeSession
                "UpdatedUser" ->
                    JD.field "steamIds" (JD.list JD.string)
                    |> JD.map UpdatedUser
                "UpdatePreference" ->
                    JD.map3 UpdatePreference
                        (JD.field "user" JD.string)
                        (JD.field "game" JD.int)
                        (JD.field "preference" Data.Session.decodePreference)
                "UpdateBroke" ->
                    JD.map2 UpdateBroke
                        (JD.field "user" JD.string)
                        (JD.field "broke" JD.bool)
                _ -> JD.fail <| "Invalid type " ++ type_
        )
    <| JD.field "$type" JD.string
