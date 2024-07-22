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

    private async Task<string?> ResolveCustomId(string id)
    {
        id = Uri.EscapeDataString(id)!;
        Serilog.Log.Debug("Look for vanity url: {url}", id);
        if (!Directory.Exists("cache/custom-id"))
            Directory.CreateDirectory("cache/custom-id");
        var cachePath = Path.Combine("cache/custom-id", id + ".json");
        if (File.Exists(cachePath) && File.GetLastAccessTimeUtc(cachePath).AddHours(24) > DateTime.UtcNow)
        {
            return await File.ReadAllTextAsync(cachePath);
        }

        using var client = new HttpClient();
        using var stream = await client.GetStreamAsync(
            "http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/" +
            "?key=" + Program.ApiKey +
            "&vanityurl=" + id
        ).ConfigureAwait(false);
        var doc = await JsonDocument.ParseAsync(stream);
        if (!doc.RootElement.TryGetProperty("response", out var response) ||
            !response.TryGetProperty("success", out var success) ||
            !success.TryGetInt32(out var successValue) ||
            successValue != 1 ||
            !response.TryGetProperty("steamid", out var steamid))
            return null;
        var steamIdValue = steamid.GetString();
        if (steamIdValue is null)
            return null;

        await File.WriteAllTextAsync(cachePath, steamIdValue);
        return steamIdValue;
    }

    [Path("/api/played-games/{steamid}")]
    [return: Mime(MimeType.ApplicationJson)]
    public async Task<Stream> GetPlayedGames([Var] string steamid)
    {
        if (!steamIdRegex.IsMatch(steamid))
        {
            var id = await ResolveCustomId(steamid);
            if (id is null || !steamIdRegex.IsMatch(id))
                return Error("invalid id");
            else steamid = id;
        }

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

    // [Path("/api/achievements/{steamid}/{appid}")]
    // [return: Mime(MimeType.ApplicationJson)]
    // public async Task<Stream?> GetAchievements([Var] string steamid, [Var] string appid, HttpResponseHeader response)
    // {
    //     if (!steamIdRegex.IsMatch(steamid))
    //     {
    //         var id = await ResolveCustomId(steamid);
    //         if (id is null || !steamIdRegex.IsMatch(id))
    //             return Error("invalid id");
    //         else steamid = id;
    //     }
    //     if (!steamIdRegex.IsMatch(appid))
    //     {
    //         return Error("invalid app id");
    //     }

    //     if (!Directory.Exists("cache/achievements"))
    //         Directory.CreateDirectory("cache/achievements");

    //     var playerCacheDir = Path.Combine("cache/achievements", steamid);
    //     if (!Directory.Exists(playerCacheDir))
    //         Directory.CreateDirectory(playerCacheDir);

    //     var cachePath = Path.Combine(playerCacheDir, appid + ".json");
    //     if (File.Exists(cachePath) && File.GetLastWriteTimeUtc(cachePath).AddHours(24) > DateTime.UtcNow)
    //         return new FileStream(cachePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);

    //     try
    //     {
    //         using var client = new HttpClient();
    //         var stream = await client.GetStreamAsync(
    //             "https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/" +
    //             "?key=" + Program.ApiKey +
    //             "&appid=" + appid +
    //             "&steamid=" + steamid +
    //             "&format=json"
    //         ).ConfigureAwait(false);
    //         var cache = new FileStream(cachePath, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.ReadWrite);
    //         await stream.CopyToAsync(cache).ConfigureAwait(false);

    //         cache.SetLength(cache.Position);
    //         cache.Position = 0;
    //         return cache;
    //     }
    //     catch(System.Net.Http.HttpRequestException e)
    //     {
    //         response.StatusCode = HttpStateCode.InternalServerError; // TODO: fetch correct response and status code and return it
    //         var cache = new FileStream(cachePath, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.ReadWrite);
    //         return cache;
    //     }
    //     catch(System.Exception e)
    //     {
    //         response.StatusCode = HttpStateCode.InternalServerError; // TODO: fetch correct response and status code and return it
    //         var cache = new FileStream(cachePath, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.ReadWrite);
    //         return cache;
    //     }
    // }

    // [Path("/api/friends/{steamid}")]
    // [return: Mime(MimeType.ApplicationJson)]
    // public async Task<Stream> GetFriends([Var] string steamid)
    // {
    //     if (!steamIdRegex.IsMatch(steamid))
    //     {
    //         var id = await ResolveCustomId(steamid);
    //         if (id is null || !steamIdRegex.IsMatch(id))
    //             return Error("invalid id");
    //         else steamid = id;
    //     }

    //     if (!Directory.Exists("cache/friends"))
    //         Directory.CreateDirectory("cache/friends");
    //     var cachePath = Path.Combine("cache/friends", steamid + ".json");
    //     if (File.Exists(cachePath) && File.GetLastWriteTimeUtc(cachePath).AddHours(6) > DateTime.UtcNow)
    //         return new FileStream(cachePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);

    //     using var client = new HttpClient();
    //     var stream = await client.GetStreamAsync(
    //         "https://api.steampowered.com/ISteamUser/GetFriendList/v0001/" +
    //         "?key=" + Program.ApiKey +
    //         "&steamid=" + steamid +
    //         "&relationship=friend" +
    //         "&format=json"
    //     ).ConfigureAwait(false);
    //     var cache = new FileStream(cachePath, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.ReadWrite);
    //     await stream.CopyToAsync(cache).ConfigureAwait(false);

    //     cache.SetLength(cache.Position);
    //     cache.Position = 0;
    //     return cache;
    // }

    [Path("/api/user/{steamid}")]
    [return: Mime(MimeType.ApplicationJson)]
    public async Task<Stream> GetUser([Var] string steamid)
    {
        if (!steamIdRegex.IsMatch(steamid))
        {
            var id = await ResolveCustomId(steamid);
            if (id is null || !steamIdRegex.IsMatch(id))
                return Error("invalid id");
            else steamid = id;
        }

        if (!Directory.Exists("cache/user"))
            Directory.CreateDirectory("cache/user");
        var cachePath = Path.Combine("cache/user", steamid + ".json");
        if (File.Exists(cachePath) && File.GetLastWriteTimeUtc(cachePath).AddMinutes(10) > DateTime.UtcNow)
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
