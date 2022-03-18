module Views.UserInput exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Event exposing (Event)
import Data exposing (Data)
import Dict
import Json.Decode as JD
import Triple

onNotShiftEnter : msg -> Html.Attribute msg
onNotShiftEnter event =
    HE.custom "keydown"
        <| JD.andThen
            (\(code, shift) ->
                if code == 13 && not shift
                then JD.succeed
                    { message = event
                    , stopPropagation = True
                    , preventDefault = True
                    }
                else JD.fail "shift+enter"
            )
        <| JD.map2
            Tuple.pair
            HE.keyCode
        <| JD.field "shiftKey" JD.bool


type alias Model =
    { name: String
    }

type Msg
    = SetInput String
    | Add

init : Model
init =
    { name = ""
    }

view : Data -> Model -> Html Msg
view data model =
    div [ class "user-input" ]
        [ Html.h2 [ class "title", HA.id "user-input", HA.name "user-input" ]
            [ text "Add new user" ]
        , div [ class "description" ]
            [ text "Insert the SteamID from the user. This is something like: "
            , Html.em []
                [ text "76561197972495328" ]
            ]
        , div [ class "input" ]
            [ case Dict.get model.name data.invalidUser of
                Nothing -> text ""
                Just error ->
                    div [ class "error" ]
                        [ text error ]
            , Html.input
                [ HA.value model.name
                , HE.onInput SetInput
                , onNotShiftEnter Add
                ] []
            ]
        ]

update : Msg -> Data -> Model -> (Model, Cmd Msg, List Event)
update msg data model =
    case msg of
        SetInput user ->
            Triple.triple
                { model | name = user }
                Cmd.none
                []
        Add ->
            if Dict.member model.name data.invalidUser
            then Triple.triple model Cmd.none []
            else Triple.triple
                model
                Cmd.none
                [ Event.AddUser model.name ]

