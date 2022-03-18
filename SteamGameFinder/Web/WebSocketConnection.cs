using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MaxLib.WebServer.WebSocket;

namespace SteamGameFinder.Web;

public class WebSocketConnection : EventConnection
{

    public Sessions.Session Session { get; }

    public string Host { get; }

    public WebSocketConnection(Stream networkStream, EventFactory factory, Sessions.Session session,
        string host)
        : base(networkStream, factory)
    {
        Session = session;
        Session.Add(this);
        Host = host;
        Closed += (_, _) =>
        {
            Session.Remove(this);
            if (Session.ConnectionCount == 0)
                Session.Dispose();
        };
        _ = Send(new Events.Send.SendInfo(session));
    }

    protected override Task ReceiveClose(CloseReason? reason, string? info)
    {
        return Task.CompletedTask;
    }

    protected override Task ReceivedFrame(EventBase @event)
    {
        _ = Task.Run(async () => 
        {
            switch (@event)
            {
                case Events.ReceiveBase receive:
                    await receive.Execute(new Events.ExecuteArgs(
                        this
                    ));
                    break;
            }
        });
        return Task.CompletedTask;
    }

    public async Task Send<T>(T @event)
        where T : Events.SendBase
    {
        await SendFrame(@event).ConfigureAwait(false);
    }
}