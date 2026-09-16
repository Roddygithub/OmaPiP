# OmaPiP — rapport d'initialisation et faisabilité

Date: 2026-09-16
Périmètre: étude uniquement. Aucun plugin V1 n'est implémenté.

## PI EXPERTISE GATE

Pi version: 0.85.1

Installation: binaire installé par mise (`~/.local/share/mise/installs/pi/0.85.1/pi/pi`)

Provider: openai-codex

Model: gpt-5.6-luna

Official current Pi documentation reviewed: PASS — documentation livrée avec Pi 0.85.1: usage, settings, sessions, compaction, security, skills, extensions, prompt-templates, packages, environment-variables, session-format.

Project instruction/context mechanism understood: PASS — `AGENTS.md` chargé depuis le projet; `.pi/` est le scope projet pour ressources/configuration après trust.

Sessions/resume understood: PASS — JSONL arborescent sous `~/.pi/agent/sessions/`; `pi -c`, `pi -r`, `/tree`, `/fork`, `/clone`.

Compaction understood: PASS — automatique ou `/compact`, résumé structuré et conservation d'une queue récente.

Skills system understood: PASS — découverte globale/projet/package, chargement à la demande; contenu potentiellement exécutable à traiter comme code de confiance.

Extensions system understood: PASS — TypeScript avec permissions du processus, discovery globale/projet, `/reload`.

Packages system understood: PASS — npm/git/local, installation globale ou `-l` projet; les extensions ont les permissions utilisateur.

Security implications understood: PASS — Pi n'est pas un sandbox; trust contrôle le chargement des ressources, pas les commandes exécutées.

Relevant Pi features actually selected:

- `AGENTS.md` comme unique instruction permanente.
- Sessions natives Pi et reprise `/resume`/`pi -c`.
- Compaction native, sans extension de mémoire.
- Git et probes jetables versionnés dans le projet.

Pi features deliberately NOT used:

- skill locale, extension, package, prompt template, sous-agent, mémoire maison, settings `.pi/settings.json`.

Reasons: aucune ne résout encore un problème concret de la phase de faisabilité; ajouter du code agentique augmenterait la surface de confiance et le contexte.

`PI_READY: YES`

## OMARCHY EXPERTISE GATE

Omarchy version: 4.0.3-1

Generation/branch: stable; `omarchy version branch` retourne une branche dev vide/non active.

Hyprland version: 0.56.2

Quickshell version: 0.3.1

Qt version: 6.11.2

QML version: Qt QML runtime 6.11.2

omarchy-shell architecture understood: PASS — un unique processus Quickshell (`quickshell -n -p /usr/share/omarchy/shell`) héberge shell, bar, services et plugins.

Third-party plugin boundary understood: PASS — manifest validé, plugin git dans `~/.config/omarchy/plugins/<id>`, code non sandboxé; façades de capacités côté tiers.

Official shell development instructions reviewed: PASS — équivalents locaux lus: `/usr/share/omarchy/shell/README.md`, `plugins/README.md`, `default/agents/skills/omarchy/plugins.md`, `PluginRegistry.qml` et `PluginRegistryApi.qml`.

Current plugin manifest contract verified: PASS — `schemaVersion: 1`, `id`, `name`, `version`, `kinds`, `entryPoints`; validation exécutée sur un fixture temporaire.

Current plugin validation workflow verified: PASS — `omarchy plugin validate <folder>`.

Relevant first-party plugins inspected: `omarchy.dev-gallery` (FloatingWindow), `omarchy.monitor`, `omarchy.menu`, `omarchy.image-picker`, `omarchy.osd`, `omarchy.notifications`, `omarchy.bar`.

Relevant community plugins inspected: `io.github.andressm415.omaprox`, `io.github.thisisgm.discord`, `quickshell.spotify`, `io.github.moizibnyousaf.omawhatsapp`, `omaconnect`.

Relevant upstream documentation consulted: Quickshell 0.3.1 type metadata installed locally (`ScreencopyView`, `Toplevel`, `ToplevelManager`, `FloatingWindow`); Hyprland behavior via local `hyprctl` and installed `xdg-desktop-portal-hyprland`.

`OMARCHY_READY: YES`

