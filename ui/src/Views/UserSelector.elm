module Views.UserSelector exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Event exposing (Event)
import Data exposing (Data)
import Dict
import Json.Decode as JD
import Triple
import Task
import Data.Steam exposing (SteamId)
import Browser.Dom

type Msg
    = None
    | SetUser SteamId
    | MoveToSelector

view : Data -> Html Msg
view data =
    case data.currentUser of
        Just _ -> text ""
        Nothing ->
            div [ class "user-selector" ]
                [ div [ class "title" ]
                    [ text "Who are you?" ]
                , div [ class "list" ]
                    <| List.map
                        (\user ->
                            div [ class "user"
                                , HE.onClick <| SetUser user.steamid
                                ]
                                [ Html.img
                                    [ HA.src user.avatarFull 
                                    , HA.attribute "referrerpolicy" "no-referrer"
                                    , HA.attribute "crossorigin" "anonymous"
                                    ] []
                                , div [ class "name" ]
                                    [ text user.personaName ]
                                ]
                        )
                    <| Dict.values data.user
                ]

viewBanner : Data -> Html Msg
viewBanner data =
    div [ class "user-banner" ]
    <| (\list -> list ++
            [ Html.a
                [ HA.title "Add more"
                , HE.onClick MoveToSelector
                ]
                [ div [] [ text "+" ]
                ]
            ]
        )
    <| List.map
        (\user ->
            div 
                [ HA.classList
                    [ ("user", True)
                    , ("selected", Just user.steamid == data.currentUser)
                    ]
                , HA.title user.personaName
                , HE.onClick <| SetUser user.steamid
                ]
                [ Html.img
                    [ HA.src user.avatarMedium
                    , HA.attribute "referrerpolicy" "no-referrer"
                    , HA.attribute "crossorigin" "anonymous"
                    ] []
                ]
        )
    <| Dict.values data.user

update : Msg -> ((), Cmd Msg, List Event)
update msg =
    case msg of
        None ->
            ((), Cmd.none, [])
        SetUser user ->
            ((), Cmd.none, [ Event.SetCurrentUser user ])
        MoveToSelector ->
            Triple.triple
                ()
                ( Task.attempt
                    (\res -> 
                        case res of
                            Ok x -> x
                            Err _ -> None
                    )
                    <| Task.map (always None)
                    <| Task.andThen
                        (\v ->
                            Browser.Dom.setViewport 0
                            <| v.element.y - 100
                        )
                    <| Browser.Dom.getElement "user-input"
                )
                []
