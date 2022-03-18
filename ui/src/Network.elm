module Network exposing (..)

import Json.Decode as JD
import Json.Encode as JE
import WebSocket
import Ports exposing (..)
import Network.Messages exposing (SendMessage, ReceiveMessage)
import Url

wsReceive : (Result String ReceiveMessage -> msg) -> Sub msg
wsReceive tagger =
    receiveSocketMsg
        <| WebSocket.receive 
        <| \result ->
            case result of
                Err err -> tagger <| Err <| JD.errorToString err
                Ok (WebSocket.Error { error }) -> tagger <| Err error
                Ok (WebSocket.Data { data }) -> 
                    tagger
                    <| Result.mapError JD.errorToString
                    <| JD.decodeString
                        Network.Messages.decodeReceiveMessage
                        data

wsConnect : String -> String -> Cmd msg
wsConnect api id =
    WebSocket.send sendSocketCommand
        <| WebSocket.Connect
            { name = "ws"
            , address =
                if String.startsWith "http" api
                then "ws" ++ String.dropLeft 4 api 
                    ++ "/ws/" ++ Url.percentEncode id
                else "wss://" ++ api ++ "/ws/" ++ Url.percentEncode id
            , protocol = ""
            }

wsExit : Cmd msg
wsExit =
    WebSocket.send sendSocketCommand
        <| WebSocket.Close
            { name = "ws" }

wsClose : (Result JD.Error SocketClose -> msg) -> Sub msg
wsClose tagger =
    receiveSocketClose
        <| tagger
        << JD.decodeValue
            (JD.map2 SocketClose
                (JD.field "code" JD.int)
                (JD.field "reason" JD.string)
            )

wsSend : SendMessage -> Cmd msg
wsSend message =
    WebSocket.send sendSocketCommand
    <| WebSocket.Send
        { name = "ws"
        , content = JE.encode 0
            <| Network.Messages.encodeSendMessage message
        }

type alias SocketClose =
    { code: Int
    , reason: String
    }