## PROJECT AGENT SETUP

Permanent project instructions: `AGENTS.md`.

Pi project skills: none.

Pi project extensions: none.

Other project-specific Pi resources: this report and disposable `probes/`.

Resources considered but rejected: `.pi/skills`, `.pi/extensions`, `.pi/settings.json`, Pi package, prompt template, memory database.

Reasons: YAGNI; instructions and native Pi sessions cover the current handoff.

Estimated agentic infrastructure complexity: `LOW`

Fresh Pi session can safely resume OmaPiP: `YES` — ouvrir `~/Projects/OmaPiP`, Pi charge `AGENTS.md`, puis lire ce rapport; `pi -c` reprend en outre la session.

## TECHNICAL PROBES

Les résultats marqués FAIL incluent les comportements non testés dans cette session; ils ne signifient pas nécessairement une impossibilité intrinsèque.

Window enumeration: PASS — `hyprctl clients -j` retourne 3 clients avec adresse stable, classe, titre, PID, workspace. Le probe Quickshell autonome avec `Hyprland.toplevels` reste vide malgré `refreshToplevels()`.

Active window identification: PASS — `hyprctl activewindow -j` disponible; `ToplevelManager.activeToplevel` est exposé par Quickshell mais nul dans le probe isolé.

Interactive window selection: FAIL — aucune sélection interactive sûre n'a été lancée; `slurp` est installé mais sélectionne une région, pas une fenêtre native.

Hyprland ↔ Toplevel mapping: FAIL — l'API locale `HyprlandToplevel` déclare bien `address` et `wayland`, mais le probe autonome n'a reçu aucun toplevel; la disponibilité dans le contexte `omarchy-shell` reste à vérifier.

Live arbitrary-window capture: PASS — probe `probes/capture.qml` avec `ScreencopyView.captureSource` a produit `hasContent=true`, source `1261x1030`.

Toplevel capture: PASS — le probe initial compile et accepte un `Toplevel` comme `captureSource`; résultat live observé. Le nouveau chemin `HyprlandToplevel.wayland` n'a pas pu sélectionner de source car la liste autonome est vide.

Capture while source is obscured: FAIL — non testé expérimentalement.

Source resize handling: FAIL — non testé.

Source workspace change handling: FAIL — non testé.

Source destruction handling: FAIL — non testé.

PiP window creation: PASS — `FloatingWindow` du probe a été créé et mappé; journal Quickshell confirme le chargement.

Floating: PASS — `FloatingWindow` est une surface xdg normale dans le probe; le comportement de placement final est compositor-owned.

Always-above-normal-windows: FAIL — non vérifié; ne pas confondre `FloatingWindow` et une garantie d'overrider.

Pinned/all-workspaces: FAIL — non vérifié par probe; nécessite règle Hyprland native ou protocole/dispatcher, avec tests réels.

Mouse drag move: FAIL — non testé; `FloatingWindow` n'expose pas x/y dans l'exemple local, et un déplacement Wayland doit passer par une opération de compositor.

4-edge resize: FAIL — non testé.

4-corner resize: FAIL — non testé.

Resize cursor feedback: FAIL — non testé.

Aspect-ratio handling: FAIL — non testé.

Initial bottom-right positioning: FAIL — non testé.

Initial bottom-left positioning: FAIL — non testé.

Multi-monitor: FAIL — session observée à un seul écran (`DP-2`); impossible de conclure.

Mixed-DPI/scaling if applicable: FAIL — un seul écran scale 1.

Dynamic source switching: FAIL — propriété mutable théorique, mais aucun changement de source live testé.

Prototype performance acceptable: FAIL — pas de mesure isolée CPU/mémoire/latence; shell existant observé à environ 387 MiB RSS, mesure non attribuable au probe.

## REAL omarchy-shell HOST PROBES

Contexte: probe temporaire installé dans `~/.config/omarchy/plugins/io.github.roddygithub.omapip-probe/`, validé par `omarchy plugin validate`, chargé par le processus réel `quickshell -n -p /usr/share/omarchy/shell`. Le fichier a ensuite été désactivé, supprimé, et `shell.json` restauré octet pour octet.

