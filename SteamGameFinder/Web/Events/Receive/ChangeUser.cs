using System.Text.Json;

namespace SteamGameFinder.Web.Events.Receive;

public class ChangeUser : ReceiveBase
{
    public List<string> SteamIds { get; }
        = new List<string>();

    public override async Task Execute(ExecuteArgs args)
    {
        lock (args.Session)
        {
            args.Session.SteamIds.Clear();
            args.Session.SteamIds.AddRange(SteamIds);
        }
        await args.Session.ForeachAsync(x => x.Send(new Send.UpdatedUser(args.Session)));
    }

    public override void ReadJsonContent(JsonElement json)
    {
        foreach (var p in json.GetProperty("steamids").EnumerateArray())
            SteamIds.Add(p.GetString() ?? throw new NullReferenceException());
    }
}