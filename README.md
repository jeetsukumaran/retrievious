
# Retrievious

*Retrievious* is a coordinated set of multiplexed commands and key-bindings for retrieving and acting on files and directory paths.
When the files provided by *Retrievious* are sourced, added to, or otherwise read in by your shell and editor configurations, you will be provided a common interface and experience in both your shell and editor to find files and directories across anywhere in your filesystem with precision using a range of search modes (fuzzy find by name, grep by content, etc.).
*Retrievious* is essentially an abstraction layer between you and a set of *very* good tools that all do *very* good jobs in *very* good ways.

When the scripts and configuration files given by *Retrievious* are sourced, included, or otherwise loaded by your shell and editor configurations, you will be provided you with a common "grammar" n your shell and editor for specifying with surgical precision (1) what path on your filesystem you want, and (b) what you want to do with it.
It very quickly becomes intuitive to "speak" in this grammar to locate, for e.g. a file using a fuzzy search pattern for its search, with the search starting from a directory 2 levels up from your current one, and thn, when found, change to the parent directory of the located file and open it up in your text editor.
##  Dependencies

### Shell Programs

-   [fzf](https://github.com/junegunn/fzf)
-   [ripgrep](https://github.com/BurntSushi/ripgrep)
-   [fasd](https://github.com/clvv/fasd)
-   [bat](https://github.com/sharkdp/bat)

### Neovim Plugins

#### Required

-   [Telescope](https://github.com/nvim-telescope/telescope.nvim)
-   [plenary](https://github.com/nvim-lua/plenary.nvim)
-   [popup](https://github.com/nvim-lua/popup.nvim)
-   [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native.nvim)
-   [telescope-grab-lines](https://github.com/jeetsukumaran/telescope-grab-lines.nvim)

### MVP Commands

- Type `<Alt-Shift-F>` to pull up a fuzzy finder dialog to find a file by name to edit, with the *home directory* as the root of the search.
- Type `<Alt-Shift-D>`  to pull up a fuzzy finder dialog to find a directory by name to open up in your editor, with the *home directory* as the root of the search.
- Type `<Alt-Shift-G>`  to pull up a fuzzy finder dialog to grep for a file to edit, with the *home directory* as the root of the search.

## Installation

1.  Clone this repository:

    ```
    $ cd ~/.local/share
    $ git clone git@github.com:jeetsukumaran/retrievious.git
    ```

2.  Source the shell script extension by adding the following to your `~/.bashrc`

    ```
    source ~/.local/share/retrievious/shell/retrievious.bash
    ```

3.  Add the Neovim extension path to your runtime path by adding the following to your `init.vim`

    ```
    set runtimepath+=~/.local/share/retrievious/nvim
    ```

## Customization

The following environmental variables can be set:

-   `$RETRIEVIOUS_PRUNE_NAMES`
    -   A space-separated list of directory/file names to exclude.
        E.g.,
        ```
        export RETRIEVIOUS_PRUNE_NAMES="snap R anaconda3"
        ```
        Note that hidden files (starting with '.') are ignored by default.
-   `$RETRIEVIOUS_PRUNE_PATHS`
    -   A space-separated list of directory/file paths to exclude.
        E.g.,
        ```
        export RETRIEVIOUS_PRUNE_NAMES="/var/* scratch/tmp"
        ```
        Note that hidden files (starting with '.') are ignored by default.
-   `$RETRIEVIOUS_EDIT_PRUNE_NAMES`
    -   As above, but only applied when retrieving files to open in the editor.
-   `$RETRIEVIOUS_EDIT_PRUNE_NAMES`
    -   As above, but only applied when retrieving files to open in the editor.
-   `$RETRIEVIOUS_EDIT_PRUNE_PATHS`
    -   As above, but only applied when retrieving files to open in the editor.
-   `$RETRIEVIOUS_BASH_COMMAND_HISTORY`
    -   Source of bash history commands (defaults to "`bash_history`").

## Example Configuration

```bash
export RETRIEVIOUS_PRUNE_NAMES="\
snap R r *.pyc
"
export RETRIEVIOUS_PRUNE_PATHS="**/Environment/python"
export RETRIEVIOUS_EDIT_PRUNE_NAMES="${RETRIEVIOUS_PRUNE_NAMES} \
 *.ai *.gif *.jpg *.jpeg *.pdf *.png *.svg *.tiff *.tgz \
 *.AI *.GIF *.JPG *.JPEG *.PDF *.PNG *.SVG *.TIFF *.TGZ \
"
export RETRIEVIOUS_EDIT_PRUNE_PATHS="${RETRIEVIOUS_PRUNE_PATHS}"
export RETRIEVIOUS_BASH_COMMAND_HISTORY=$HOME/.bash_log
export RETRIEVIOUS_FDFIND_OPTS="--no-ignore-vcs"
export RETRIEVIOUS_RIPGREP_OPTS="--no-ignore-vcs"
set -o vi # This needs to come before sourcing so that vi key bindings are correctly mapped below
source "/home/gandalf/.local/share/retrievious/shell/retrievious.bash"
```

## Keybindings

### Filesystem Retrievals for Editing/Opening

| Key                    | Search | For  | From                               | S? | E? |
|:-----------------------|:-------|:-----|:-----------------------------------|:---|:---|
| **Find File**          |        |      |                                    |    |    |
| `<Alt-r>~`             | Find   | file | `$HOME`                            | Y  | Y  |
| `<Alt-r>.`             | Find   | file | cwd                                | Y  | Y  |
| `<Alt-r>`*[count]*`.`  | Find   | file | *[count]* up from cwd              | Y  | Y  |
| `<Alt-r>%`             | Find   | file | Buffer local dir                   | N  | Y  |
| `<Alt-r>`*[count]*`%`  | Find   | file | *[count]* up from buffer local dir | N  | Y  |
| **Find Dirs**          |        |      |                                    |    |    |
| `<Alt-r>d~`            | Find   | dir  | `$HOME`                            | Y  | *  |
| `<Alt-r>d.`            | Find   | dir  | cwd                                | Y  | *  |
| `<Alt-r>`*[count]*`d.` | Find   | dir  | *[count]* up from cwd              | Y  | *  |
| **Grep Text**          |        |      |                                    |    |    |
| `<Alt-r>g~`            | Grep   | text | `$HOME`                            | Y  | Y  |
| `<Alt-r>g.`            | Grep   | text | cwd                                | Y  | Y  |
| `<Alt-r>g`*[count]*`.` | Grep   | text | *[count]* up from cwd              | Y  | Y  |
| `<Alt-r>g%`            | Grep   | text | Buffer local dir                   | N  | Y  |
| `<Alt-r>g`*[count]*`%` | Grep   | text | *[count]* up from buffer local dir | N  | Y  |
| **Find Lines**         |        |      |                                    |    |    |
| `<Alt-r>l`             | Find   | line | Current buffer                     | N  | Y  |

### Filesystem Path Retrievals for Pasting/Putting

| Key                     | Search | For      | From                  | S? | E? |
|:------------------------|:-------|:---------|:----------------------|:---|:---|
| `<Alt-r>pf~`            | Find   | file     | `$HOME`               | *  | *  |
| `<Alt-r>pf.`            | Find   | file     | cwd                   | Y  | Y  |
| `<Alt-r>pf`*[count]*`.` | Find   | file     | *[count]* up from cwd | Y  | Y  |
| `<Alt-r>pd~`            | Find   | dir      | `$HOME`               | Y  | *  |
| `<Alt-r>pd.`            | Find   | dir      | cwd                   | Y  | ?  |
| `<Alt-r>pd`*[count]*`.` | Find   | dir      | *[count]* up from cwd | Y  | ?  |
| `<Alt-r>pc`             | Find   | commands | cwd                   | Y  | ?  |

### Frecent Retrievals

| Key         | Target    | S? | E? | Action  |
|:------------|:----------|:---|:---|---------|
| `<Alt-r>rf` | file      | Y  | Y  | Cd/Edit |
| `<Alt-r>rd` | directory | Y  | *  | Cd/Edit |
| `<Alt-r>rc` | commands  | Y  | -  | Cd/Edit |
| `<Alt-r>prf` | file      | Y  | Y  | Paste   |
| `<Alt-r>prd` | directory | Y  | *  | Paste   |
| `<Alt-r>prc` | commands  | Y  | -  | Paste   |

## Appendices

### Index of Key Sequences

#### 1.1.1. Retrieve [to edit]: [Find] [File]

- `<alt-r>~`
- `<alt-r>.`
- `<alt-r>1.`
- `<alt-r>2.`
- `<alt-r>3.`
- `<alt-r>4.`
- `<alt-r>5.`
- `<alt-r>6.`
- `<alt-r>7.`
- `<alt-r>8.`
- `<alt-r>9.`

#### 1.1.2. Retrieve [to edit]: [Find] Directory

- `<alt-r>d~`
- `<alt-r>d.`
- `<alt-r>d1.`
- `<alt-r>d2.`
- `<alt-r>d3.`
- `<alt-r>d4.`
- `<alt-r>d5.`
- `<alt-r>d6.`
- `<alt-r>d7.`
- `<alt-r>d8.`
- `<alt-r>d9.`

#### 1.1.3. Retrieve [to edit]: [Find] Buffer

- `<alt-r>b`

#### 1.1.4. Retrieve [to edit]: [Find] Lines

- `<alt-r>l`

#### 1.2.1. Retrieve [to edit]: Grep [File]

- `<alt-r>g~`
- `<alt-r>g.`
- `<alt-r>g1.`
- `<alt-r>g2.`
- `<alt-r>g3.`
- `<alt-r>g4.`
- `<alt-r>g5.`
- `<alt-r>g6.`
- `<alt-r>g7.`
- `<alt-r>g8.`
- `<alt-r>g9.`

#### 1.2.2. Retrieve [to edit]: Grep [Buffer]

- `<alt-r>gb`

#### 1.3.1. Retrieve [to edit]: Recent

- `<alt-r>rc`
- `<alt-r>rd`
- `<alt-r>rf`

#### 2.1.1. Retrieve to *p*aste: [Find] [File]

- `<alt-r>p~`
- `<alt-r>p.`
- `<alt-r>p1.`
- `<alt-r>p2.`
- `<alt-r>p3.`
- `<alt-r>p4.`
- `<alt-r>p5.`
- `<alt-r>p6.`
- `<alt-r>p7.`
- `<alt-r>p8.`
- `<alt-r>p9.`

#### 2.1.2. Retrieve to *p*aste: [Find] Directory

- `<alt-r>pd~`
- `<alt-r>pd.`
- `<alt-r>pd1.`
- `<alt-r>pd2.`
- `<alt-r>pd3.`
- `<alt-r>pd4.`
- `<alt-r>pd5.`
- `<alt-r>pd6.`
- `<alt-r>pd7.`
- `<alt-r>pd8.`
- `<alt-r>pd9.`

#### 2.2.1. Retrieve to *p*aste: Lines

- `<alt-r>pl~`
- `<alt-r>pl.`
- `<alt-r>pl1.`
- `<alt-r>pl2.`
- `<alt-r>pl3.`
- `<alt-r>pl4.`
- `<alt-r>pl5.`
- `<alt-r>pl6.`
- `<alt-r>pl7.`
- `<alt-r>pl8.`
- `<alt-r>pl9.`

#### 2.3.1. Retrieve to *p*aste: Recent

- `<alt-r>prc`
- `<alt-r>prd`
- `<alt-r>prf`

#### 3.1.1. Retrieve to *o*pen

- `<alt-r>o~`
- `<alt-r>o.`
- `<alt-r>o1.`
- `<alt-r>o2.`
- `<alt-r>o3.`
- `<alt-r>o4.`
- `<alt-r>o5.`
- `<alt-r>o6.`
- `<alt-r>o7.`
- `<alt-r>o8.`
- `<alt-r>o9.`