Host plugin loads successfully: PASS — fenêtre `OmaPiP host probe` créée dans le vrai host après redémarrage officiel du shell.

Hyprland.toplevels inside omarchy-shell: PASS — 5 toplevels observés.

activeToplevel inside omarchy-shell: PASS — adresse active observée et cohérente avec `hyprctl activewindow`.

HyprlandToplevel.wayland mapping: PASS — chaque entrée utile exposait `wayland: true`; `appId` et titre cohérents.

hyprctl ↔ HyprlandToplevel mapping: PASS — adresse sans préfixe `0x` du modèle QML correspond à l'adresse `hyprctl` avec préfixe; titre, workspace et classe/appId concordaient.

Live capture in host: PASS — `ScreencopyView.captureSource = HyprlandToplevel.wayland`, `hasContent=true`, tailles 1261x1030 / 626x1030 observées sur deux sources réelles.

Capture while obscured: PASS — capture restée `hasContent=true` avec une seconde fenêtre temporaire en fullscreen au-dessus de la source.

Source resize lifecycle: PASS — source temporaire redimensionnée de 621x1030 à 700x400; `sourceSize` reflétait 700x400.

Source workspace lifecycle: PASS — source déplacée silencieusement de workspace 3 à 4; capture restée active et `sourceSize` inchangée; source restaurée puis supprimée.

Source destruction lifecycle: PASS — fermeture de la source temporaire a retiré son toplevel; le viewer a perdu/repris le contenu sur une autre source. Observation importante: le probe a automatiquement choisi une autre source après destruction; V1 devra traiter explicitement cet état.

Dynamic source switching: PASS — `shell call ... select` a basculé le viewer foot → Brave puis vers une source temporaire sans recréer la fenêtre viewer; `hasContent` et `sourceSize` ont changé.

Floating: PASS — `FloatingWindow` créé puis rendu floating via dispatcher Hyprland temporaire; aucun état persistant ajouté.

Always-above: FAIL — aucune garantie `above` indépendante n'a été démontrée.

Pinned/all-workspaces: FAIL — dispatcher natif `hl.dsp.window.pin` a produit `pinned=true`, mais le comportement réellement visible sur plusieurs workspaces n'a pas été démontré.

Mouse drag move: FAIL — déplacement démontré uniquement via dispatcher `hl.dsp.window.move`, pas via clic gauche + drag.

4-edge resize: FAIL — non démontré par souris.

4-corner resize: FAIL — non démontré par souris.

Resize cursor feedback: FAIL — non démontré.

Aspect ratio: FAIL — ratio libre observé via dispatcher, mais aucun maintien de ratio utilisateur implémenté/testé.

Bottom-right positioning: FAIL — aucune logique de placement automatique du probe; la position dispatcher 2040,780 était seulement un test compositor.

Bottom-left positioning: FAIL — aucune logique de placement automatique du probe.

Performance acceptable: PASS — mesure indicative: host ~457 MiB RSS et ~5.6% CPU pendant capture; après cleanup/restart ~433–439 MiB RSS. Aucun crash, blocage ou symptôme visuel évident; mesure non scientifique et CPU non comparable pendant le démarrage du shell.

Multi-monitor: DEFERRED_ENVIRONMENT_LIMITATION — une seule sortie réelle (`DP-2`, scale 1); aucune sortie virtuelle/headless n'a été créée car cela nécessiterait une validation spécifique et risquerait de modifier l'environnement.

Mixed-DPI: DEFERRED_ENVIRONMENT_LIMITATION — aucun second écran/scale disponible.

Cleanup: PASS — probe désactivé, répertoire utilisateur supprimé, `shell.json` restauré avec hash identique `990c7780...`, plugins existants inchangés, `omarchy-shell shell ping` répond `ok`, aucun viewer temporaire restant.

## ARCHITECTURE DECISION

Recommended Omarchy plugin kind(s): `panel`; possiblement `service` si la sélection/source doit survivre indépendamment de la fenêtre. Le contexte host réel est requis.

Recommended architecture: plugin Omarchy tiers minimal, chargé on-demand dans `omarchy-shell`, avec `FloatingWindow` + `ScreencopyView` + `Hyprland.toplevels`; utiliser le dispatcher Hyprland Lua/IPC pour float, pin, move et resize lorsque Quickshell ne fournit pas l'opération.

