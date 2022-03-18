using System.Text.Json;

namespace SteamGameFinder.Web.Events.Send;

public class UpdatePreference : SendBase
{
    public Receive.SetPreference Message { get; }

    public UpdatePreference(Receive.SetPreference message)
    {
        Message = message;
    }

    protected override void WriteJsonContent(Utf8JsonWriter writer)
    {
        writer.WriteString("user", Message.User);
        writer.WriteNumber("game", Message.Game);
        writer.WriteString("preference", Message.Preference.ToString());
    }
}