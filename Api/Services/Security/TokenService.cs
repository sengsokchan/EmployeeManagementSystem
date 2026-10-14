using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using HrManagementSystem.Application;
using HrManagementSystem.Domain;

namespace HrManagementSystem.Infrastructure.Security;

public sealed class TokenService(IConfiguration configuration) : ITokenService
{
    public const string RetiredSigningKey = "HrManagementSystem-Dev-Signing-Key-ChangeMe!";
    public const int MinimumSigningKeyLength = 32;

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private readonly byte[] _key = Encoding.UTF8.GetBytes(RequireSigningKey(configuration));
    private readonly string _issuer = configuration["Auth:Issuer"] ?? "HrManagementSystem";
    private readonly string _audience = configuration["Auth:Audience"] ?? "HrManagementSystem.Clients";
    private readonly TimeSpan _lifetime = TimeSpan.FromHours(
        double.TryParse(configuration["Auth:TokenHours"], out var hours) && hours > 0 ? hours : 1);

    public static string RequireSigningKey(IConfiguration configuration)
    {
        var key = configuration["Auth:SigningKey"];
        if (string.IsNullOrWhiteSpace(key) ||
            key.Length < MinimumSigningKeyLength ||
            string.Equals(key, RetiredSigningKey, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                "Auth:SigningKey is missing, shorter than 32 characters, or still the retired key that was committed to git. " +
                "Set a new secret with Auth__SigningKey (Cloud Run) or: dotnet user-secrets set \"Auth:SigningKey\" \"<new-secret>\".");
        }

        return key;
    }

    public string CreateToken(UserAccount user, string role, IReadOnlyCollection<string> permissions)
    {
        if (string.IsNullOrWhiteSpace(user.SecurityStamp))
        {
            throw new InvalidOperationException("Cannot sign in this account until its security stamp is set.");
        }

        var issuedAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var payload = new TokenPayload(
            user.Id,
            user.EmployeeId,
            user.Email,
            role,
            permissions.ToArray(),
            issuedAt + (long)_lifetime.TotalSeconds,
            _issuer,
            _audience,
            issuedAt,
            user.SecurityStamp);

        var body = Convert.ToBase64String(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(payload, JsonOptions)));
        var signature = Sign(body);
        return $"{body}.{signature}";
    }

    public bool TryValidate(string token, out UserContext? user)
    {
        user = null;
        var parts = token.Split('.', 2);
        if (parts.Length != 2)
        {
            return false;
        }

        var body = parts[0];
        if (!CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(Sign(body)),
                Encoding.UTF8.GetBytes(parts[1])))
        {
            return false;
        }

        try
        {
            var json = Encoding.UTF8.GetString(Convert.FromBase64String(body));
            var payload = JsonSerializer.Deserialize<TokenPayload>(json, JsonOptions);
            if (payload is null || string.IsNullOrWhiteSpace(payload.SecurityStamp))
            {
                return false;
            }

            var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            if (payload.ExpiresAt < now || payload.IssuedAt > now + 60)
            {
                return false;
            }

            if (!string.Equals(payload.Issuer, _issuer, StringComparison.Ordinal) ||
                !string.Equals(payload.Audience, _audience, StringComparison.Ordinal))
            {
                return false;
            }

            user = new UserContext(
                payload.UserId,
                payload.EmployeeId,
                payload.Email,
                payload.Role,
                payload.Permissions,
                payload.SecurityStamp);
            return true;
        }
        catch
        {
            return false;
        }
    }

    private string Sign(string body)
    {
        using var hmac = new HMACSHA256(_key);
        return Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(body)));
    }
}
