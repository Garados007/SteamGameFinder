using System;
using System.Text.Json;
using System.Threading.Tasks;
using MaxLib.WebServer.WebSocket;

namespace SteamGameFinder.Web.Events
{
    public abstract class ReceiveBase : EventBase
    {
        protected sealed override void WriteJsonContent(Utf8JsonWriter writer)
        {
            throw new NotSupportedException();
        }

        public abstract Task Execute(ExecuteArgs args);
    }
}