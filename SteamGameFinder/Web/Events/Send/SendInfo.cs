using System.Text.Json;

namespace SteamGameFinder.Web.Events.Send;

public class SendInfo : SendBase
{
    public Sessions.Session Session { get; }

    public SendInfo(Sessions.Session session)
    {
        Session = session;
    }

    protected override void WriteJsonContent(Utf8JsonWriter writer)
    {
        Session.WriteJsonContent(writer);
    }
}