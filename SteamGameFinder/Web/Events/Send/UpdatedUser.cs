using System.Text.Json.Serialization;

namespace SteamGameFinder.Web.Events.Send;

public class UpdatedUser : SendBase
{
    [JsonPropertyName("steamids")]
    public List<string> SteamIds { get; set; } = new();

    public static UpdatedUser From(Sessions.Session session)
    {
        lock (session)
            return new UpdatedUser { SteamIds = new List<string>(session.SteamIds) };
    }
}
