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

Window enumeration: PASS — `hyprctl clients -j` retourne 3 clients avec adresse stable, classe, titre, PID, workspace.

Active window identification: PASS — `hyprctl activewindow -j` disponible; `ToplevelManager.activeToplevel` est exposé par Quickshell mais nul dans le probe isolé.

Interactive window selection: FAIL — aucune sélection interactive sûre n'a été lancée; `slurp` est installé mais sélectionne une région, pas une fenêtre native.

Hyprland ↔ Toplevel mapping: FAIL — Toplevel expose appId/titre/workspace-écrans mais pas l'adresse Hyprland/PID observé; corrélation heuristique seulement.

Live arbitrary-window capture: PASS — probe `probes/capture.qml` avec `ScreencopyView.captureSource` a produit `hasContent=true`, source `1261x1030`.

Toplevel capture: PASS — le même probe compile et accepte un `Toplevel` comme `captureSource`; résultat live observé.

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

## ARCHITECTURE DECISION

Recommended Omarchy plugin kind(s): `panel`; possiblement `service` si la sélection/source doit survivre indépendamment de la fenêtre.

Recommended architecture: plugin Omarchy tiers minimal, chargé on-demand, avec `FloatingWindow` + `ScreencopyView` + `ToplevelManager`; utiliser `hyprctl`/IPC seulement pour les opérations compositor qui ne sont pas exposées nativement.

External process/helper required: `NO` pour le chemin de capture démontré; **décision finale bloquée** par déplacement/redimensionnement, multi-écran et stabilité non testés.

If YES, exact demonstrated reason: N/A. Un helper ne doit être ajouté que si les probes manquants démontrent que le protocole de fenêtre/resize ou l'isolation ne peut pas être satisfait dans le shell.

Languages/technologies proposed: QML/Quickshell 0.3.1, Wayland `ScreencopyView`, `ToplevelManager`, Hyprland IPC/dispatch si nécessaire.

Main components: source selector, source identity/model, `ScreencopyView`, `FloatingWindow`, placement/resize controller, lifecycle/IPC.

Communication mechanism if applicable: IPC shell Omarchy pour summon/change/close; `hyprctl` IPC uniquement après preuve qu'une API native Quickshell ne suffit pas.

Why this architecture is preferred: capture live d'un Toplevel observée sans dépendance ni modification d'Omarchy système; elle respecte le plugin natif et garde le code court.

Alternatives rejected: capture d'écran périodique (`grim`) — ce n'est pas un miroir live indépendant et serait plus lourd; helper Rust/C — aucune nécessité démontrée; layer-shell plein écran — risque connu de capture/input region et mauvais modèle pour une fenêtre déplaçable.

Impact on omarchy-shell stability: important — un plugin QML s'exécute dans le processus principal non sandboxé; éviter les boucles/bloquages et préférer une capture native. Un helper isolé ne se justifie qu'après démonstration d'un risque ou d'une limite réelle.

Future Interactive Mirror compatibility: conserver capture et surface comme composants séparés; l'injection de clic/clavier exige des protocoles Wayland dédiés (probablement portail/virtual-input), consentement et contrôle de sécurité. Ne pas transmettre d'input en V1.

Known limitations: aucun mapping unique démontré entre adresse Hyprland et objet Toplevel; tests interactifs et multi-écrans absents; `FloatingWindow` ne garantit pas à lui seul above/all-workspaces ni déplacement libre.

Risks: capture autorisée par configuration (`xdph.conf` contient `allow_token_by_default = true`), fuite/crash dans `omarchy-shell`, surfaces qui interceptent les clics, disparition de la source, coûts GPU/CPU pendant resize.

Blockers: exécuter sur une seconde sortie et tester manuellement source couverte/redimensionnée/détruite; démontrer drag gauche, 8 zones de resize, placement, above/pin et changement de source; mesurer CPU/mémoire.

`READY_TO_IMPLEMENT: NO`

## STOP CONDITION

Arrêt volontaire avant toute implémentation V1. Les deux probes QML sont jetables et ne sont pas du code de production.

## REPOSITORY

Local path: `/home/roddy/Projects/OmaPiP`

GitHub repository: `https://github.com/Roddygithub/OmaPiP`

Visibility: public

Current branch: `main`

HEAD: voir `git rev-parse HEAD` après le commit initial

Git status: propre après publication prévue

Remote: `origin https://github.com/Roddygithub/OmaPiP.git`

Commits created: initial feasibility study

Push status: pending until final diff/status inspection

## FILES

Files created: `AGENTS.md`, `README.md`, `.gitignore`, `docs/feasibility-report.md`, `probes/enumerate.qml`, `probes/capture.qml`.

Files modified: none.

Files intentionally not created yet: plugin manifest, production QML, shell config changes, keybindings, helper process, tests de production, `.pi` resources.

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

Passed: versions, repo GitHub, manifest fixture, Hyprland enumeration, FloatingWindow mapping, ScreencopyView content.

Failed: Toplevel list dans probe isolé, mapping adresse↔Toplevel, et tous les essais interactifs/non disponibles listés ci-dessus.

Skipped: tests multi-écrans, obscuration, destruction, drag/resize, performance, changement source.

## SOURCES

Pi official documentation consulted: documentation installée Pi 0.85.1 sous `/home/roddy/.local/share/mise/installs/pi/0.85.1/pi/docs/` — usage, settings, sessions, compaction, security, skills, extensions, prompt-templates, packages, environment-variables, session-format.

Omarchy official documentation/code consulted: `/usr/share/omarchy/shell/README.md`, `/usr/share/omarchy/shell/plugins/README.md`, `/usr/share/omarchy/default/agents/skills/omarchy/plugins.md`, `/usr/share/omarchy/shell/services/PluginRegistry.qml`, `/usr/share/omarchy/shell/services/PluginRegistryApi.qml`, manifests first-party et config shell.

Hyprland documentation consulted: sorties locales `hyprctl version`, `clients -j`, `activewindow -j`, `monitors -j`; `/usr/share/omarchy/config/hypr/xdph.conf`.

Quickshell documentation consulted: métadonnées de types installées pour `ScreencopyView`, `Toplevel`, `ToplevelManager`, `FloatingWindow`; exemples `/usr/share/omarchy/shell/plugins/dev-gallery/GalleryPanel.qml`.

Relevant plugins inspected: `omarchy.dev-gallery`, `omarchy.monitor`, `omarchy.menu`, `omarchy.image-picker`, `omarchy.bar`, `io.github.andressm415.omaprox`, `io.github.thisisgm.discord`, `quickshell.spotify`, `OmaWhatsApp`, `OmaConnect`.

## HUMAN DECISIONS REQUIRED

- Valider ou rejeter la poursuite vers les probes interactifs manuels sur une seconde sortie/avec fenêtres de test.
- Après ces probes, approuver explicitement (ou non) l'architecture avant l'implémentation V1.