External process/helper required: `NO` — aucune nécessité démontrée après les host probes; la capture et le mapping fonctionnent in-process.

If YES, exact demonstrated reason: N/A. Un helper ne doit être ajouté que si les probes manquants démontrent que le protocole de fenêtre/resize ou l'isolation ne peut pas être satisfait dans le shell.

Languages/technologies proposed: QML/Quickshell 0.3.1, Wayland `ScreencopyView`, `ToplevelManager`, Hyprland IPC/dispatch si nécessaire.

Main components: source selector, source identity/model, `ScreencopyView`, `FloatingWindow`, placement/resize controller, lifecycle/IPC.

Communication mechanism if applicable: IPC shell Omarchy pour summon/change/close; `hyprctl` IPC uniquement après preuve qu'une API native Quickshell ne suffit pas.

Why this architecture is preferred: dans le vrai `omarchy-shell`, le mapping adresse↔Toplevel↔Wayland et la capture live ont été observés sans dépendance ni modification d'Omarchy système; elle respecte le plugin natif et garde le code court.

Alternatives rejected: capture d'écran périodique (`grim`) — ce n'est pas un miroir live indépendant et serait plus lourd; helper Rust/C — aucune nécessité démontrée; layer-shell plein écran — risque connu de capture/input region et mauvais modèle pour une fenêtre déplaçable.

Impact on omarchy-shell stability: important — un plugin QML s'exécute dans le processus principal non sandboxé; éviter les boucles/bloquages et préférer une capture native. Un helper isolé ne se justifie qu'après démonstration d'un risque ou d'une limite réelle.

Future Interactive Mirror compatibility: conserver capture et surface comme composants séparés; l'injection de clic/clavier exige des protocoles Wayland dédiés (probablement portail/virtual-input), consentement et contrôle de sécurité. Ne pas transmettre d'input en V1.

Known limitations: above, drag souris, resize souris 8 zones, curseurs, ratio conservé et placement automatique restent non démontrés; multi-monitor/mixed-DPI sont différés par l'environnement. La destruction nécessite un état explicite plutôt qu'une sélection automatique implicite.

Risks: capture autorisée par configuration (`xdph.conf` contient `allow_token_by_default = true`), fuite/crash dans `omarchy-shell`, surfaces qui interceptent les clics, disparition de la source, coûts GPU/CPU pendant resize.

Blockers: démontrer drag gauche + resize natif/dispatcher sur 8 zones, feedback curseur, above, ratio et placement; ajouter ensuite les tests multi-monitor lorsque l'environnement le permet.

`READY_TO_IMPLEMENT: NO` — les gates move/resize/above/placement/ratio restent bloquants; multi-monitor et mixed-DPI sont différés, non considérés comme échec architectural.

## STOP CONDITION

Arrêt volontaire avant toute implémentation V1. Les probes QML sont jetables et ne sont pas du code de production. Les probes supplémentaires `hyprland.qml` et `capture-hyprland.qml` ont confirmé l'absence de toplevels dans une instance Quickshell autonome, sans modifier Omarchy.

## REPOSITORY

Local path: `/home/roddy/Projects/OmaPiP`

GitHub repository: `https://github.com/Roddygithub/OmaPiP`

Visibility: public

Current branch: `main`

HEAD: `cd04275` (`cd04275...`)

Git status: propre après publication

Remote: `origin https://github.com/Roddygithub/OmaPiP.git`

Commits created: initial feasibility study, GitHub governance PR #1, MIT license/probe PR #2, host probe PR #4

Push status: PASS — `main` à jour sur `origin` via PR #4

## FILES

