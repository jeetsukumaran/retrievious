
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
    - `<alt-e><alt-f>`
    - `<alt-e><alt-d>`
    - `<alt-e><alt-g>`
-   `RETRIEVIOUS_GLOBAL_SEARCH_PATHS2`
    - `<alt-e><ctrl-f>`
    - `<alt-e><ctrl-d>`
    - `<alt-e><ctrl-g>`

For example, you can define the following to have one special search of your local ecosystem and another of all mounted drives:

```
export RETRIEVIOUS_GLOBAL_SEARCH_PATHS1='~/.local/;~/.config'
export RETRIEVIOUS_GLOBAL_SEARCH_PATHS2='/media/username;/mnt/;~/remotes/;'
```

By default, if undefined, they take on the value of "`$HOME`".

### Index of Key Sequences

#### 1.1.1. Retrieve [to visit]: [Find] [File]

- `<alt-e>f~`
    -   Searches for a file to visit, using find, starting at `$HOME`.
- `<alt-e>f.`
    -   Searches for a file to visit, using find, starting at the current working directory.
- `<alt-e>f1.`, `<alt-e>f2.`, `<alt-e>f3.`, ... `<alt-e>f9.`
    -   Searches for a file to visit, using find, starting at directory 1, 2, 3, etc. directory levels up from current working directory.
- `<alt-e><alt-f>`
    -   Searches for a file to visit, using find, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS1`.
- `<alt-e><alt-f>`
    -   Searches for a file to visit, using find, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS2`.

#### 1.1.2. Retrieve [to visit]: [Find] Directory

- `<alt-e>d~`,
- `<alt-e>d.`
- `<alt-e>d1.`
- `<alt-e>d2.`
- `<alt-e>d3.`
- `<alt-e>d4.`
- `<alt-e>d5.`
- `<alt-e>d6.`
- `<alt-e>d7.`
- `<alt-e>d8.`
- `<alt-e>d9.`
- `<alt-e><alt-d>`
    -   Searches for a directory to visit, using find, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS1`.
- `<alt-e><ctrl-d>`
    -   Searches for a directory to visit, using find, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS2`.

#### 1.1.3. Retrieve [to visit]: [Find] Buffer

- `<alt-e>b`

#### 1.1.4. Retrieve [to visit]: [Find] Lines (in Buffer)

- `<alt-e>l`

#### 1.2.1. Retrieve [to visit]: Grep [File]

- `<alt-e>g~`
- `<alt-e>g.`
- `<alt-e>g1.`
- `<alt-e>g2.`
- `<alt-e>g3.`
- `<alt-e>g4.`
- `<alt-e>g5.`
- `<alt-e>g6.`
- `<alt-e>g7.`
- `<alt-e>g8.`
- `<alt-e>g9.`
- `<alt-e><alt-g>`
    -   Searches for a file to visit, using grep, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS1`.
- `<alt-e><ctrl-g>`
    -   Searches for a file to visit, using grep, starting at `$RETRIEVIOUS_GLOBAL_SEARCH_PATHS2`.

#### 1.2.2. Retrieve [to visit]: Grep (Open) Buffers

- `<alt-e>gb`

#### 1.2.3. Retrieve [to visit]: Grep Lines (in Current Buffer)

- `<alt-e>gl`


#### 1.3.1. Retrieve [to visit]: *r*ecent *f*iles, *d*irectories, and *c*ommands

- `<alt-e>rf`
- `<alt-e>rd`
- `<alt-e>rc`

#### 2.1.1. Retrieve to *p*aste: [Find] [File]

- `<alt-e>pf~`
- `<alt-e>pf.`
- `<alt-e>pf1.`
- `<alt-e>pf2.`
- `<alt-e>pf3.`
- `<alt-e>pf4.`
- `<alt-e>pf5.`
- `<alt-e>pf6.`
- `<alt-e>pf7.`
- `<alt-e>pf8.`
- `<alt-e>pf9.`

#### 2.1.2. Retrieve to *p*aste: [Find] Directory

- `<alt-e>pd~`
- `<alt-e>pd.`
- `<alt-e>pd1.`
- `<alt-e>pd2.`
- `<alt-e>pd3.`
- `<alt-e>pd4.`
- `<alt-e>pd5.`
- `<alt-e>pd6.`
- `<alt-e>pd7.`
- `<alt-e>pd8.`
- `<alt-e>pd9.`

#### 2.2.1. Retrieve to *p*aste: Lines

- `<alt-e>plb`
- `<alt-e>pl~`
- `<alt-e>pl.`
- `<alt-e>pl1.`
- `<alt-e>pl2.`
- `<alt-e>pl3.`
- `<alt-e>pl4.`
- `<alt-e>pl5.`
- `<alt-e>pl6.`
- `<alt-e>pl7.`
- `<alt-e>pl8.`
- `<alt-e>pl9.`

#### 2.3.1. Retrieve to *p*aste: *r*ecent *f*iles, *d*irectories, and *c*ommands

- `<alt-e>prf`
- `<alt-e>prd`
- `<alt-e>prc`

#### 3.1.1. Retrieve to *o*pen: [Find] [File]

- `<alt-e>of~`
- `<alt-e>of.`
- `<alt-e>of1.`
- `<alt-e>of2.`
- `<alt-e>of3.`
- `<alt-e>of4.`
- `<alt-e>of5.`
- `<alt-e>of6.`
- `<alt-e>of7.`
- `<alt-e>of8.`
- `<alt-e>of9.`
