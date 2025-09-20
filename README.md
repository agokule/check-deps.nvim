# check-deps.nvim

A lightweight Neovim plugin to check for external dependencies and help install them.

## Features

* Define a list of required programs/tools.
* Custom check functions per dependency.
* Warn if dependencies are missing.
* Floating window display of missing dependencies.
* Suggested install commands for each dependency.
* Press `<CR>` on an install command to open a bottom split terminal and run it.
* Press `q` to quit the floating window.

## Installation

Use your favorite plugin manager:

### Lazy.nvim

```lua
{
  "agokule/check-deps.nvim",
  config = function()
    require("nvim-deps-check").setup({
      list = {
        {
          name = "rg",
          cmd = "rg",
          install = {
            linux = { "sudo apt install ripgrep", "sudo pacman -S ripgrep" },
            darwin = { "brew install ripgrep" },
            windows = { "choco install ripgrep", "winget install BurntSushi.ripgrep.GNU" },
          },
        },
        {
          name = "node",
          cmd = "node",
          check = function()
            return vim.fn.executable("node") == 1 and vim.fn.system("node -v"):match("v16") ~= nil
          end,
          install = {
            linux = { "sudo apt install nodejs" },
            darwin = { "brew install node" },
            windows = { "choco install nodejs" },
          },
        },
      },
      auto_check = true,
      open_float = true,
    })
  end
}
```

## Usage

* Run `:DepsCheck` to check dependencies.
* If missing dependencies are found:
  * A floating window will open.
  * Each missing dependency is listed with its install commands.
  * Move the cursor to an install command and press `<CR>` to open a bottom vsplit terminal and run it.
  * Press `q` to close the floating window.

## Configuration

Options passed to `setup`:

```lua
{
  list = { ... },  -- table of dependencies
  auto_check = false, -- run automatically at startup
  open_float = true,  -- open floating window if missing deps
}
```

### Dependency spec fields

* **name**: Display name.
* **cmd**: The executable name to check (optional if using `check`).
* **check**: A custom Lua function that takes no parameters and returns `true` if installed.
* **install**: A table of possible install commands by platform (keys: `linux`, `darwin`, `windows`).

## Example

```lua
{
  name = "python3",
  cmd = "python3",
  install = {
    linux = { "sudo apt install python3" },
    darwin = { "brew install python3" },
    windows = { "choco install python3" },
  }
}
```

