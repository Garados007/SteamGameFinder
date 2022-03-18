using System;
using System.Text.Json;
using MaxLib.WebServer.WebSocket;

namespace SteamGameFinder.Web.Events
{
    public abstract class SendBase : EventBase
    {
        public sealed override void ReadJsonContent(JsonElement json)
        {
            throw new NotSupportedException();
        }
    }
}