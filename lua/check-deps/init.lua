local M = {}

local default_config = {
  list = {
    { name = 'yessir', cmd = 'yessir', install = { windows = { 'winget install yessir' }, linux = { 'sudo apt install yessir' } } }
  },
  auto_check = false,
  open_float = true,
}

local config = {}

local function detect_os()
  local uname = (vim.loop.os_uname() or vim.uv.os_uname()).sysname:lower()
  if uname:match("darwin") then return "mac" end
  if uname:match("linux") then
    return "linux"
  end
  if uname:match("windows") or uname:match("mingw") or uname:match("cygwin") then
    return "windows"
  end

  return uname
end

local function is_executable(name)
  return vim.fn.executable(name) == 1
end

local function check_dep(dep)
  if dep.check then
    local ok = dep.check()
    if ok then return true end
  end
  return is_executable(dep.cmd or dep.name)
end

local function open_float(missing)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}
  for _, dep in ipairs(missing) do
    table.insert(lines, dep.name .. " is missing, the following commands are available to install it:")
    for _, cmd in ipairs(dep.install[detect_os()] or {}) do
      table.insert(lines, "  " .. cmd)
    end
    table.insert(lines, "")
  end

  table.insert(lines, "Press <CR> to run an install command")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  -- keymaps
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true })

  vim.keymap.set('n', '<CR>', function()
    local line = vim.api.nvim_get_current_line()
    line = vim.trim(line)
    if line ~= '' and not line:match("is missing,") and not line:match("Press <CR>") then
      vim.api.nvim_del_current_line()
      -- open floating terminal underneath
      local term_buf = vim.api.nvim_create_buf(false, true)
      local term_height = 10
      local term_win = vim.api.nvim_open_win(term_buf, true, {
        relative = 'editor',
        width = width,
        height = term_height,
        row = row + height + 1,
        col = col,
        style = 'minimal',
        border = 'single',
      })
      vim.fn.termopen(line)

      vim.api.nvim_buf_set_option(term_buf, 'buflisted', false)

      vim.keymap.set('n', 'q', function()
        if vim.api.nvim_win_is_valid(term_win) then
          vim.api.nvim_win_close(term_win, true)
        end
      end, { buffer = term_buf, nowait = true })

    end
  end, { buffer = buf, nowait = true })
end

function M.check()
  local missing = {}
  for _, dep in ipairs(config.list) do
    if not check_dep(dep) then
      table.insert(missing, dep)
    end
  end

  if #missing > 0 and config.open_float then
    open_float(missing)
  elseif #missing > 0 then
    vim.notify("Missing dependencies found", vim.log.levels.WARN)
  else
    vim.notify("All dependencies are installed", vim.log.levels.INFO)
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})

  vim.api.nvim_create_user_command('DepsCheck', function()
    M.check()
  end, {})

  if config.auto_check then
    M.check()
  end
end

return M
