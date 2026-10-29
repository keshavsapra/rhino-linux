# Running Rhino without any connection to McNeel

Rhino normally talks to McNeel's servers on its own: licence validation for
Cloud Zoo and Rhino Accounts, the update check, anonymous usage statistics,
crash report uploads, the news panel, help lookups in the browser and the
package manager all connect out. This setup can keep every one of those from
reaching their servers while Rhino stays fully usable offline.

## What the offline mode does

`rhino-linux --offline` (or every launch, once you save it — below) starts
Rhino with four things taken care of:

1. **A network namespace with no network.** Rhino, Wine and everything Wine
   starts run inside an `unshare --user --map-root-user --net` sandbox whose
   only interface is the local loopback. There is no DNS server, no route and
   no internet in it: a connection to any host fails immediately. The loopback
   is kept, so Rhino's own local licence broker on 127.0.0.1 (port 1717)
   works. Nothing outside the machine can be reached — this covers McNeel and
   also any third-party plug-in that phones home.
2. **No embedded Edge browser.** The embedded WebView2 (used for Cloud Zoo
   sign-in and HTML panels) is swapped for a stub that never starts a browser
   process — Chrome/Edge's own background traffic included. HTML panels stay
   blank, which is expected: their content comes from the network.
3. **No update checks or statistics.** The launcher sets the registry value
   behind Options > Updates and Statistics
   (`HKCU\Software\McNeel\McNeelUpdate\7|8|9`, `Enabled` = `False`), so Rhino
   stops even trying to phone home for updates or sending usage statistics.
4. **A refusal to start online by accident.** If the namespace cannot be
   created (for example, unprivileged user namespaces are disabled), the
   launcher stops with an error instead of quietly starting Rhino online.
   Start it anyway with `RHINO_OFFLINE_FALLBACK=1`, or use the hosts
   blocklist below as the fallback.

## One-time: install and activate

Your single-computer licence key has to meet McNeel's servers exactly once,
when Rhino validates it. After that first validation Rhino runs on the stored
licence with no connection at all for its lifetime.

```bash
# 1. Install Rhino (needs the network for the installer itself):
./install.sh --installer /path/to/rhino_installer.exe

# 2. First start: activate your licence key while the network is up.
#    Signing in or entering the key in the licence dialog happens exactly once.
rhino-linux --online

# 3. From now on, every launch — including the menu icons — is fully offline:
rhino-linux --set-offline 1

# 4. Check it worked:
getent hosts api.mcneel.com   # inside Rhino's namespace: empty
```

To bring the network back for one launch afterwards (a plug-in install, for
example), run `rhino-linux --online`; the next launch is offline again.
`--set-offline 0` turns the default back to online for every launch.

A per-launch choice is also possible with the environment variable
`RHINO_OFFLINE=1 rhino-linux`.

## Who needs the network, and when

| Licence type | Can run permanently offline? | Needs the network first? |
|---|---|---|
| Single-computer licence key | Yes — forever | Yes, once, when the key is validated |
| Cloud Zoo (Rhino account) | Only about two weeks at a time | Yes, to sign in, then a periodic check-in |

With a Cloud Zoo licence cut off for too long, Rhino eventually asks to
revalidate and stops starting until it can. If your machine must never call
McNeel, use the single-computer licence key mode
(Options > Licenses > Change licence key). Note that educational lab and
sharing arrangements differ; ask McNeel if unsure.

Your "validation code and activation code" pair is the old offline validation
flow of Rhino 5. Recent Rhino versions (7/8/9) do not have it: entering a
licence key needs one online validation. Regardless, with the codes above in
hand you activate once with `rhino-linux --online` and then go offline —
after that, the machine never contacts McNeel.

## What you give up offline

- **Package Manager / food4Rhino**: installing plug-ins from the network.
  Download plug-ins as files first, then use the app's "Install a plug-in…" or
  `tools/install-plugin.sh file.rhi|file.zip` instead.
- **News panel, help look-ups, "What's new"**: stay blank — they are web views.
- **Script Editor on Rhino 8**: the built-in editor's interface loads from
  Rhino itself, but keep in mind WebView-based editors of any plug-in are
  offline too.
- **Cloud Zoo sign-in** and any OAuth flow.
- Everything in Rhino that does not need the network works: modelling,
  Grasshopper, Cycles/Rhino Render, tokenizing meshes, exporting, python and
  C# scripting run from local files, and saving `.3dm` files.

## Belt and braces: block McNeel in /etc/hosts

If you prefer a system-wide block that covers everything on the machine
(other accounts, a stray Rhino started with `--online`, any background tool),
resolve McNeel's servers to 127.0.0.1 in the hosts file by editing
`/etc/hosts` (adding a line like `127.0.0.1 api.mcneel.com` per server), or
use this repo's helper script:

```bash
sudo tools/block-mcneel-hosts.sh add     # block McNeel system-wide
sudo tools/block-mcneel-hosts.sh remove  # undo
tools/block-mcneel-hosts.sh list         # show what is in place
```

The names it blocks are listed in `tools/mcneel-domains.txt`. Wine resolves
hosts through the system resolver, so Rhino's HTML panels, the news feed, the
package manager, update checks and licence check-ins all fail to connect.
Delete the block before you validate a new licence with `--online`.

## Verifying

With Rhino running in offline mode (or with the hosts block in place), from a
terminal:

```bash
# Name resolution for McNeel fails (empty output):
getent hosts api.mcneel.com accounts.rhino3d.com discourse.mcneel.com

# Rhino itself runs fine:
rhino-linux model.3dm
```

You can also watch Rhino from the outside with your normal network monitor
(Utilities such as `ss`, `nethogs`, `iftop` or `wireshark`) and see that the
`rhino.exe` processes have no reachable sockets beyond loopback.
