# 0. Get Access to the Source Code and These Guides

This is the first step for the customer's technical team, sent to you by
email when your contract starts. It gives one computer read-only access to
the app's source code; the deployment guides are part of it. About 10
minutes, plus our confirmation (usually within one working day).

Repeat it for every computer of your team that needs access: each computer
has its own key.

## Step 1: Create a key on your computer

1. Install [Git](https://git-scm.com/downloads). It includes SSH.
2. Open a terminal (**Terminal** on a Mac, **PowerShell** on Windows) and run:

   ```
   ssh-keygen -t ed25519 -f ~/.ssh/skeleton_key -q -N "" -C "<your-company>-<your-name>"
   ```

   It creates two files in your `.ssh` folder: `skeleton_key` (private, a
   **secret**: it never leaves this computer) and `skeleton_key.pub`
   (public).

## Step 2: Send us the public key

Email `skeleton_key.pub` (the file ending in `.pub`, one line starting with
`ssh-ed25519`) to [medsalemkhattat@gmail.com](mailto:medsalemkhattat@gmail.com),
with your company name and your name. **Never send the file without `.pub`.**

We add it as a **read-only** key and confirm by email.

## Step 3: Clone the source code

After our confirmation:

1. Tell SSH to use the key: add these lines to the file `~/.ssh/config`
   (create it if it does not exist; on Windows it is
   `C:\Users\<you>\.ssh\config`):

   ```
   Host skeleton-source
     HostName github.com
     User git
     IdentityFile ~/.ssh/skeleton_key
     IdentitiesOnly yes
   ```

2. Clone, and switch to the release tag we announced:

   ```
   git clone skeleton-source:medsalem-khattat/skeleton.git
   cd skeleton
   git checkout v1.1.0
   ```

   `git tag` lists every release.

## Step 4: Read the guides

The guides are in the folder `docs/customer-setup/` of your copy. Start with
`docs/customer-setup/README.md`.

They are Markdown files. To read them with formatting and clickable links,
open the `skeleton` folder in [Visual Studio Code](https://code.visualstudio.com/)
(free) and press **Ctrl+Shift+V** (**Cmd+Shift+V** on a Mac) on a file. Any
text editor can also open them.

## Getting updates

Every release updates the guides too. To get them:

```
git fetch --tags
git checkout <new tag>
```

Read the guides of the version you deploy: they match its tools and
workflows.

## If something goes wrong

| Message | Meaning |
| --- | --- |
| `Permission denied (publickey)` | Our confirmation has not arrived yet, or SSH does not use the key: check `~/.ssh/config` and the key's file name |
| `Repository not found` | Same as above: GitHub hides private repositories from unknown keys |
| `Host key verification failed` | First connection: run `ssh -T skeleton-source` once and answer `yes` |
