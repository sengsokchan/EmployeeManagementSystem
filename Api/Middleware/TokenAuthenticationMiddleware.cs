using HrManagementSystem.Application;

namespace HrManagementSystem.Api.Middleware;

public sealed class TokenAuthenticationMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(
        HttpContext context,
        ITokenService tokenService,
        IHrRepository repository,
        IConfiguration configuration)
    {
        if (context.Request.Path.StartsWithSegments("/api") &&
            !context.Request.Path.StartsWithSegments("/api/auth/login") &&
            !context.Request.Path.StartsWithSegments("/api/auth/forgot-password"))
        {
            var authorization = context.Request.Headers.Authorization.ToString();

            if (authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) &&
                tokenService.TryValidate(authorization["Bearer ".Length..].Trim(), out var user) &&
                user is not null)
            {
                var idleMinutes = int.TryParse(configuration["Auth:IdleMinutes"], out var minutes) && minutes > 0
                    ? minutes
                    : 15;
                var session = repository.AuthorizeSession(user.UserId, user.SecurityStamp, idleMinutes);
                if (session == SessionCheckResult.Allowed)
                {
                    context.Items[HttpContextExtensions.CurrentUserItemKey] = user;
                }
            }
        }

        await next(context);
    }
}
