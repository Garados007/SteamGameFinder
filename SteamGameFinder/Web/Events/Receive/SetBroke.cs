using System.Text.Json.Serialization;

namespace SteamGameFinder.Web.Events.Receive;

public class SetBroke : ReceiveBase
{
    [JsonPropertyName("user")]
    [JsonRequired]
    public string User { get; set; } = "";

    [JsonPropertyName("broke")]
    [JsonRequired]
    public bool Broke { get; set; }

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
        var update = Send.UpdateBroke.From(this);
        await args.Session.ForeachAsync(x => x.Send(update));
    }
}
