using System.Text.Json.Serialization;

namespace SteamGameFinder.Web.Events.Send;

public class UpdatePreference : SendBase
{
    [JsonPropertyName("user")]
    public string User { get; set; } = "";

    [JsonPropertyName("game")]
    public ulong Game { get; set; }

    [JsonPropertyName("preference")]
    public Sessions.Preference Preference { get; set; }

    public static UpdatePreference From(Receive.SetPreference message)
    {
        return new UpdatePreference
        {
            User = message.User,
            Game = message.Game,
            Preference = message.Preference,
        };
    }
}
