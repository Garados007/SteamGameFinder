namespace SteamGameFinder.Web.Events
{
    public class ExecuteArgs
    {
        public WebSocketConnection Connection { get; }

        public Sessions.Session Session => Connection.Session;

        public ExecuteArgs(WebSocketConnection connection)
        {
            Connection = connection;
        }
    }
}