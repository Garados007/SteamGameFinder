using System.Text.Json.Serialization;

namespace SteamGameFinder.Web.Events.Receive;

public class SetPreference : ReceiveBase
{
    [JsonPropertyName("user")]
    [JsonRequired]
    public string User { get; set; } = "";

    [JsonPropertyName("game")]
    [JsonRequired]
    public ulong Game { get; set; }

    [JsonPropertyName("preference")]
    [JsonRequired]
    public Sessions.Preference Preference { get; set; }

    public override async Task Execute(ExecuteArgs args)
    {
        lock (args.Session)
        {
            if (!args.Session.Preferences.TryGetValue(User, out Dictionary<ulong, Sessions.Preference>? v))
                args.Session.Preferences.Add(User, v = new Dictionary<ulong, Sessions.Preference>());
            v[Game] = Preference;
        }
        var update = Send.UpdatePreference.From(this);
        await args.Session.ForeachAsync(x => x.Send(update));
    }
}
