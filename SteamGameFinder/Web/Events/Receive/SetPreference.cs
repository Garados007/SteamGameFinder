using System.Text.Json;

namespace SteamGameFinder.Web.Events.Receive;

public class SetPreference : ReceiveBase
{
    public string User { get; private set; } = "";

    public ulong Game { get; private set; }

    public Sessions.Preference Preference { get; private set; }

    public override async Task Execute(ExecuteArgs args)
    {
        lock (args.Session)
        {
            if (!args.Session.Preferences.TryGetValue(User, out Dictionary<ulong, Sessions.Preference>? v))
                args.Session.Preferences.Add(User, v = new Dictionary<ulong, Sessions.Preference>());
            v[Game] = Preference;
        }
        await args.Session.ForeachAsync(x => x.Send(new Send.UpdatePreference(this)));
    }

    public override void ReadJsonContent(JsonElement json)
    {
        User = json.GetProperty("user").GetString() ?? "";
        Game = json.GetProperty("game").GetUInt64();
        Preference = Enum.Parse<Sessions.Preference>(
            json.GetProperty("preference").GetString() ?? ""
        );
    }
}