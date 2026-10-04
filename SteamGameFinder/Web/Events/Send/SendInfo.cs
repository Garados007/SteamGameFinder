using System.Text.Json.Serialization;

namespace SteamGameFinder.Web.Events.Send;

public class SendInfo : SendBase
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("steamids")]
    public List<string> SteamIds { get; set; } = new();

    [JsonPropertyName("broke")]
    public List<string> Broke { get; set; } = new();

    [JsonPropertyName("preferences")]
    public Dictionary<string, Dictionary<ulong, Sessions.Preference>> Preferences { get; set; } = new();

    public static SendInfo From(Sessions.Session session)
    {
        lock (session)
        {
            return new SendInfo
            {
                Id = session.Id,
                SteamIds = new List<string>(session.SteamIds),
                Broke = new List<string>(session.Broke),
                Preferences = session.Preferences.ToDictionary(
                    x => x.Key,
                    x => new Dictionary<ulong, Sessions.Preference>(x.Value)
                ),
            };
        }
    }
}
