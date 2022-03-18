using System.Text.Json;

namespace SteamGameFinder.Web.Events.Send;

public class UpdateBroke : SendBase
{
    public Receive.SetBroke Message { get; }

    public UpdateBroke(Receive.SetBroke message)
    {
        Message = message;
    }

    protected override void WriteJsonContent(Utf8JsonWriter writer)
    {
        writer.WriteString("user", Message.User);
        writer.WriteBoolean("broke", Message.Broke);
    }
}