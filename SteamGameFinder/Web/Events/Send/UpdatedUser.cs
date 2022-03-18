using System.Text.Json;

namespace SteamGameFinder.Web.Events.Send;

public class UpdatedUser : SendBase
{
    public Sessions.Session Session { get; }

    public UpdatedUser(Sessions.Session session)
    {
        Session = session;
    }

    protected override void WriteJsonContent(Utf8JsonWriter writer)
    {
        lock (Session)
        {
            writer.WriteStartArray("steamids");
            foreach (var id in Session.SteamIds)
                writer.WriteStringValue(id);
            writer.WriteEndArray();
        }
    }
}