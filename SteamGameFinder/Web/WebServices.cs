using System.IO;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Text.Json;
using System.Threading.Tasks;
using MaxLib.WebServer;
using MaxLib.WebServer.Builder;

namespace SteamGameFinder.Web;

public class WebServices : Service
{
    private static readonly Regex steamIdRegex = new Regex("^[0-9]+$", RegexOptions.Compiled);

    private static Stream Error(string code)
    {
        var m = new MemoryStream();
        var w = new Utf8JsonWriter(m);
        w.WriteStartObject();
        w.WriteString("error", code);
        w.WriteEndObject();
        w.Flush();
        m.Position = 0;
        return m;
    }

    [Path("/api/played-games/{steamid}")]
    [return: Mime(MimeType.ApplicationJson)]
    public async Task<Stream> GetPlayedGames([Var] string steamid)
    {
        if (!steamIdRegex.IsMatch(steamid))
            return Error("invalid id");
        
        if (!Directory.Exists("cache/played-games"))
            Directory.CreateDirectory("cache/played-games");
        var cachePath = Path.Combine("cache/played-games", steamid + ".json");
        if (File.Exists(cachePath) && File.GetLastWriteTimeUtc(cachePath).AddHours(1) > DateTime.UtcNow)
            return new FileStream(cachePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
        
        using var client = new HttpClient();
        var stream = await client.GetStreamAsync(
            "http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/" +
            "?key=" + Program.ApiKey +
            "&steamid=" + steamid +
            "&format=json" +
            "&include_appinfo=true" +
            "&include_played_free_games=true"
        ).ConfigureAwait(false);
        var cache = new FileStream(cachePath, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.ReadWrite);
        await stream.CopyToAsync(cache).ConfigureAwait(false);

        cache.SetLength(cache.Position);
        cache.Position = 0;
        return cache;
    }

    [Path("/api/user/{steamid}")]
    [return: Mime(MimeType.ApplicationJson)]
    public async Task<Stream> GetUser([Var] string steamid)
    {
        if (!steamIdRegex.IsMatch(steamid))
            return Error("invalid id");
        
        if (!Directory.Exists("cache/user"))
            Directory.CreateDirectory("cache/user");
        var cachePath = Path.Combine("cache/user", steamid + ".json");
        if (File.Exists(cachePath) && File.GetLastWriteTimeUtc(cachePath).AddHours(6) > DateTime.UtcNow)
            return new FileStream(cachePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
        
        using var client = new HttpClient();
        var stream = await client.GetStreamAsync(
            "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/" +
            "?key=" + Program.ApiKey +
            "&steamids=" + steamid +
            "&format=json"
        ).ConfigureAwait(false);
        var cache = new FileStream(cachePath, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.ReadWrite);
        await stream.CopyToAsync(cache).ConfigureAwait(false);

        cache.SetLength(cache.Position);
        cache.Position = 0;
        return cache; 
    }

    [Path("/api/new")]
    [return: Mime(MimeType.ApplicationJson)]
    public Stream NewSocket(MaxLib.WebServer.HttpLocation location)
    {
        var m = new MemoryStream();
        var w = new Utf8JsonWriter(m);
        w.WriteStartObject();
        w.WriteString("id", new Sessions.Session().Id);
        w.WriteEndObject();
        w.Flush();
        m.Position = 0;
        return m;
    }

    [Path("/")]
    public HttpDataSource Root()
    {
        return new HttpFileDataSource("ui/index.html")
        {
            MimeType = MimeType.TextHtml
        };
    }

    [Path("/api/session/{key}")]
    [return: Mime(MimeType.ApplicationJson)]
    public Stream GetSession([Var] string key)
    {
        var session = Sessions.Session.TryGet(key);
        if (session is null)
            return Error("not found");
        var m = new MemoryStream();
        var w = new Utf8JsonWriter(m);
        w.WriteStartObject();
        session.WriteJsonContent(w);
        w.WriteEndObject();
        w.Flush();
        m.Position = 0;
        return m;
    }
}