using System.Text.Json.Serialization;

namespace SteamGameFinder.Web.Events.Send;

public class UpdateBroke : SendBase
{
    [JsonPropertyName("user")]
    public string User { get; set; } = "";

    [JsonPropertyName("broke")]
    public bool Broke { get; set; }

    public static UpdateBroke From(Receive.SetBroke message)
    {
        return new UpdateBroke { User = message.User, Broke = message.Broke };
    }
}
