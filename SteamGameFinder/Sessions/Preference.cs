namespace SteamGameFinder.Sessions;

/// <summary>
/// The preference of a user to a single game
/// </summary>
public enum Preference
{
    /// <summary>
    /// This is identical to a non set preference.
    /// </summary>
    Undefined,
    /// <summary>
    /// The user whould like to not play this game
    /// </summary>
    Dislike,
    /// <summary>
    /// The users opion is unclear or it doesn't matter for him to play or not
    /// </summary>
    Optional,
    /// <summary>
    /// The user whould play this game
    /// </summary>
    Like,
}