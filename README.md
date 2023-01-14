
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

- Type `<Alt-Shift-F>` to pull up a fuzzy finder dialog to find a file by name to visit, with the *home directory* as the root of the search.
- Type `<Alt-Shift-D>`  to pull up a fuzzy finder dialog to find a directory by name to open up in your editor, with the *home directory* as the root of the search.
- Type `<Alt-Shift-G>`  to pull up a fuzzy finder dialog to grep for a file to visit, with the *home directory* as the root of the search.

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

## Appendices

### Global Search Paths

You can defined two global search path environmental variables, `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS1` and `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS2`.
Each of these can be a *SEMI-COLON* separated list of paths (semi-colon was selected to allow the 'colon' character to be part of the path as might be needed for Windows.
These paths will be searched when the "global search" commands are used:

-   `RETRIEVIOUS_GLOBAL_SEARCH_PATHS1`
    - `<alt-r><alt-f>`
    - `<alt-r><alt-d>`
    - `<alt-r><alt-g>`
-   `RETRIEVIOUS_GLOBAL_SEARCH_PATHS2`
    - `<alt-r><ctrl-f>`
    - `<alt-r><ctrl-d>`
    - `<alt-r><ctrl-g>`

For example, you can define the following to have one special search of your local ecosystem and another of all mounted drives:

```
export RETRIEVIOUS_GLOBAL_SEARCH_PATHS1='~/.local/;~/.config'
export RETRIEVIOUS_GLOBAL_SEARCH_PATHS2='/media/username;/mnt/;~/remotes/;'
```

By default, if undefined, they take on the value of "`$HOME`".

### Index of Key Sequences

#### 1.1.1. Retrieve [to visit]: [Find] [File]

- `<alt-r>f~`
    -   Searches for a file to visit, using find, starting at `$HOME`.
- `<alt-r>f.`
    -   Searches for a file to visit, using find, starting at the current working directory.
- `<alt-r>f1.`, `<alt-r>f2.`, `<alt-r>f3.`, ... `<alt-r>f9.`
    -   Searches for a file to visit, using find, starting at directory 1, 2, 3, etc. directory levels up from current working directory.
- `<alt-r>f/`
    -   Searches for a file to visit, using find, starting at filesystem root.
- `<alt-r><alt-f>`
    -   Searches for a file to visit, using find, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS1`.
- `<alt-r><alt-f>`
    -   Searches for a file to visit, using find, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS2`.

#### 1.1.2. Retrieve [to visit]: [Find] Directory

- `<alt-r>d~`,
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
- `<alt-r><alt-d>`
    -   Searches for a directory to visit, using find, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS1`.
- `<alt-r><ctrl-d>`
    -   Searches for a directory to visit, using find, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS2`.

#### 1.1.3. Retrieve [to visit]: [Find] Buffer

- `<alt-r>b`

#### 1.1.4. Retrieve [to visit]: [Find] Lines (in Buffer)

- `<alt-r>l`

#### 1.2.1. Retrieve [to visit]: Grep [File]

- `<alt-r>g~`
- `<alt-r>g.`
- `<alt-r>g/`
- `<alt-r>g1.`
- `<alt-r>g2.`
- `<alt-r>g3.`
- `<alt-r>g4.`
- `<alt-r>g5.`
- `<alt-r>g6.`
- `<alt-r>g7.`
- `<alt-r>g8.`
- `<alt-r>g9.`
- `<alt-r><alt-g>`
    -   Searches for a file to visit, using grep, starting at the directory of the current buffer.
- `<alt-r><ctrl-g>`
    -   Searches for a file to visit, using grep, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS1`.

#### 1.2.2. Retrieve [to visit]: Grep (Open) Buffers

- `<alt-r>gb`, `<alt-r>/`

#### 1.2.3. Retrieve [to visit]: Grep Lines (in Current Buffer)

- `<alt-r>gl`, `<alt-r>\`


#### 1.3.1. Retrieve [to visit]: *r*ecent *f*iles, *d*irectories, and *c*ommands

- `<alt-r>rf`
- `<alt-r>rd`
- `<alt-r>rc`

#### 2.1.1. Retrieve to *p*aste: [Find] [File]

- `<alt-r>pf~`
- `<alt-r>pf.`
- `<alt-r>pf1.`
- `<alt-r>pf2.`
- `<alt-r>pf3.`
- `<alt-r>pf4.`
- `<alt-r>pf5.`
- `<alt-r>pf6.`
- `<alt-r>pf7.`
- `<alt-r>pf8.`
- `<alt-r>pf9.`

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

- `<alt-r>plb`
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

#### 2.3.1. Retrieve to *p*aste: *r*ecent *f*iles, *d*irectories, and *c*ommands

- `<alt-r>prf`
- `<alt-r>prd`
- `<alt-r>prc`

#### 3.1.1. Retrieve to *o*pen: [Find] [File]

- `<alt-r>of~`
- `<alt-r>of.`
- `<alt-r>of1.`
- `<alt-r>of2.`
- `<alt-r>of3.`
- `<alt-r>of4.`
- `<alt-r>of5.`
- `<alt-r>of6.`
- `<alt-r>of7.`
- `<alt-r>of8.`
- `<alt-r>of9.`
