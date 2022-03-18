using System.IO;
using MaxLib.WebServer;
using MaxLib.WebServer.WebSocket;
using SteamGameFinder.Web.Events.Receive;

namespace SteamGameFinder.Web;

public class WebSocketEndpoint : WebSocketEndpoint<WebSocketConnection>
{
    public override string? Protocol => null;

    private readonly EventFactory factory = new EventFactory();

    public WebSocketEndpoint()
    {
        // fill the factory with the known event types
        // factory.Add<InfoRequest>();
        var required = typeof(Events.ReceiveBase);
        var count = 0;
        foreach (var type in GetType().Assembly.GetTypes())
        {
            if (type.IsAbstract || !type.IsAssignableTo(required))
                continue;
            Serilog.Log.Verbose("register event {event}", type.Name);
            factory.Add(type.Name, type);
            count++;
        }
        Serilog.Log.Debug("{count} events registered", count);
    }

    protected override WebSocketConnection? CreateConnection(Stream stream, HttpRequestHeader header)
    {
        if (header.Location.DocumentPathTiles.Length != 2)
            return null;
        if (header.Location.DocumentPathTiles[0].ToLowerInvariant() != "ws")
            return null;
        var session = Sessions.Session.TryGet(header.Location.DocumentPathTiles[1]);
        if (session is null)
            return null;
        return new WebSocketConnection(
            stream,
            factory,
            session,
            header.Host
        );
    }
}