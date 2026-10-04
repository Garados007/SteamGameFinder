using System.Threading.Tasks;
using MaxLib.WebServer.WebSocket;

namespace SteamGameFinder.Web.Events
{
    public abstract class ReceiveBase : EventBase
    {
        public abstract Task Execute(ExecuteArgs args);
    }
}
