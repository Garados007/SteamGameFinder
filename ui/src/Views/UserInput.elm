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
            [ text "Insert the SteamID or VanityURL from the user. This can be something like: "
            , Html.ul []
                <| List.map (Html.li [] << List.singleton << Html.em [] << List.singleton << text)
                [ "76561197972495328"
                , "https://steamcommunity.com/profiles/76561197972495328"
                , "garados007"
                , "https://steamcommunity.com/id/garados007"
                ]
            , text
                <| "All Steam data will be cached for one hour. If you bought new games in the "
                ++ "meantime, just wait a bit."
            ]
        , div [ class "input" ]
            [ case Dict.get model.name data.invalidUser of
                Nothing -> text ""
                Just error ->
                    div [ class "error" ]
                        [ text error ]
            , div [ class "input-box" ]
                [ Html.input
                    [ HA.value model.name
                    , HE.onInput SetInput
                    , onNotShiftEnter Add
                    ] []
                , Html.button [ HE.onClick Add ] [ text "Add" ]
                ]
            ]
        , div [ class "hint" ]
            [ text
                <| "If you are having trouble fetching or viewing a teammate's games, try setting "
                ++ "your game list to public in your Steam settings. More Information can be found "
                ++ "at the "
            , Html.a
                [ HA.href "https://help.steampowered.com/en/faqs/view/588C-C67D-0251-C276"
                , HA.target "_blank"
                ]
                [ text "Steam Support" ]
            , text " page."
            ]
        , div [ class "hint" ]
            [ text
                <| "Steam profiles with a large library may take a while to load and make the page "
                ++ "unresponsive. Please wait a moment in such cases."
            ]
        ]

fixId : String -> String
fixId original =
    if String.startsWith "https://steamcommunity.com/profiles/" original
    then String.dropLeft (String.length "https://steamcommunity.com/profiles/") original
    else if String.startsWith "https://steamcommunity.com/id/" original
    then String.dropLeft (String.length "https://steamcommunity.com/id/") original
    else original

update : Msg -> Data -> Model -> (Model, Cmd Msg, List Event)
update msg data model =
    case msg of
        SetInput user ->
            Triple.triple
                { model | name = user }
                Cmd.none
                []
        Add ->
            let
                id : String
                id = fixId model.name
            in
                if Dict.member id data.invalidUser
                then Triple.triple model Cmd.none []
                else Triple.triple
                    model
                    Cmd.none
                    [ Event.AddUser id ]

