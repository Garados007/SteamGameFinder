using System.Text.Json;

namespace SteamGameFinder.Web.Events.Receive;

public class SetBroke : ReceiveBase
{
    public string User { get; private set; } = "";

    public bool Broke { get; private set; }

    public override async Task Execute(ExecuteArgs args)
    {
        lock (args.Session)
        {
            if (Broke)
            {
                if (!args.Session.Broke.Contains(User))
                    args.Session.Broke.Add(User);
            }
            else
            {
                args.Session.Broke.Remove(User);
            }
        }
        await args.Session.ForeachAsync(x => x.Send(new Send.UpdateBroke(this)));
    }

    public override void ReadJsonContent(JsonElement json)
    {
        User = json.GetProperty("user").GetString() ?? "";
        Broke = json.GetProperty("broke").GetBoolean();
    }
}