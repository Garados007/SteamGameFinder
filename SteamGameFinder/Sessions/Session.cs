using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Text.Json;

namespace SteamGameFinder.Sessions;

public class Session : IDisposable
{
    private readonly List<Web.WebSocketConnection> connections
        = new List<Web.WebSocketConnection>();

    public int ConnectionCount => connections.Count;

    public string Id { get; }

    public List<string> SteamIds { get; } = new List<string>();

    /// <summary>
    /// The Preferences of the user. The outer key is the steam id, the inner is the game id.
    /// </summary>
    public Dictionary<string, Dictionary<ulong, Preference>> Preferences { get; }
        = new Dictionary<string, Dictionary<ulong, Preference>>();

    /// <summary>
    /// The user that are broke and cannot by new games.
    /// </summary>
    public List<string> Broke { get; } = new List<string>();

    public Session()
    {
        var rng = new Random();
        Span<byte> buffer = stackalloc byte[16];
        do
        {
            rng.NextBytes(buffer);
            Id = Convert.ToHexString(buffer);
        }
        while (!sessions.TryAdd(Id, this));
    }

    private static readonly ConcurrentDictionary<string, Session> sessions
        = new ConcurrentDictionary<string, Session>();
    
    public static Session? TryGet(string id)
    {
        return sessions.TryGetValue(id, out Session? value) ? value : null;
    }
    
    public void Dispose()
    {
        sessions.Remove(Id, out _);
    }

    public void Add(Web.WebSocketConnection connection)
    {
        lock (this)
            connections.Add(connection);
    }

    public void Remove(Web.WebSocketConnection connection)
    {
        lock (this)
            connections.Remove(connection);
    }

    public void Foreach(Action<Web.WebSocketConnection> handler)
    {
        lock (this)
        {
            foreach (var connection in connections)
                handler(connection);
        }
    }

    public async Task ForeachAsync(Func<Web.WebSocketConnection, Task> handler)
    {
        Task[] tasks;
        lock (this)
        {
            tasks = new Task[connections.Count];
            for (int i = 0; i < connections.Count; ++i)
                tasks[i] = handler(connections[i]);
        }
        await Task.WhenAll(tasks);
    }

    public void WriteJsonContent(Utf8JsonWriter writer)
    {
        lock (this)
        {
            writer.WriteString("id", Id);
            writer.WriteStartArray("steamids");
            foreach (var id in SteamIds)
                writer.WriteStringValue(id);
            writer.WriteEndArray();
            writer.WriteStartArray("broke");
            foreach (var id in Broke)
                writer.WriteStringValue(id);
            writer.WriteEndArray();
            writer.WriteStartObject("preferences");
            foreach (var (user,v) in Preferences)
            {
                writer.WriteStartObject(user);
                foreach (var (game, pref) in v)
                    writer.WriteString(game.ToString(), pref.ToString());
                writer.WriteEndObject();
            }
            writer.WriteEndObject();
        }
    }
}