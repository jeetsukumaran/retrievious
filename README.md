
# Retrievious

*Retrievious* is a coordinated set of multiplexed commands and key-bindings for retrieving and acting on files and directory paths.
When the files provided by *Retrievious* are sourced, added to, or otherwise read in by your shell and editor configurations, you will be provided a common interface and experience in both your shell and editor to find files and directories across anywhere in your filesystem with precision using a range of search modes (fuzzy find by name, grep by content, etc.).
*Retrievious* is essentially an abstraction layer between you and a set of *very* good tools that all do *very* good jobs in *very* good ways.

When the scripts and configuration files given by *Retrievious* are sourced, included, or otherwise loaded by your shell and editor configurations, you will be provided you with a common "grammar" n your shell and editor for specifying with surgical precision (1) what path on your filesystem you want, and (b) what you want to do with it.
It very quickly becomes intuitive to "speak" in this grammar to locate, for e.g. a file using a fuzzy search pattern for its search, with the search starting from a directory 2 levels up from your current one, and thn, when found, change to the parent directory of the located file and open it up in your text editor.
This grammar not only has a simple vocabulary, of only a few words, but is itself also simple.
It mostly consists of 4-word combinations that express:

```
<action-to-be-carried-out> <object on which it is going be carried out on><how to search for the object><where to start looking for the object>
```


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
-   [telescope-grab-lines](https://github.com/jeetsukumaran/telescope-grab-lines.nvim)

#### Recommended

-   [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native.nvim)


##  Interface

### Example workflow

-   In either your shell OR your editor:
    - Type `<Alt-f>f.`  (="Find file from '`.`' ") to pull up a fuzzy finder dialog that lets you select a file by name to open up in your editor, with the current working directory as the root of the search.
    - Type `<Alt-f>f2.` (="Find file from *2* directory levels up") to pull up a fuzzy finder dialog that lets you select a file by name to open up in your editor, with the directory two levels up from the current as the root of the search.
    - Type `<Alt-f>f~`  (="Find file from '`~`' ") as above, but start search in home directory.
    - Type `<Alt-r>f`   (="Recent File") to pull up a fuzzy finder dialog that lets you select a "frecent" file by name to open up in your editor, with the current directory as the root of the search.
    - Type `<Alt-g>.`   (="Grep for file contents from '`.`'") to pull up a fuzzy finder dialog that lets you select a file by grepped contents to open up in your editor, with the current directory as the root of the search.
    - Type `<Alt-g>4.`  (="Grep for file contents from *4* directory levels up") to pull up a fuzzy finder dialog that lets you select a file by grepped contents to open up in your editor, with the directory four levels up from the currentas the root of the search.
    - Type `<Alt-g>~`   (="Grep for file contents from '`~`'") as above, but start search in home directory.
-   Additional shell-specific functionality:
    -   Type `<Alt-f>d.` (="Find directory from '`.`'") to pull up a fuzzy finder to select a directory by name to change to, with search starting from the current working directory.
    -   Type `<Alt-f>d~` (="Find drectory from '`~`'") as above, but start search from home directory.
    -   Type `<Alt-r>d` (="Recent directory") as above, but search "frecent" directories.

There are a number of other functionalities, including variants of above, which allow you to specify a relative parent directory to start the search (e.g., ``<Alt-g>f3.`` to start the search three directory levels up), as well as custom functionality to put/paste the retreived result onto the command line in the shell or content lines into the buffer in the editor.

### In Detail

The Retrievious "grammar" consists of three keystrokes, specifying, in order: the search mode, the search object, and the search location.

-   The first keystroke is you specifying one the following three search modes:

    1.   `<Alt-f>` for "Find": this begins the process of searching for a file or directory in the filesystem by matching it's name.
    2.   `<Alt-g>` for "Grep": this begins the process of searching for a file in the filesystem by matching its content.
    3.   `<Alt-r>` for "Recent": this begins the process of searching for a recently used file or visted directory by matching it's name.

-   The second keystroke indicates whether it is a file or directory being searched for:

    -   `f` for "file"
    -   `d` for "directory"

-   When the third keystroke (or keystrokes) specifies the location that the search starts in:

    -   (1) and (2) can take an optional single-digit *count* before which specifies the number of levels up from the current working directory the search will begin.
        E.g., "1." means parent directory of the current working directory; "2." means two directory levels up from the current working diretory; etc..

    -   Instead of `[count].` , `~` starts the search from the home directory

The following summarizes the basic commands and key mappings:

| Key Sequence | With Count      | Search Type                | Starting Search             |
|:-------------|:----------------|:---------------------------|:----------------------------|
| `<Alt-f>f~`  |                 | Find file                  | home                        |
| `<Alt-f>f.`  |                 | Find file                  | cwd                         |
|              | `<Alt-e> f 1 .` | Find file                  | 1 dir up from cwd           |
|              | `<Alt-e> f 2 .` | Find file                  | 2 dirs up from cwd          |
|              | `<Alt-e> f 3 .` | Find file                  | 3 dirs up from cwd          |
|              | etc.            | etc.                       | etc.                        |
| `<Alt-g>f.`  |                 | Grep for file by content   | cwd                         |
|              | `<Alt-e> g 1 .` | Grep for file by content   | 1 dir up from cwd           |
|              | `<Alt-e> g 2 .` | Grep for file by content   | 2 dirs up from cwd          |
|              | `<Alt-e> g 3 .` | Grep for file by content   | 3 dirs up from cwd          |
|              | etc.            | etc.                       | etc.                        |
| `<Alt-e>g~`  |                 | Grep for file by content   | home                        |
| `<Alt-e>g%`  |                 | Grep for buffer by content | Directory of current buffer |
| `<Alt-e>gb`  |                 | Grep for buffer by content |                             |
| `<Alt-e>rf`  |                 | Recall "(f)recent" file    |                             |
| `<Alt-e>b`   |                 | Find buffer                |                             |


#### `<Alt-p>` for "Put" (or "Paste")

`<Alt-p>`: starts **p**ulling a file, directory, or file names or content into the current context (command line or buffer)
-   `f`: find a **f**ile by name, and insert its name into the command line
    -   `.`: starts the search (by default) at the current working directory.
        -   This can take an optional single-digit *count* before it which specifies the number of levels up from the current working directory (e.g., "1." means parent directory of the current working directory; "2." means two directory levels up from the current working diretory; etc.)
    -   `~`: starts the search from the home directory
-   `d`: find a **d**irectory by name, and insert its name into the command line
    -   `.`: starts the search (by default) at the current working directory.
        -   This can take an optional single-digit *count* before it which specifies the number of levels up from the current working directory (e.g., "1." means parent directory of the current working directory; "2." means two directory levels up from the current working directory; etc.)
    -   `~`: starts the search from the home directory
-   `g`: find a line by **g**repping a directory, and insert it into the buffer
    -   `.`: starts the search (by default) at the current working directory.
        -   This can take an optional single-digit *count* before it which specifies the number of levels up from the current working directory (e.g., "1." means parent directory of the current working directory; "2." means two directory levels up from the current working directory; etc.)
    -   `~`: starts the search from the home directory

| Key Sequence | With Count   | Search Type              | Starting Search           | Shell Action                      | Editor Action               |
|:-------------|:-------------|:-------------------------|:--------------------------|:----------------------------------|:----------------------------|
| `<Alt-p>rc`  |              | Find "(f)recent" command |                           | Put command in command line       | Put command in command line |
| `<Alt-p>d~`  |              | Find directory           | home                      | Put selected name in command line |                             |
| `<Alt-p>d.`  |              | Find directory           | cwd                       | Put selected name in command line |                             |
|              | `<Alt-p>d1.` | Find directory           | 1 directory up from cwd   | Put selected name in command line |                             |
|              | `<Alt-p>d2.` | Find directory           | 2 directories up from cwd | Put selected name in command line |                             |
|              | `<Alt-p>d3.` | Find directory           | 3 directories up from cwd | Put selected name in command line |                             |
|              | etc.         | etc.                     | etc.                      | etc.                              |                             |
| `<Alt-p>f~`  |              | Find file                | home                      | Put selected name in command line |                             |
| `<Alt-p>f.`  |              | Find file                | cwd                       | Put selected name in command line |                             |
|              | `<Alt-p>f1.` | Find directory           | 1 directory up from cwd   | Put selected name in command line |                             |
|              | `<Alt-p>f2.` | Find directory           | 2 directories up from cwd | Put selected name in command line |                             |
|              | `<Alt-p>f3.` | Find directory           | 3 directories up from cwd | Put selected name in command line |                             |
|              | etc.         | etc.                     | etc.                      | etc.                              |                             |
| `<Alt-p>rc`  |              | Find "(f)recent" command |                           | Put command in command line       | Put command in command line |
| `<Alt-p>l~`  |              | Grep for lines           | home                      |                                   | Put line into buffer        |
| `<Alt-p>l.`  |              | Grep for lines           | cwd                       |                                   | Put line into buffer        |
|              | `<Alt-p>l1.` | Grep for lines           | 1 directory up from cwd   |                                   | Put line to buffer          |
|              | `<Alt-p>l2.` | Grep for lines           | 2 directories up from cwd |                                   | Put line to buffer          |
|              | `<Alt-p>l3.` | Grep for lines           | 3 directories up from cwd |                                   | Put line to buffer          |
|              | etc.         | etc.                     | etc.                      |                                   | etc.                        |


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