Files created: `AGENTS.md`, `README.md`, `.gitignore`, `LICENSE`, `docs/feasibility-report.md`, `docs/github-governance.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `SECURITY.md`, and probe files including `probes/omarchy-host/`.

Files modified: none.

Files intentionally not created yet: plugin manifest de production, production QML, shell config changes, keybindings, helper process, tests de production, `.pi` resources. Le manifest/QML sous `probes/omarchy-host/` reste explicitement NON PRODUCTION.

## PI

Project-specific Pi resources created: none beyond `AGENTS.md`; no extension/skill/package.

Skills used: `omarchy` (consultation du guide; aucune configuration utilisateur modifiée).

Extensions used: none.

Packages added: none.

## VERIFICATION

Important commands executed:

- `pi --version`, inspection de `~/.pi/agent/settings.json` et variables `PI_*`.
- lecture des docs Pi installées.
- `omarchy version`, `hyprctl version`, `qs --version`, `omarchy plugin list --json`, `omarchy-shell shell ping/listPlugins`.
- lecture du contrat local Omarchy et de `PluginRegistry.qml`.
- `gh repo create Roddygithub/OmaPiP --public ...`.
- inspection `git status`/diff avant publication.

Tests/probes executed:

- `timeout 5s qs -p probes/enumerate.qml` — lancement réussi, `screens=1`, `toplevels=0` dans l'instance isolée.
- `timeout 8s qs -p probes/capture.qml` — lancement réussi, `capture hasContent=true`, `sourceSize=1261x1030`.
- `omarchy plugin validate <temporary-fixture>` — PASS.
- `hyprctl clients -j`, `hyprctl monitors -j` — PASS.
- `omarchy plugin validate probes/omarchy-host` — PASS.
- Installation temporaire, `omarchy plugin enable`, `omarchy-shell shell summon`, `omarchy-shell shell call`, puis désactivation/suppression/restauration — PASS.
- Redémarrage officiel `omarchy restart shell` — PASS; `omarchy-shell shell ping` répond `ok` après cleanup.
- Dispatchers Hyprland temporaires float/pin/move/resize/fullscreen/close — PASS pour les opérations démontrées, sans règle persistante.
- Mesures RSS/CPU indicatives avec capture puis après cleanup — PASS, voir la section host.

Passed: contexte host réel, plugin load, toplevel enumeration/mapping, capture live, obscuration, resize lifecycle, workspace lifecycle, destruction/recovery, dynamic source switching, floating, pin, performance indicative.

Failed: always-above, clic gauche + drag, resize souris 8 zones, feedback curseur, ratio conservé, placement automatique; les probes standalone restent non représentatifs pour les toplevels.

Skipped/deferred: multi-écrans et mixed-DPI (`DEFERRED_ENVIRONMENT_LIMITATION`), aucun écran virtuel créé; fullscreen source non testé séparément.

## SOURCES

Pi official documentation consulted: documentation installée Pi 0.85.1 sous `/home/roddy/.local/share/mise/installs/pi/0.85.1/pi/docs/` — usage, settings, sessions, compaction, security, skills, extensions, prompt-templates, packages, environment-variables, session-format.

Omarchy official documentation/code consulted: `/usr/share/omarchy/shell/README.md`, `/usr/share/omarchy/shell/plugins/README.md`, `/usr/share/omarchy/default/agents/skills/omarchy/plugins.md`, `/usr/share/omarchy/shell/services/PluginRegistry.qml`, `/usr/share/omarchy/shell/services/PluginRegistryApi.qml`, manifests first-party et config shell.

Hyprland documentation consulted: sorties locales `hyprctl version`, `clients -j`, `activewindow -j`, `monitors -j`; `/usr/share/omarchy/config/hypr/xdph.conf`.

Quickshell documentation consulted: métadonnées de types installées pour `ScreencopyView`, `Toplevel`, `ToplevelManager`, `FloatingWindow`; exemples `/usr/share/omarchy/shell/plugins/dev-gallery/GalleryPanel.qml`.

Relevant plugins inspected: `omarchy.dev-gallery`, `omarchy.monitor`, `omarchy.menu`, `omarchy.image-picker`, `omarchy.bar`, `io.github.andressm415.omaprox`, `io.github.thisisgm.discord`, `quickshell.spotify`, `OmaWhatsApp`, `OmaConnect`, et le probe temporaire `probes/omarchy-host`.

## HUMAN DECISIONS REQUIRED

- Valider ou rejeter la poursuite vers les probes interactifs manuels sur une seconde sortie/avec fenêtres de test.
- Après ces probes, approuver explicitement (ou non) l'architecture avant l'implémentation V1.
