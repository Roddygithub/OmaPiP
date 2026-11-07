# Security policy

OmaPiP runs as unsandboxed QML inside `omarchy-shell` and mirrors pixels from a
Wayland window selected by the user. Marketplace checks are compatibility and
static security-baseline checks; they are not a security audit, certification,
or endorsement.

## Report a vulnerability

Please use GitHub's private **Report a vulnerability** form:

https://github.com/Roddygithub/OmaPiP/security/advisories/new

Do not publish an exploit or include credentials, tokens, personal data, or
private window captures in a public issue. Include the affected version or
commit, environment, impact, and reproduction details only when safe.

## V1 security boundaries

- The only network request is a bounded, credential-free check of the public GitHub latest release endpoint, at most once per day. No window or capture data is sent.
- No authentication, secrets or capture persistence. Update-check timestamps and notification deduplication state are stored in the user state directory. Updates are never installed automatically.
- No administrator elevation, package manager, service installation, helper, daemon, or portal.
- No writes to `/usr/share/omarchy` or persistent Hyprland configuration.
- Hyprland commands use validated compositor addresses and bounded numeric geometry.
- Move and resize requests are native Wayland requests scoped to the OmaPiP viewer.
