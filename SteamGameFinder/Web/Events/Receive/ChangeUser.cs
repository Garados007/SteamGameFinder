using System.Text.Json.Serialization;

namespace SteamGameFinder.Web.Events.Receive;

public class ChangeUser : ReceiveBase
{
    [JsonPropertyName("steamids")]
    [JsonRequired]
    public List<string> SteamIds { get; set; } = new();

    public override async Task Execute(ExecuteArgs args)
    {
        if (SteamIds.Contains(null!))
            return;
        lock (args.Session)
        {
            args.Session.SteamIds.Clear();
            args.Session.SteamIds.AddRange(SteamIds);
        }
        var update = Send.UpdatedUser.From(args.Session);
        await args.Session.ForeachAsync(x => x.Send(update));
    }
}
