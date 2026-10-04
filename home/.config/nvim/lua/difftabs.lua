-- Diff viewer for `git difftool -d`: one tab per changed file.
-- Tab / Shift-Tab jump between changes and continue into the next / previous file.
local M = {}

local function files_in(dir)
  local files = {}
  for name, type in vim.fs.dir(dir, { depth = math.huge }) do
    if type == "file" or type == "link" then files[name] = true end
  end
  return files
end

-- Show `path` in the current window, or an empty scratch buffer if it doesn't exist
local function show(path)
  if vim.uv.fs_stat(path) then
    vim.cmd.edit(vim.fn.fnameescape(path))
  else
    vim.cmd.enew()
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
  end
  vim.cmd.diffthis()
end

local function open_pair(left, right, first)
  if not first then vim.cmd.tabnew() end
  show(left)
  vim.cmd("rightbelow vsplit")
  show(right)
end

function M.open(left, right)
  if vim.fn.isdirectory(left) == 0 then
    open_pair(left, right, true)
    return
  end
  local all = vim.tbl_extend("force", files_in(left), files_in(right))
  local names = vim.tbl_keys(all)
  table.sort(names)
  for i, name in ipairs(names) do
    open_pair(left .. "/" .. name, right .. "/" .. name, i == 1)
  end
  vim.cmd("tabfirst")
  M.first_change()
end

function M.first_change()
  vim.cmd("normal! gg")
  if vim.fn.diff_hlID(1, 1) == 0 then vim.cmd("normal! ]c") end
end

function M.last_change()
  vim.cmd("normal! G")
  if vim.fn.diff_hlID(vim.fn.line("$"), 1) == 0 then vim.cmd("normal! [c") end
end

function M.next()
  local line = vim.fn.line(".")
  vim.cmd("normal! ]c")
  if vim.fn.line(".") == line and vim.fn.tabpagenr() < vim.fn.tabpagenr("$") then
    vim.cmd("tabnext")
    M.first_change()
  end
end

function M.prev()
  local line = vim.fn.line(".")
  vim.cmd("normal! [c")
  if vim.fn.line(".") == line and vim.fn.tabpagenr() > 1 then
    vim.cmd("tabprevious")
    M.last_change()
  end
end

function M.setup()
  -- Outside of diff mode the keys keep their normal behaviour
  vim.keymap.set("n", "<Tab>", function()
    return vim.wo.diff and "<Cmd>lua require('difftabs').next()<CR>" or "<Tab>"
  end, { expr = true })
  vim.keymap.set("n", "<S-Tab>", function()
    return vim.wo.diff and "<Cmd>lua require('difftabs').prev()<CR>" or "<S-Tab>"
  end, { expr = true })
end

return M
